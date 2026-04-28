import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/seller_delivery_models.dart';
import '../../models/app_error.dart';
import '../core/logger_service.dart';

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
  final String? buyerPostalCode;
  final String buyerPhone;
  final DeliveryMethod deliveryMethod;
  final String? deliveryCity;
  final String? deliveryPointId;
  final String? deliverySlotId;
  final String? deliveryPointLabel;
  final String? deliveryAddress;
  final int? deliveryWeekday;
  final String? deliveryTimeFrom;
  final String? deliveryTimeTo;
  final double? deliveryFeeRsd;
  final double? minOrderAmountRsd;
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
    this.buyerPostalCode,
    required this.buyerPhone,
    this.deliveryMethod = DeliveryMethod.agreement,
    this.deliveryCity,
    this.deliveryPointId,
    this.deliverySlotId,
    this.deliveryPointLabel,
    this.deliveryAddress,
    this.deliveryWeekday,
    this.deliveryTimeFrom,
    this.deliveryTimeTo,
    this.deliveryFeeRsd,
    this.minOrderAmountRsd,
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
        'buyer_postal_code': buyerPostalCode,
        'buyer_phone': buyerPhone,
        'delivery_method': deliveryMethod.dbValue,
        'delivery_city': deliveryCity,
        'delivery_point_id': deliveryPointId,
        'delivery_slot_id': deliverySlotId,
        'delivery_point_label': deliveryPointLabel,
        'delivery_address': deliveryAddress,
        'delivery_weekday': deliveryWeekday,
        'delivery_time_from': deliveryTimeFrom,
        'delivery_time_to': deliveryTimeTo,
        'delivery_fee_rsd': deliveryFeeRsd,
        'min_order_amount_rsd': minOrderAmountRsd,
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
        buyerPostalCode: json['buyer_postal_code'] as String?,
        buyerPhone: json['buyer_phone'] as String,
        deliveryMethod:
            deliveryMethodFromDb(json['delivery_method'] as String?),
        deliveryCity: json['delivery_city'] as String?,
        deliveryPointId: json['delivery_point_id'] as String?,
        deliverySlotId: json['delivery_slot_id'] as String?,
        deliveryPointLabel: json['delivery_point_label'] as String?,
        deliveryAddress: json['delivery_address'] as String?,
        deliveryWeekday: (json['delivery_weekday'] as num?)?.toInt(),
        deliveryTimeFrom:
            normalizeDeliveryTimeString(json['delivery_time_from'] as String?),
        deliveryTimeTo:
            normalizeDeliveryTimeString(json['delivery_time_to'] as String?),
        deliveryFeeRsd: (json['delivery_fee_rsd'] as num?)?.toDouble(),
        minOrderAmountRsd: (json['min_order_amount_rsd'] as num?)?.toDouble(),
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
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Serializuje sve write operacije da spreči race condition na SharedPreferences.
  // Sve mutacije (add/mark/remove/clean) idu u red i izvršavaju se jedna po jedna.
  static Future<void> _writeChain = Future.value();

  Future<T> _serialized<T>(Future<T> Function() op) {
    final result = _writeChain.then((_) => op());
    _writeChain = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Preuzmi sve pending porudžbine (read-only, nema race condition)
  Future<List<PendingOrder>> getPendingOrders(
      {bool onlyUnsynced = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await _loadOrders(prefs);
      if (onlyUnsynced) {
        return orders.where((o) => o.isPending).toList();
      }
      return orders;
    } catch (e, st) {
      LoggerService.error('Failed to load pending orders', e, stackTrace: st);
      return [];
    }
  }

  /// Dodaj porudžbinu u queue (bez slanja na server)
  Future<void> addPendingOrder(PendingOrder order) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final orders = await _loadOrders(prefs);

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
        throw AppError(
          message: 'Failed to add pending order: $e',
          userMessage: 'Greška pri čuvanju porudžbine u lokalu.',
          type: ErrorType.unknown,
        );
      }
    });
  }

  /// Označi order kao sinhronizovan (već poslat na server)
  Future<void> markAsSynced(String orderId) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final orders = await _loadOrders(prefs);

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
          buyerPostalCode: order.buyerPostalCode,
          buyerPhone: order.buyerPhone,
          deliveryMethod: order.deliveryMethod,
          deliveryCity: order.deliveryCity,
          deliveryPointId: order.deliveryPointId,
          deliverySlotId: order.deliverySlotId,
          deliveryPointLabel: order.deliveryPointLabel,
          deliveryAddress: order.deliveryAddress,
          deliveryWeekday: order.deliveryWeekday,
          deliveryTimeFrom: order.deliveryTimeFrom,
          deliveryTimeTo: order.deliveryTimeTo,
          deliveryFeeRsd: order.deliveryFeeRsd,
          minOrderAmountRsd: order.minOrderAmountRsd,
          preferCall: order.preferCall,
          pickupOptions: order.pickupOptions,
          createdAt: order.createdAt,
          synced: DateTime.now(),
        );

        await _saveOrders(prefs, orders);
        LoggerService.info('Marked order as synced',
            extra: {'orderId': orderId});
      } catch (e, st) {
        LoggerService.error('Failed to mark order as synced', e,
            stackTrace: st);
      }
    });
  }

  /// Obriši porudžbinu iz queue (ako je cancelled)
  Future<void> removePendingOrder(String orderId) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final orders = await _loadOrders(prefs);
        orders.removeWhere((o) => o.id == orderId);
        await _saveOrders(prefs, orders);
        LoggerService.info('Removed pending order',
            extra: {'orderId': orderId});
      } catch (e, st) {
        LoggerService.error('Failed to remove pending order', e,
            stackTrace: st);
      }
    });
  }

  /// Obriši sve sinhronizovane porudžbine (cleanup)
  Future<void> cleanSyncedOrders() {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final orders = await _loadOrders(prefs);
        final pending = orders.where((o) => o.isPending).toList();
        await _saveOrders(prefs, pending);
        LoggerService.info('Cleaned synced orders from queue');
      } catch (e, st) {
        LoggerService.error('Failed to clean synced orders', e, stackTrace: st);
      }
    });
  }

  Future<List<PendingOrder>> _loadOrders(SharedPreferences prefs) async {
    final json = await _readStoredJson(prefs);
    if (json == null || json.isEmpty) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => PendingOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveOrders(
      SharedPreferences prefs, List<PendingOrder> orders) async {
    final json = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _writeStoredJson(prefs, json);
  }

  Future<String?> _readStoredJson(SharedPreferences prefs) async {
    if (kIsWeb) {
      return prefs.getString(_storageKey);
    }

    try {
      final secureValue = await _secureStorage.read(key: _storageKey);
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
    } catch (e, st) {
      LoggerService.warning(
        'Secure storage read failed, falling back to legacy storage',
        extra: {'error': e.toString(), 'stackTrace': st.toString()},
      );
    }

    final legacyValue = prefs.getString(_storageKey);
    if (legacyValue == null || legacyValue.isEmpty) {
      return legacyValue;
    }

    try {
      await _secureStorage.write(key: _storageKey, value: legacyValue);
      await prefs.remove(_storageKey);
    } catch (e, st) {
      LoggerService.warning(
        'Secure storage migration failed; legacy queue retained',
        extra: {'error': e.toString(), 'stackTrace': st.toString()},
      );
    }

    return legacyValue;
  }

  Future<void> _writeStoredJson(SharedPreferences prefs, String json) async {
    if (kIsWeb) {
      await prefs.setString(_storageKey, json);
      return;
    }

    await _secureStorage.write(key: _storageKey, value: json);
    await prefs.remove(_storageKey);
  }
}
