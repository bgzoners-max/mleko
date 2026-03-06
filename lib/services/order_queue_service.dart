import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// Model za porudžbinu koja čeka sinhronizaciju (offline queue)
class PendingOrder {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final double quantityKg;
  final String unitType;
  final String? note;
  final String buyerCity;
  final String? buyerAddress;
  final String buyerPhone;
  final bool preferCall;
  final List<String> pickupOptions;
  final DateTime createdAt;
  final DateTime? synced; // null = still pending, DateTime = synced

  const PendingOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitType,
    this.note,
    required this.buyerCity,
    this.buyerAddress,
    required this.buyerPhone,
    required this.preferCall,
    required this.pickupOptions,
    required this.createdAt,
    this.synced,
  });

  bool get isPending => synced == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'product_id': productId,
        'product_name': productName,
        'quantity_kg': quantityKg,
        'unit_type': unitType,
        'note': note,
        'buyer_city': buyerCity,
        'buyer_address': buyerAddress,
        'buyer_phone': buyerPhone,
        'prefer_call': preferCall,
        'pickup_options': pickupOptions,
        'created_at': createdAt.toIso8601String(),
        'synced': synced?.toIso8601String(),
      };

  factory PendingOrder.fromJson(Map<String, dynamic> json) => PendingOrder(
        id: json['id'] as String,
        buyerId: json['buyer_id'] as String,
        sellerId: json['seller_id'] as String,
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        quantityKg: (json['quantity_kg'] as num).toDouble(),
        unitType: json['unit_type'] as String,
        note: json['note'] as String?,
        buyerCity: json['buyer_city'] as String,
        buyerAddress: json['buyer_address'] as String?,
        buyerPhone: json['buyer_phone'] as String,
        preferCall: json['prefer_call'] as bool,
        pickupOptions: List<String>.from(json['pickup_options'] as List),
        createdAt: DateTime.parse(json['created_at'] as String),
        synced: json['synced'] != null
            ? DateTime.parse(json['synced'] as String)
            : null,
      );
}

/// Servis za offline queue - čuvaj orders kada nema interneta
class OrderQueueService {
  static const _storageKey = 'mleko_pending_orders';

  /// Dodaj porudžbinu u queue (bez slanja na server)
  Future<void> addPendingOrder(PendingOrder order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getPendingOrders();

      // Ako order već postoji, ne dupliraj
      if (orders.any((o) => o.id == order.id)) {
        LoggerService.warning('Order already in queue',
            extra: {'orderId': order.id});
        return;
      }

      orders.add(order);
      await _saveOrders(prefs, orders);
      LoggerService.info('Added pending order to queue',
          extra: {'orderId': order.id});
    } catch (e, st) {
      LoggerService.error('Failed to add pending order', e, stackTrace: st);
      rethrow;
    }
  }

  /// Preuzmi sve pending porudžbine
  Future<List<PendingOrder>> getPendingOrders(
      {bool onlyUnsynced = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json == null || json.isEmpty) return [];

      final list = jsonDecode(json) as List;
      final orders = list
          .map((e) => PendingOrder.fromJson(e as Map<String, dynamic>))
          .toList();

      if (onlyUnsynced) {
        return orders.where((o) => o.isPending).toList();
      }
      return orders;
    } catch (e, st) {
      LoggerService.error('Failed to load pending orders', e, stackTrace: st);
      return [];
    }
  }

  /// Označi order kao sinhronizovan (već poslat na server)
  Future<void> markAsSynced(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getPendingOrders();

      final index = orders.indexWhere((o) => o.id == orderId);
      if (index == -1) {
        LoggerService.warning('Order not found in queue',
            extra: {'orderId': orderId});
        return;
      }

      final order = orders[index];
      orders[index] = PendingOrder(
        id: order.id,
        buyerId: order.buyerId,
        sellerId: order.sellerId,
        productId: order.productId,
        productName: order.productName,
        quantityKg: order.quantityKg,
        unitType: order.unitType,
        note: order.note,
        buyerCity: order.buyerCity,
        buyerAddress: order.buyerAddress,
        buyerPhone: order.buyerPhone,
        preferCall: order.preferCall,
        pickupOptions: order.pickupOptions,
        createdAt: order.createdAt,
        synced: DateTime.now(), // Označi kao sinhronizovano
      );

      await _saveOrders(prefs, orders);
      LoggerService.info('Marked order as synced', extra: {'orderId': orderId});
    } catch (e, st) {
      LoggerService.error('Failed to mark order as synced', e, stackTrace: st);
    }
  }

  /// Obriši porudžbinu iz queue (ako je cancelled)
  Future<void> removePendingOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getPendingOrders();
      orders.removeWhere((o) => o.id == orderId);
      await _saveOrders(prefs, orders);
      LoggerService.info('Removed pending order', extra: {'orderId': orderId});
    } catch (e, st) {
      LoggerService.error('Failed to remove pending order', e, stackTrace: st);
    }
  }

  /// Obriši sve sinhronizovane porudžbine (cleanup)
  Future<void> cleanSyncedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getPendingOrders();
      final pending = orders.where((o) => o.isPending).toList();
      await _saveOrders(prefs, pending);
      LoggerService.info('Cleaned synced orders from queue');
    } catch (e, st) {
      LoggerService.error('Failed to clean synced orders', e, stackTrace: st);
    }
  }

  Future<void> _saveOrders(
      SharedPreferences prefs, List<PendingOrder> orders) async {
    final json = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }
}
