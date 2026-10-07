import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/order_item_model.dart';
import '../../../models/order_model.dart';
import '../../../models/order_status_audit_log_model.dart';
import '../../../models/product_model.dart';
import '../../communication/realtime_channel_manager.dart';
import '../../core/logger_service.dart';

const int kPageSize = 20;

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

class BuyerStats {
  final int pendingCount;
  final int totalSuccessCount;
  final double totalSpent;

  BuyerStats({
    required this.pendingCount,
    required this.totalSuccessCount,
    required this.totalSpent,
  });
}

mixin OrderQueryMixin {
  SupabaseClient get client;
  static const String statusFilterActiveNonArchived = 'active';

  Future<List<OrderModel>> fetchOrdersByBuyer(
    String buyerId, {
    int limit = kPageSize,
    int offset = 0,
    String? statusFilter,
  }) async {
    var query = client.from('orders').select().eq('buyer_id', buyerId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == statusFilterActiveNonArchived) {
        query = query.neq('status', 'archived');
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
    return enrichWithNames(orders, loadSeller: true);
  }

  Future<List<OrderModel>> fetchOrdersBySeller(
    String sellerId, {
    int limit = kPageSize,
    int offset = 0,
    String? statusFilter,
  }) async {
    var query = client.from('orders').select().eq('seller_id', sellerId);
    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == statusFilterActiveNonArchived) {
        query = query.neq('status', 'archived');
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
    return enrichWithNames(orders, loadSeller: false);
  }

  Future<List<OrderModel>> enrichWithNames(
    List<OrderModel> orders, {
    required bool loadSeller,
  }) async {
    if (orders.isEmpty) return orders;
    final ids =
        orders.map((o) => loadSeller ? o.sellerId : o.buyerId).toSet().toList();
    final profiles = await client
        .from('public_profiles')
        .select('id, farm_name, display_name')
        .inFilter('id', ids);
    final fallback = loadSeller ? 'Prodavac' : 'Kupac';
    final nameMap = <String, String>{
      for (final p in profiles as List)
        p['id'] as String:
            (p['farm_name'] ?? p['display_name']) as String? ?? fallback,
    };

    Set<String> reviewedOrderIds = {};
    if (loadSeller) {
      try {
        final orderIds = orders.map((o) => o.id).toList();
        final reviewsList = await client
            .from('reviews')
            .select('order_id')
            .inFilter('order_id', orderIds);
        reviewedOrderIds = (reviewsList as List)
            .map((e) => e['order_id'] as String)
            .toSet();
      } catch (e, st) {
        LoggerService.warning('Failed to batch-fetch reviews for orders',
            extra: {'error': e.toString(), 'stackTrace': st.toString()});
      }
    }

    return orders.map((o) {
      final id = loadSeller ? o.sellerId : o.buyerId;
      final isReviewed = loadSeller ? reviewedOrderIds.contains(o.id) : null;
      return o.copyWith(
        counterpartyName: nameMap[id] ?? fallback,
        isReviewed: isReviewed,
      );
    }).toList();
  }

  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  }) =>
      fetchOrdersByBuyer(buyerId, offset: offset, statusFilter: statusFilter);

  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(
      String buyerId) async {
    const limit = 300;
    final orders =
        await fetchOrdersByBuyer(buyerId, limit: limit, statusFilter: null);
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
      fetchOrdersBySeller(sellerId, offset: offset, statusFilter: statusFilter);

  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    Stream<void>? refreshTrigger,
    String? statusFilter,
  }) {
    final suffix = statusFilter != null ? '-$statusFilter' : '';
    return ordersStream(
      channelName: 'orders-buyer-$buyerId$suffix',
      filterColumn: 'buyer_id',
      filterValue: buyerId,
      fetcher: () => fetchOrdersByBuyer(buyerId, statusFilter: statusFilter),
      refreshTrigger: refreshTrigger,
    );
  }

  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    Stream<void>? refreshTrigger,
    String? statusFilter,
  }) {
    final suffix = statusFilter != null ? '-$statusFilter' : '';
    return ordersStream(
      channelName: 'orders-seller-$sellerId$suffix',
      filterColumn: 'seller_id',
      filterValue: sellerId,
      fetcher: () => fetchOrdersBySeller(sellerId, statusFilter: statusFilter),
      refreshTrigger: refreshTrigger,
    );
  }

  Stream<List<OrderModel>> ordersStream({
    required String channelName,
    required String filterColumn,
    required String filterValue,
    required Future<List<OrderModel>> Function() fetcher,
    Stream<void>? refreshTrigger,
  }) {
    StreamSubscription? refreshSub;
    void Function()? releaseChannel;

    late final StreamController<List<OrderModel>> controller;

    Future<void> refetch() async {
      try {
        final orders = await fetcher();
        if (!controller.isClosed) controller.add(orders);
      } catch (e, st) {
        LoggerService.error('Failed to refetch orders stream', e,
            stackTrace: st);
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<OrderModel>>.broadcast(
      onListen: () {
        refetch();

        releaseChannel = RealtimeChannelManager().acquire(
          client: client,
          channelName: channelName,
          onEvent: refetch,
          createChannel: (c, notify) {
            final ch = c.channel(channelName);
            ch.onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: filterColumn,
                value: filterValue,
              ),
              callback: (_) => notify(),
            );
            return ch;
          },
        );

        refreshSub = refreshTrigger?.listen((_) => refetch());
      },
      onCancel: () {
        refreshSub?.cancel();
        releaseChannel?.call();
        releaseChannel = null;
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return controller.stream;
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final res =
        await client.from('orders').select().eq('id', orderId).maybeSingle();
    if (res == null) return null;
    return OrderModel.fromJson(res);
  }

  Future<List<OrderItemModel>> getOrderItems(String orderId) async {
    final list =
        await client.from('order_items').select().eq('order_id', orderId);
    return (list as List)
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) async {
    final list = await client
        .from('order_status_audit_logs')
        .select()
        .eq('order_id', orderId)
        .order('changed_at', ascending: false);

    return (list as List)
        .map(
          (e) => OrderStatusAuditLogModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<SellerStats> getSellerStats(String sellerId) async {
    final result = await client.rpc(
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

  Future<BuyerStats> getBuyerStats(String buyerId) async {
    final result = await client.rpc(
      'get_buyer_stats_dashboard',
      params: {'p_buyer_id': buyerId},
    );
    if (result == null) {
      return BuyerStats(pendingCount: 0, totalSuccessCount: 0, totalSpent: 0);
    }
    final json = result is Map<String, dynamic>
        ? result
        : Map<String, dynamic>.from(result as Map);
    return BuyerStats(
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      totalSuccessCount: (json['total_success_count'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<({ProductModel product, int salesCount})>>
      getSellerPopularProducts(
    String sellerId, {
    int limit = 5,
  }) async {
    final products = await client
        .from('products_with_ratings')
        .select()
        .eq('seller_id', sellerId)
        .gte('order_count', 1)
        .order('order_count', ascending: false)
        .limit(limit);

    return (products as List).map((p) {
      final data = p as Map<String, dynamic>;
      final product = ProductModel.fromJson(data);
      final salesCount = data['order_count'] as int;
      return (product: product, salesCount: salesCount);
    }).toList();
  }
}
