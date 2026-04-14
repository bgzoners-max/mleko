import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_model.dart';
import '../../models/seller_delivery_models.dart';
import '../core/connectivity_service.dart';
import '../core/logger_service.dart';
import 'order_queue_service.dart';
import 'orders_service.dart';
import 'sync_analytics_service.dart';

/// Shared order sync logic used by foreground and background flows.
class OrderSyncService {
  final OrderQueueService _queueService;
  final OrdersService _ordersService;
  final SyncAnalyticsService _analyticsService;
  final _client = Supabase.instance.client;
  static const _duplicateLookback = Duration(days: 2);

  OrderSyncService({
    required OrderQueueService queueService,
    required OrdersService ordersService,
  })  : _queueService = queueService,
        _ordersService = ordersService,
        _analyticsService = SyncAnalyticsService();

  static const String taskName = 'mleko_order_sync';

  Future<int> syncPendingOrders({
    ConnectivityService? connectivity,
    bool skipConnectivityCheck = false,
    String source = 'foreground',
  }) async {
    final stopwatch = Stopwatch()..start();
    var attempted = 0;
    var syncedCount = 0;
    var duplicateCount = 0;
    var failedCount = 0;
    var skippedOffline = false;

    try {
      if (!skipConnectivityCheck &&
          connectivity != null &&
          connectivity.isOffline) {
        skippedOffline = true;
        LoggerService.debug('Order sync skipped: device is offline');
        return 0;
      }

      final pendingOrders =
          await _queueService.getPendingOrders(onlyUnsynced: true);
      attempted = pendingOrders.length;
      if (pendingOrders.isEmpty) {
        LoggerService.info('No pending orders to sync');
        return 0;
      }

      LoggerService.info('Starting pending order sync',
          extra: {'pendingCount': pendingOrders.length, 'source': source});

      for (final pending in pendingOrders) {
        try {
          final duplicateOrderId = await _findDuplicateOrderId(pending);
          if (duplicateOrderId != null) {
            await _queueService.markAsSynced(pending.id);
            syncedCount++;
            duplicateCount++;
            LoggerService.warning(
              'Conflict resolved: pending order already exists on server',
              extra: {
                'pendingOrderId': pending.id,
                'existingOrderId': duplicateOrderId,
              },
            );
            continue;
          }

          final order = OrderModel(
            id: '',
            buyerId: pending.buyerId,
            sellerId: pending.sellerId,
            productId: pending.productId,
            productName: pending.productName,
            quantityKg: pending.quantityKg,
            unitType: pending.unitType,
            note: pending.note ?? '',
            buyerCity: pending.buyerCity,
            buyerPhone: pending.buyerPhone,
            buyerAddress: pending.buyerAddress,
            deliveryMethod: pending.deliveryMethod,
            deliveryCity: pending.deliveryCity,
            deliveryPointId: pending.deliveryPointId,
            deliveryPointLabel: pending.deliveryPointLabel,
            deliveryAddress: pending.deliveryAddress,
            deliveryWeekday: pending.deliveryWeekday,
            deliveryTimeFrom: pending.deliveryTimeFrom,
            deliveryTimeTo: pending.deliveryTimeTo,
            deliveryFeeRsd: pending.deliveryFeeRsd,
            status: OrderStatus.sent,
            createdAt: DateTime.now(),
          );

          await _ordersService.createOrder(order);
          await _queueService.markAsSynced(pending.id);
          syncedCount++;

          LoggerService.info('Pending order synced',
              extra: {'pendingOrderId': pending.id});
        } catch (e, st) {
          failedCount++;
          LoggerService.error('Failed to sync pending order ${pending.id}', e,
              stackTrace: st);
        }
      }

      await _queueService.cleanSyncedOrders();

      LoggerService.info('Pending order sync completed', extra: {
        'syncedCount': syncedCount,
        'duplicateCount': duplicateCount,
        'failedCount': failedCount,
        'source': source,
      });
      return syncedCount;
    } finally {
      stopwatch.stop();
      try {
        await _analyticsService.recordRun(
          source: source,
          attempted: attempted,
          synced: syncedCount,
          duplicates: duplicateCount,
          failed: failedCount,
          duration: stopwatch.elapsed,
          skippedOffline: skippedOffline,
        );
      } catch (e, st) {
        LoggerService.warning('Failed to record sync analytics',
            extra: {'error': e.toString(), 'stackTrace': st.toString()});
      }
    }
  }

