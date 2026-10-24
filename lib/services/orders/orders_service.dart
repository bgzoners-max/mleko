import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status_audit_log_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../repositories/orders/orders_repository.dart';
import 'mixins/order_query_mixin.dart';

export '../../repositories/orders/orders_repository.dart';
export 'mixins/order_query_mixin.dart';
export 'mixins/order_management_mixin.dart';

/// Centralni servis za porudžbine baziran na kompoziciji sa [OrdersRepository].
class OrdersService {
  static final OrdersService _instance = OrdersService._();

  factory OrdersService({
    OrdersRepository? repository,
    SupabaseClient? client,
  }) {
    if (repository != null || client != null) {
      return OrdersService._(repository: repository, client: client);
    }
    return _instance;
  }

  OrdersService._({
    OrdersRepository? repository,
    SupabaseClient? client,
  })  : _customClient = client,
        _repository = repository ?? SupabaseOrdersRepository(client: client);

  /// Konstruktor namenjen isključivo jediničnom testiranju uz mockovanje repozitorijuma.
  @visibleForTesting
  OrdersService.forTesting({
    required OrdersRepository repository,
  })  : _customClient = null,
        _repository = repository;

  final SupabaseClient? _customClient;
  final OrdersRepository _repository;

  SupabaseClient get client => _customClient ?? Supabase.instance.client;
  OrdersRepository get repository => _repository;

  /// Vrednost statusFilter za listu „aktivnih” porudžbina: sve osim kupčeve ručne arhive (`arhivirano`).
  static const String statusFilterActiveNonArchived = 'active';

  Future<List<OrderModel>> fetchOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) =>
      _repository.fetchOrdersByBuyer(
        buyerId,
        statusFilter: statusFilter,
        limit: limit,
        offset: offset,
      );

  Future<List<OrderModel>> fetchOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    int limit = 20,
    int offset = 0,
  }) =>
      _repository.fetchOrdersBySeller(
        sellerId,
        statusFilter: statusFilter,
        limit: limit,
        offset: offset,
      );

  Future<OrderModel?> getOrderById(String orderId) =>
      _repository.getOrderById(orderId);

  Future<List<OrderItemModel>> getOrderItems(String orderId) =>
      _repository.getOrderItems(orderId);

  Future<SellerStats> getSellerStats(String sellerId) =>
      _repository.getSellerStats(sellerId);

  Future<BuyerStats> getBuyerStats(String buyerId) =>
      _repository.getBuyerStats(buyerId);

  Future<List<BuyerSellerStats>> getOrdersByBuyerForSellerStats(String buyerId) =>
      _repository.getOrdersByBuyerForSellerStats(buyerId);

  Future<List<OrderModel>> fetchMoreOrdersByBuyer(
    String buyerId, {
    required int offset,
    String? statusFilter,
  }) =>
      _repository.fetchMoreOrdersByBuyer(
        buyerId,
        offset: offset,
        statusFilter: statusFilter,
      );

  Future<List<OrderModel>> fetchMoreOrdersBySeller(
    String sellerId, {
    required int offset,
    String? statusFilter,
  }) =>
      _repository.fetchMoreOrdersBySeller(
        sellerId,
        offset: offset,
        statusFilter: statusFilter,
      );

  Stream<List<OrderModel>> getOrdersBySeller(
    String sellerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) =>
      _repository.getOrdersBySeller(
        sellerId,
        statusFilter: statusFilter,
        refreshTrigger: refreshTrigger,
      );

  Stream<List<OrderModel>> getOrdersByBuyer(
    String buyerId, {
    String? statusFilter,
    Stream<void>? refreshTrigger,
  }) =>
      _repository.getOrdersByBuyer(
        buyerId,
        statusFilter: statusFilter,
        refreshTrigger: refreshTrigger,
      );

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
  }) =>
      _repository.createSingleProductOrder(
        buyerId: buyerId,
        sellerId: sellerId,
        productId: productId,
        productName: productName,
        quantityKg: quantityKg,
        unitType: unitType,
        note: note,
        buyerCity: buyerCity,
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        buyerPostalCode: buyerPostalCode,
        deliveryMethod: deliveryMethod,
        deliverySelection: deliverySelection,
      );

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
  }) =>
      _repository.createOrderWithItems(
        buyerId: buyerId,
        sellerId: sellerId,
        items: items,
        note: note,
        buyerCity: buyerCity,
        buyerPhone: buyerPhone,
        buyerAddress: buyerAddress,
        buyerPostalCode: buyerPostalCode,
        deliveryMethod: deliveryMethod,
        deliverySelection: deliverySelection,
      );

  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) =>
      _repository.getOrderStatusAuditLogs(orderId);

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _repository.updateOrderStatus(orderId, status);

  Future<void> cancelOrderBySeller(String orderId, String reason) =>
      _repository.cancelOrderBySeller(orderId, reason);

  Future<void> archiveOrderByBuyer(String buyerId, String orderId) =>
      _repository.archiveOrderByBuyer(buyerId, orderId);

  Future<void> archiveOrderBySeller(String sellerId, String orderId) =>
      _repository.archiveOrderBySeller(sellerId, orderId);

  Future<void> archiveOrder(String orderId) => _repository.archiveOrder(orderId);

  Future<void> confirmOrderReceivedByBuyer(String orderId) =>
      _repository.confirmOrderReceivedByBuyer(orderId);
}

