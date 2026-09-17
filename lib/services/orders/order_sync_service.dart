import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/seller_delivery_models.dart';
import '../../models/app_error.dart';
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
  SupabaseClient get _client => Supabase.instance.client;
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
          // Pre-flight provera autentifikacije:
          // RPC funkcija na bazi (create_order_with_items) strogo zahteva auth.uid() = p_buyer_id.
          // U background isolate-u, ako restore sesije nije uspeo ili je korisnik izlogovan,
          // ne šaljemo RPC koji je osuđen na neuspeh (401/Unauthorized), već evidentiramo razlog.
          final currentUser = _client.auth.currentUser;
          if (currentUser == null) {
            const errorMsg =
                'Sesija nije pronađena u pozadini. Otvorite aplikaciju da bi porudžbina bila poslata.';
            await _queueService.recordOrderFailure(pending.id, error: errorMsg);
            failedCount++;
            LoggerService.warning(
              'Order sync pre-flight failed: unauthenticated session in isolate',
              extra: {'pendingOrderId': pending.id, 'source': source},
            );
            continue;
          }

          if (currentUser.id != pending.buyerId) {
            final errorMsg =
                'Prijavljeni nalog ne odgovara kupcu ove porudžbine.';
            await _queueService.recordOrderFailure(pending.id, error: errorMsg);
            failedCount++;
            LoggerService.warning(
              'Order sync pre-flight failed: buyer mismatch',
              extra: {
                'pendingOrderId': pending.id,
                'currentUserId': currentUser.id,
                'buyerId': pending.buyerId,
                'source': source,
              },
            );
            continue;
          }

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

          final deliverySelection =
              await _buildDeliverySelectionForSync(pending);

          await _ordersService.createSingleProductOrder(
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
            buyerPostalCode: pending.buyerPostalCode,
            deliveryMethod: pending.deliveryMethod,
            deliverySelection: deliverySelection,
          );
          await _queueService.markAsSynced(pending.id);
          syncedCount++;

          LoggerService.info('Pending order synced',
              extra: {'pendingOrderId': pending.id});
        } catch (e, st) {
          failedCount++;
          final errorMsg = e is AppError
              ? (e.userMessage ?? e.message)
              : e.toString();
          await _queueService.recordOrderFailure(pending.id, error: errorMsg);
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
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

  Future<DeliverySelectionModel?> _buildDeliverySelectionForSync(
    PendingOrder pending,
  ) async {
    try {
      if (pending.deliveryMethod != DeliveryMethod.sellerDelivery) {
        return null;
      }

      final pointId = pending.deliveryPointId;
      final city = pending.deliveryCity;
      final pointLabel = pending.deliveryPointLabel;
      final address = pending.deliveryAddress;
      final weekday = pending.deliveryWeekday;
      final timeFrom = pending.deliveryTimeFrom;
      final timeTo = pending.deliveryTimeTo;

      if ([pointId, city, pointLabel, address, timeFrom, timeTo]
              .any((value) => value == null || value.isEmpty) ||
          weekday == null) {
        throw AppError(
          message: 'Incomplete delivery data for offline order',
          userMessage:
              'Offline seller-delivery porudžbina nema kompletne podatke za termin.',
          type: ErrorType.validation,
        );
      }

      final resolvedPointId = pointId!;
      final resolvedCity = city!;
      final resolvedPointLabel = pointLabel!;
      final resolvedAddress = address!;
      final resolvedWeekday = weekday;
      final resolvedTimeFrom = timeFrom!;
      final resolvedTimeTo = timeTo!;

      var slotId = pending.deliverySlotId;
      double? minOrderAmountRsd = pending.minOrderAmountRsd;
      double? deliveryFeeRsd = pending.deliveryFeeRsd;

      if (slotId == null || slotId.isEmpty) {
        final slot = await _resolveLegacyDeliverySlot(
          pointId: resolvedPointId,
          weekday: resolvedWeekday,
          timeFrom: resolvedTimeFrom,
          timeTo: resolvedTimeTo,
        );
        slotId = slot['id'] as String?;
        minOrderAmountRsd ??= (slot['min_order_amount_rsd'] as num?)?.toDouble();
        deliveryFeeRsd ??= (slot['delivery_fee_rsd'] as num?)?.toDouble();
      }

      if (slotId == null || slotId.isEmpty) {
        throw AppError(
          message: 'Delivery slot resolution failed during sync',
          userMessage:
              'Offline seller-delivery porudžbina ne može da pronađe termin za sinhronizaciju.',
          type: ErrorType.notFound,
        );
      }

      return DeliverySelectionModel(
        method: DeliveryMethod.sellerDelivery,
        pointId: resolvedPointId,
        slotId: slotId,
        city: resolvedCity,
        pointLabel: resolvedPointLabel,
        address: resolvedAddress,
        weekday: resolvedWeekday,
        timeFrom: resolvedTimeFrom,
        timeTo: resolvedTimeTo,
        deliveryFeeRsd: deliveryFeeRsd,
        minOrderAmountRsd: minOrderAmountRsd,
      );
    } catch (e, st) {
      if (e is AppError) rethrow;
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<Map<String, dynamic>> _resolveLegacyDeliverySlot({
    required String pointId,
    required int weekday,
    required String timeFrom,
    required String timeTo,
  }) async {
    try {
      final slot = await _client
          .from('seller_delivery_slots')
          .select('id, delivery_fee_rsd, min_order_amount_rsd')
          .eq('delivery_point_id', pointId)
          .eq('weekday', weekday)
          .eq('time_from', timeFrom)
          .eq('time_to', timeTo)
          .eq('is_active', true)
          .maybeSingle();

      return slot is Map<String, dynamic>
          ? slot
          : Map<String, dynamic>.from(slot as Map? ?? const {});
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<String?> _findDuplicateOrderId(PendingOrder pending) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