  Future<String?> _findDuplicateOrderId(PendingOrder pending) async {
    final lookbackSince =
        DateTime.now().subtract(_duplicateLookback).toIso8601String();
    final rows = await _client
        .from('orders')
        .select(
            'id, quantity_kg, buyer_phone, buyer_city, buyer_address, note, delivery_method, delivery_city, delivery_point_label, delivery_address, delivery_weekday, delivery_time_from, delivery_time_to, delivery_fee_rsd, created_at')
        .eq('buyer_id', pending.buyerId)
        .eq('seller_id', pending.sellerId)
        .eq('product_id', pending.productId)
        .gte('created_at', lookbackSince)
        .order('created_at', ascending: false)
        .limit(20);

    final expectedPhone = _normalize(pending.buyerPhone);
    final expectedCity = _normalize(pending.buyerCity);
    final expectedAddress = _normalize(pending.buyerAddress ?? '');
    final expectedNote = _normalize(pending.note ?? '');
    final expectedDeliveryMethod = pending.deliveryMethod.dbValue;
    final expectedDeliveryCity = _normalize(pending.deliveryCity ?? '');
    final expectedDeliveryPoint = _normalize(pending.deliveryPointLabel ?? '');
    final expectedDeliveryAddress = _normalize(pending.deliveryAddress ?? '');
    final expectedDeliveryWeekday = pending.deliveryWeekday;
    final expectedDeliveryFrom = _normalize(pending.deliveryTimeFrom ?? '');
    final expectedDeliveryTo = _normalize(pending.deliveryTimeTo ?? '');
    final expectedDeliveryFee = pending.deliveryFeeRsd ?? 0;

    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final qty = (row['quantity_kg'] as num?)?.toDouble();
      if (qty == null || (qty - pending.quantityKg).abs() > 0.0001) {
        continue;
      }

      final phone = _normalize(row['buyer_phone'] as String? ?? '');
      final city = _normalize(row['buyer_city'] as String? ?? '');
      final address = _normalize(row['buyer_address'] as String? ?? '');
      final note = _normalize(row['note'] as String? ?? '');
      final deliveryMethod =
          _normalize(row['delivery_method'] as String? ?? 'agreement');
      final deliveryCity = _normalize(row['delivery_city'] as String? ?? '');
      final deliveryPoint =
          _normalize(row['delivery_point_label'] as String? ?? '');
      final deliveryAddress =
          _normalize(row['delivery_address'] as String? ?? '');
      final deliveryWeekday = (row['delivery_weekday'] as num?)?.toInt();
      final deliveryFrom =
          _normalize(row['delivery_time_from'] as String? ?? '');
      final deliveryTo = _normalize(row['delivery_time_to'] as String? ?? '');
      final deliveryFee = (row['delivery_fee_rsd'] as num?)?.toDouble() ?? 0;

      if (phone == expectedPhone &&
          city == expectedCity &&
          address == expectedAddress &&
          note == expectedNote &&
          deliveryMethod == expectedDeliveryMethod &&
          deliveryCity == expectedDeliveryCity &&
          deliveryPoint == expectedDeliveryPoint &&
          deliveryAddress == expectedDeliveryAddress &&
          deliveryWeekday == expectedDeliveryWeekday &&
          deliveryFrom == expectedDeliveryFrom &&
          deliveryTo == expectedDeliveryTo &&
          (deliveryFee - expectedDeliveryFee).abs() < 0.0001) {
        return row['id'] as String?;
      }
    }

    return null;
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
