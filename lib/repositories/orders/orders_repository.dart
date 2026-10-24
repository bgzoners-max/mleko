import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status_audit_log_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../services/orders/mixins/order_query_mixin.dart';
import '../../services/orders/mixins/order_management_mixin.dart';

/// Interfejs za perzistenciju i upite nad porudžbinama (Repository Pattern).
abstract interface class OrdersRepository {
  Future<List<OrderModel>> fetchOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  });

  Future<List<OrderModel>> fetchOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  });

  Future<OrderModel?> getOrderById(String orderId);

  Future<List<OrderItemModel>> getOrderItems(String orderId);

  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(String orderId);

  Future<SellerStats> getSellerStats(String sellerId);

  Future<BuyerStats> getBuyerStats(String buyerId);

  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  });

  Future<List<OrderModel>> fetchMoreOrdersBySeller(
    String sellerId, {
    required int offset,
    String? statusFilter,
  });

  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(String buyerId);

  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  });

  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  });

  Future<String> createSingleProductOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productName,
    required double quantityKg,
    required String unitType,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  });

  Future<String> createOrderWithItems({
    required String buyerId,
    required String sellerId,
    required List<OrderItemModel> items,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  });

  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  Future<void> cancelOrderBySeller(String orderId, String reason);

  Future<void> archiveOrderByBuyer(String buyerId, String orderId);

  Future<void> archiveOrderBySeller(String sellerId, String orderId);

  Future<void> archiveOrder(String orderId);

  Future<void> confirmOrderReceivedByBuyer(String orderId);
}

/// Supabase implementacija [OrdersRepository].
class SupabaseOrdersRepository
    with OrderQueryMixin, OrderManagementMixin
    implements OrdersRepository {
  final SupabaseClient? _customClient;

  SupabaseOrdersRepository({SupabaseClient? client}) : _customClient = client;

  @override
  SupabaseClient get client => _customClient ?? Supabase.instance.client;
}
