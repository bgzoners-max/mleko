import 'dart:convert';
import 'dart:math' as math;
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
  final int retryCount;
  final String? lastError;
  final DateTime? lastAttemptAt;

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
    this.retryCount = 0,
    this.lastError,
    this.lastAttemptAt,
  });

  bool get isPending => synced == null;

  /// Eksponencijalni backoff razmak po formuli: min(2^retryCount * 5s, 1h)
  Duration get retryBackoff {
    if (retryCount <= 0) return Duration.zero;
    final exp = retryCount > 15 ? 15 : retryCount;
    final seconds = math.min((math.pow(2, exp) * 5).toInt(), 3600);
    return Duration(seconds: seconds);
  }

  /// Proverava da li je prošao interval eksponencijalnog backoff-a
  bool get isReadyForRetry {
    if (retryCount <= 0 || lastAttemptAt == null) return true;
    return DateTime.now().isAfter(lastAttemptAt!.add(retryBackoff));
  }

  PendingOrder copyWith({
    DateTime? synced,
    int? retryCount,
    String? lastError,
    DateTime? lastAttemptAt,
  }) {
    return PendingOrder(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      productName: productName,
      quantityKg: quantityKg,
      unitType: unitType,
      note: note,
      buyerCity: buyerCity,
      buyerAddress: buyerAddress,
      buyerPostalCode: buyerPostalCode,
      buyerPhone: buyerPhone,
      deliveryMethod: deliveryMethod,
      deliveryCity: deliveryCity,
      deliveryPointId: deliveryPointId,
      deliverySlotId: deliverySlotId,
      deliveryPointLabel: deliveryPointLabel,
      deliveryAddress: deliveryAddress,
      deliveryWeekday: deliveryWeekday,
      deliveryTimeFrom: deliveryTimeFrom,
      deliveryTimeTo: deliveryTimeTo,
      deliveryFeeRsd: deliveryFeeRsd,
      minOrderAmountRsd: minOrderAmountRsd,
      preferCall: preferCall,
      pickupOptions: pickupOptions,
      createdAt: createdAt,
      synced: synced ?? this.synced,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

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
        'retry_count': retryCount,
        'last_error': lastError,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
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
        retryCount: (json['retry_count'] as num?)?.toInt() ?? 0,
        lastError: json['last_error'] as String?,
        lastAttemptAt: json['last_attempt_at'] != null
            ? DateTime.tryParse(json['last_attempt_at'] as String)
            : null,
      );
}

/// Servis za offline queue - čuvaj orders kada nema interneta
class OrderQueueService {
  static const _storageKey = 'mleko_pending_orders';
  static const int maxQueueLength = 50;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (e) {
        LoggerService.warning('Error in OrderQueueService listener: $e');
      }
    }
  }

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

  /// Preuzmi broj pending porudžbina
  Future<int> getPendingCount({bool onlyUnsynced = true}) async {
    final orders = await getPendingOrders(onlyUnsynced: onlyUnsynced);
    return orders.length;
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

        // Očisti već sinhronizovane pre provere limita radi zaštite storage prostora
        orders.removeWhere((o) => !o.isPending);

        if (orders.length >= maxQueueLength) {
          throw AppError(
            message: 'Order queue limit reached ($maxQueueLength)',
            userMessage:
                'Dostignut je maksimalan broj porudžbina na čekanju ($maxQueueLength). Povežite se na internet.',
            type: ErrorType.validation,
          );
        }

        orders.add(order);
        await _saveOrders(prefs, orders);
        _notifyListeners();
        LoggerService.info('Added pending order to queue',
            extra: {'orderId': order.id});
      } on AppError {
        rethrow;
      } catch (e) {
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
        orders[index] = order.copyWith(
          synced: DateTime.now(),
        );

        await _saveOrders(prefs, orders);
        _notifyListeners();
        LoggerService.info('Marked order as synced',
            extra: {'orderId': orderId});
      } catch (e, st) {
        LoggerService.error('Failed to mark order as synced', e,
            stackTrace: st);
      }
    });
  }

  /// Evidentira neuspešan pokušaj sinhronizacije i ažurira brojač grešaka
  Future<void> recordOrderFailure(String orderId, {required String error}) {
    return _serialized(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final orders = await _loadOrders(prefs);

        final index = orders.indexWhere((o) => o.id == orderId);
        if (index == -1) {
          LoggerService.warning('Order not found for failure recording',
              extra: {'orderId': orderId});
          return;
        }

        final order = orders[index];
        orders[index] = order.copyWith(
          retryCount: order.retryCount + 1,
          lastError: error,
          lastAttemptAt: DateTime.now(),
        );

        await _saveOrders(prefs, orders);
        _notifyListeners();
        LoggerService.info('Recorded sync failure for order', extra: {
          'orderId': orderId,
          'retryCount': orders[index].retryCount,
          'error': error,
        });
      } catch (e, st) {
        LoggerService.error('Failed to record order sync failure', e,
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
        _notifyListeners();
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
        _notifyListeners();
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

    try {
      await _secureStorage.write(key: _storageKey, value: json);
      await prefs.remove(_storageKey);
    } catch (e, st) {
      LoggerService.warning(
        'Secure storage write failed, falling back to legacy storage',
        extra: {'error': e.toString(), 'stackTrace': st.toString()},
      );
      await prefs.setString(_storageKey, json);
    }
  }
}
