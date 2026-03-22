import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status_audit_log_model.dart';
import '../../models/product_model.dart';
import '../../utils/quantity_engine.dart';
import '../core/logger_service.dart';

/// Broj porudžbina koji se učitava u jednoj stranici.
const _kPageSize = 20;

/// Statistika kupca po prodavcu za tab „Po prodavcima”.
class BuyerSellerStats {
  final String sellerId;
  final String sellerName;
  final int orderCount;
  final double totalSpent;
  final String lastOrderId;

  const BuyerSellerStats({
    required this.sellerId,
    required this.sellerName,
    required this.orderCount,
    required this.totalSpent,
    required this.lastOrderId,
  });

  double get averageOrder => orderCount > 0 ? totalSpent / orderCount : 0;
}

class OrdersService {
  final _client = Supabase.instance.client;

  /// Vrednost [statusFilter] za listu „aktivnih” porudžbina: sve osim kupčeve ručne arhive (`arhivirano`).
  static const String statusFilterActiveNonArchived = 'active';

  // ─── Fetch (sa paginacijom i batch-učitavanjem imena) ──────────────────────

  Future<List<OrderModel>> _fetchOrdersByBuyer(
    String buyerId, {
    int limit = _kPageSize,
    int offset = 0,
    String? statusFilter,
  }) async {
    var query = _client.from('orders').select().eq('buyer_id', buyerId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == statusFilterActiveNonArchived) {
        query = query.neq('status', 'arhivirano');
      } else {
        query = query.eq('status', statusFilter);
      }
    }
    final list = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final orders = (list as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _enrichWithNames(orders, loadSeller: true);
  }

  Future<List<OrderModel>> _fetchOrdersBySeller(
    String sellerId, {
    int limit = _kPageSize,
    int offset = 0,
    String? statusFilter,
  }) async {
    var query = _client.from('orders').select().eq('seller_id', sellerId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == statusFilterActiveNonArchived) {
        query = query.neq('status', 'arhivirano');
      } else {
        query = query.eq('status', statusFilter);
      }
    }
    final list = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final orders = (list as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _enrichWithNames(orders, loadSeller: false);
  }

  /// Batch-load: jedan upit za sve jedinstvene prodavce/kupce u listi.
  /// Eliminišu se N+1 pozivi koji su bili u _BuyerOrderCard / _SellerOrderCard.
  Future<List<OrderModel>> _enrichWithNames(
    List<OrderModel> orders, {
    required bool loadSeller,
  }) async {
    if (orders.isEmpty) return orders;
    final ids =
        orders.map((o) => loadSeller ? o.sellerId : o.buyerId).toSet().toList();
    final profiles = await _client
        .from('profiles')
        .select('id, farm_name, display_name')
        .inFilter('id', ids);
    final fallback = loadSeller ? 'Prodavac' : 'Kupac';
    final nameMap = <String, String>{
      for (final p in profiles as List)
        p['id'] as String:
            (p['farm_name'] ?? p['display_name']) as String? ?? fallback,
    };
    return orders.map((o) {
      final id = loadSeller ? o.sellerId : o.buyerId;
      return o.copyWith(counterpartyName: nameMap[id] ?? fallback);
    }).toList();
  }

  // ─── Paginacija: "učitaj starije" ─────────────────────────────────────────

  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  }) =>
      _fetchOrdersByBuyer(buyerId, offset: offset, statusFilter: statusFilter);

  /// Za tab „Po prodavcima”: sve porudžbine kupca (bez filtera statusa), grupisane po prodavcu.
  /// Limit 300 da ne opterećujemo; za prosečan račun koristi total_amount iz orders.
  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(
      String buyerId) async {
    const limit = 300;
    final orders =
        await _fetchOrdersByBuyer(buyerId, limit: limit, statusFilter: null);
    final bySeller = <String, List<OrderModel>>{};
    for (final o in orders) {
      bySeller.putIfAbsent(o.sellerId, () => []).add(o);
    }
    return bySeller.entries.map((e) {
      final list = e.value;
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final last = list.first;
      final totalSpent = list.fold<double>(
        0,
        (sum, o) => sum + (o.totalAmount ?? 0),
      );
      return BuyerSellerStats(
        sellerId: e.key,
        sellerName: last.counterpartyName ?? 'Prodavac',
        orderCount: list.length,
        totalSpent: totalSpent,
        lastOrderId: last.id,
      );
    }).toList()
      ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
  }

  Future<List<OrderModel>> fetchMoreOrdersBySeller(
    String sellerId, {
    required int offset,
    String? statusFilter,
  }) =>
      _fetchOrdersBySeller(sellerId,
          offset: offset, statusFilter: statusFilter);

  // ─── Kreiranje porudžbine ─────────────────────────────────────────────────

  Future<String> createOrder(OrderModel order) async {
    final res = await _client
        .from('orders')
        .insert(order.toJson())
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<String> createOrderWithItems({
    required String buyerId,
    required String sellerId,
    required List<OrderItemModel> items,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
  }) async {
    if (items.isEmpty) {
      throw Exception('Porudžbina mora imati barem jednu stavku.');
    }

    final productIds = items.map((e) => e.productId).toSet().toList();
    final products = await _client
        .from('products')
        .select(
            'id, seller_id, name, category, unit_type, min_order_kg, order_step')
        .inFilter('id', productIds);
    final productMap = {
      for (final p in (products as List).cast<Map<String, dynamic>>())
        (p['id'] as String): p,
    };

    for (final item in items) {
      final product = productMap[item.productId];
      if (product == null) {
        throw Exception('Proizvod više nije dostupan.');
      }

      if ((product['seller_id'] as String?) != sellerId) {
        throw Exception('Stavke moraju pripadati istom prodavcu.');
      }

      final unitType = (product['unit_type'] as String?) ?? ProductModel.unitKg;
      final minQuantity = (product['min_order_kg'] as num?)?.toDouble() ?? 0;
      final explicitStep = (product['order_step'] as num?)?.toDouble();
      final name = (product['name'] as String?) ?? '';
      final normalizedUnit =
          unitType == ProductModel.unitG ? ProductModel.unitKg : unitType;
      if (explicitStep == null || explicitStep <= 0) {
        throw Exception('$name: proizvod nema validan korak porudžbine.');
      }
      final step = explicitStep;

      if (!QuantityEngine.isValidQuantity(
        quantity: item.quantityKg,
        minQuantity: minQuantity,
        step: step,
      )) {
        throw Exception(
          '$name: količina mora biti od minimuma i u koracima od ${ProductModel.formatQuantityWithUnit(step, normalizedUnit)}.',
        );
      }
    }

    final itemsJson = items.map((i) => i.toJson()).toList();
    final result = await _client.rpc(
      'create_order_with_items',
      params: {
        'p_buyer_id': buyerId,
        'p_seller_id': sellerId,
        'p_buyer_phone': buyerPhone,
        'p_items': itemsJson,
        'p_note': note,
        'p_buyer_city': buyerCity,
        'p_buyer_address': buyerAddress,
      },
    );
    return result as String;
  }

  // ─── Real-time stream-ovi ──────────────────────────────────────────────────

  /// Stream prati najnovijih [_kPageSize] porudžbina.
  /// [statusFilter]: [statusFilterActiveNonArchived] = sve osim arhive; tačan status = filter po koloni;
  /// `'arhivirano'` = arhiva; `null` = sve (npr. statistika „Po prodavcima”).
  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    Stream<void>? refreshTrigger,
    String? statusFilter,
  }) {
    final suffix = statusFilter != null ? '-$statusFilter' : '';
    return _ordersStream(
      channelName: 'orders-buyer-$buyerId$suffix',
      filterColumn: 'buyer_id',
      filterValue: buyerId,
      fetcher: () => _fetchOrdersByBuyer(buyerId, statusFilter: statusFilter),
      refreshTrigger: refreshTrigger,
    );
  }

  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    Stream<void>? refreshTrigger,
    String? statusFilter,
  }) {
    final suffix = statusFilter != null ? '-$statusFilter' : '';
    return _ordersStream(
      channelName: 'orders-seller-$sellerId$suffix',
      filterColumn: 'seller_id',
      filterValue: sellerId,
      fetcher: () => _fetchOrdersBySeller(sellerId, statusFilter: statusFilter),
      refreshTrigger: refreshTrigger,
    );
  }

  Stream<List<OrderModel>> _ordersStream({
    required String channelName,
    required String filterColumn,
    required String filterValue,
    required Future<List<OrderModel>> Function() fetcher,
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<List<OrderModel>>.broadcast();
    StreamSubscription? refreshSub;

    Future<void> refetch() async {
      try {
        final orders = await fetcher();
        if (!controller.isClosed) controller.add(orders);
      } catch (e, st) {
        LoggerService.error('Failed to refetch orders stream', e,
            stackTrace: st);
      }
    }

    refetch();

    final channel = _client.channel(channelName);
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filterColumn,
            value: filterValue,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  // ─── Status i otkazivanje ─────────────────────────────────────────────────

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _client
        .from('orders')
        .update({'status': status.dbValue}).eq('id', orderId);
  }

  Future<void> cancelOrderBySeller(String orderId, String reason) async {
    await _client.from('orders').update({
      'status': OrderStatus.cancelledBySeller.dbValue,
      'cancellation_reason': reason.trim().isEmpty ? null : reason.trim(),
    }).eq('id', orderId);
  }

  Future<void> archiveOrderByBuyer(String buyerId, String orderId) async {
    await _client
        .from('orders')
        .update({
          'status': OrderStatus.archived.dbValue,
          'archived_at': DateTime.now().toUtc().toIso8601String(),
          // Retention starts from buyer-side archive timestamp.
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 365))
              .toIso8601String(),
        })
        .eq('id', orderId)
        .eq('buyer_id', buyerId);
  }

  /// Ručna arhiva sa prodavčeve strane (isti terminalni statusi kao kod kupca).
  Future<void> archiveOrderBySeller(String sellerId, String orderId) async {
    await _client
        .from('orders')
        .update({
          'status': OrderStatus.archived.dbValue,
          'archived_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 365))
              .toIso8601String(),
        })
        .eq('id', orderId)
        .eq('seller_id', sellerId);
  }

  Future<void> confirmOrderReceivedByBuyer(String orderId) async {
    final result = await _client.rpc(
      'buyer_confirm_order_received',
      params: {'p_order_id': orderId},
    );
    if (result != true) {
      throw Exception('Nije moguce potvrditi prijem za ovu porudzbinu.');
    }
  }

  // ─── Pojedinačne porudžbine ───────────────────────────────────────────────

  Future<OrderModel?> getOrderById(String orderId) async {
    final res =
        await _client.from('orders').select().eq('id', orderId).maybeSingle();
    if (res == null) return null;
    return OrderModel.fromJson(res);
  }

  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final list =
        await _client.from('order_items').select().eq('order_id', orderId);
    return (list as List)
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) async {
    final list = await _client
        .from('order_status_audit_logs')
        .select()
        .eq('order_id', orderId)
        .order('changed_at', ascending: false);

    return (list as List)
        .map(
          (e) =>
              OrderStatusAuditLogModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  // ─── Statistika za dashboard ──────────────────────────────────────────────

  /// Jedan DB round-trip putem get_seller_stats_dashboard RPC.
  /// Zamenjuje prethodni N+N+1 loop (svaka porudžbina → products query).
  Future<SellerStats> getSellerStats(String sellerId) async {
    final result = await _client.rpc(
      'get_seller_stats_dashboard',
      params: {'p_seller_id': sellerId},
    );
    if (result == null) {
      return SellerStats(pendingCount: 0, totalCount: 0, revenue: 0);
    }
    final json = result is Map<String, dynamic>
        ? result
        : Map<String, dynamic>.from(result as Map);
    return SellerStats(
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  // ─── Popularni proizvodi ──────────────────────────────────────────────────

  Future<List<({ProductModel product, int salesCount})>>
      getSellerPopularProducts(
    String sellerId, {
    int limit = 5,
  }) async {
    final orders = await _client
        .from('orders')
        .select('id, product_id')
        .eq('seller_id', sellerId)
        .inFilter('status', ['accepted', 'delivered']);

    final productCounts = <String, int>{};
    final multiOrderIds = <String>[];

    for (final o in (orders as List).cast<Map<String, dynamic>>()) {
      final productId = o['product_id'] as String?;
      if (productId != null) {
        productCounts[productId] = (productCounts[productId] ?? 0) + 1;
      } else {
        multiOrderIds.add(o['id'] as String);
      }
    }

    // Batch-load svih stavki za multi-item porudžbine (1 upit umesto N)
    if (multiOrderIds.isNotEmpty) {
      final items = await _client
          .from('order_items')
          .select('product_id')
          .inFilter('order_id', multiOrderIds);
      for (final it in (items as List).cast<Map<String, dynamic>>()) {
        final pid = it['product_id'] as String?;
        if (pid != null) {
          productCounts[pid] = (productCounts[pid] ?? 0) + 1;
        }
      }
    }

    if (productCounts.isEmpty) return [];
    final sorted = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sorted.take(limit).map((e) => e.key).toList();
    final products =
        await _client.from('products').select().inFilter('id', topIds);
    final productMap = <String, ProductModel>{};
    for (final row in (products as List).cast<Map<String, dynamic>>()) {
      final p = ProductModel.fromJson(row);
      productMap[p.id] = p;
    }
    return topIds
        .where((id) => productMap.containsKey(id))
        .map((id) => (product: productMap[id]!, salesCount: productCounts[id]!))
        .toList();
  }
}

class SellerStats {
  final int pendingCount;
  final int totalCount;
  final double revenue;

  SellerStats({
    required this.pendingCount,
    required this.totalCount,
    required this.revenue,
  });
}
