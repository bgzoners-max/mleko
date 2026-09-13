import '../utils/order_status_flow_rules.dart';
import 'seller_delivery_models.dart';

enum OrderStatus {
  sent,
  accepted,
  shipped,
  rejected,
  delivered,
  cancelledBySeller,
  archived
}

extension OrderStatusX on OrderStatus {
  String get dbValue => switch (this) {
        OrderStatus.cancelledBySeller => 'cancelled_by_seller',
        OrderStatus.archived => 'archived',
        _ => name,
      };

  String get displayName => switch (this) {
        OrderStatus.sent => 'Na čekanju',
        OrderStatus.accepted => 'Prihvaćeno',
        OrderStatus.shipped => 'Poslato',
        OrderStatus.rejected => 'Odbijeno',
        OrderStatus.delivered => 'Isporučeno',
        OrderStatus.cancelledBySeller => 'Otkazano',
        OrderStatus.archived => 'Arhivirano',
      };
}

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final String? productName;
  final double? quantityKg;

  /// Jedinica količine: 'kg' ili 'L' (za prikaz)
  final String? unitType;
  final String note;
  final String buyerCity;
  final String buyerPhone;
  final String? buyerAddress;
  final String? buyerPostalCode;
  final OrderStatus status;
  final DateTime createdAt;
  final String? cancellationReason;
  final DateTime? archivedAt;
  final DateTime? expiresAt;
  final DeliveryMethod deliveryMethod;
  final String? deliveryCity;
  final String? deliveryPointId;
  final String? deliveryPointLabel;
  final String? deliveryAddress;
  final int? deliveryWeekday;
  final String? deliveryTimeFrom;
  final String? deliveryTimeTo;
  final double? deliveryFeeRsd;

  /// Ukupna suma porudžbine (iz order_items ili legacy); null za stare porudžbine.
  final double? totalAmount;

  /// Ime druge strane — upisuje servis pri batch-učitavanju profila (bez N+1).
  /// Nije deo DB tabele, ne šalje se na insert/update.
  final String? counterpartyName;

  /// Da li je kupac ostavio recenziju za ovu porudžbinu (batch-učitava se na klijentu).
  final bool? isReviewed;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    this.productName,
    this.quantityKg,
    this.unitType,
    required this.note,
    required this.buyerCity,
    required this.buyerPhone,
    this.buyerAddress,
    this.buyerPostalCode,
    this.status = OrderStatus.sent,
    required this.createdAt,
    this.cancellationReason,
    this.archivedAt,
    this.expiresAt,
    this.deliveryMethod = DeliveryMethod.agreement,
    this.deliveryCity,
    this.deliveryPointId,
    this.deliveryPointLabel,
    this.deliveryAddress,
    this.deliveryWeekday,
    this.deliveryTimeFrom,
    this.deliveryTimeTo,
    this.deliveryFeeRsd,
    this.totalAmount,
    this.counterpartyName,
    this.isReviewed,
  });

  bool get isArchived => status == OrderStatus.archived;

  /// Kupac sme ručno da arhivira (završene: isporučeno, odbijeno, otkazano od prodavca).
  bool get canBuyerManuallyArchive =>
      OrderStatusFlowRules.canBuyerManuallyArchive(status.dbValue);

  /// Prodavac sme ručno da arhivira isti skup završenih statusa kao i kupac.
  bool get canSellerManuallyArchive =>
      OrderStatusFlowRules.canSellerManuallyArchive(status.dbValue);

  String get statusLabel {
    switch (status) {
      case OrderStatus.sent:
        return 'Na čekanju';
      case OrderStatus.accepted:
        return 'Prihvaćeno';
      case OrderStatus.shipped:
        return 'Poslato';
      case OrderStatus.rejected:
        return 'Odbijeno';
      case OrderStatus.delivered:
        return 'Isporučeno';
      case OrderStatus.cancelledBySeller:
        return 'Otkazano';
      case OrderStatus.archived:
        return 'Arhivirano';
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'sent';
    OrderStatus status = OrderStatus.sent;
    for (final s in OrderStatus.values) {
      if (s.name == statusStr || s.dbValue == statusStr || (s == OrderStatus.archived && statusStr == 'arhivirano')) {
        status = s;
        break;
      }
    }
    final createdAt = json['created_at'];
    DateTime date = DateTime.now();
    if (createdAt != null) {
      if (createdAt is String) {
        date = DateTime.tryParse(createdAt) ?? date;
      } else if (createdAt is DateTime) {
        date = createdAt;
      }
    }
    DateTime? archivedAt;
    final archivedAtVal = json['archived_at'];
    if (archivedAtVal != null) {
      if (archivedAtVal is String) {
        archivedAt = DateTime.tryParse(archivedAtVal);
      } else if (archivedAtVal is DateTime) {
        archivedAt = archivedAtVal;
      }
    }
    DateTime? expiresAt;
    final expiresAtVal = json['expires_at'];
    if (expiresAtVal != null) {
      if (expiresAtVal is String) {
        expiresAt = DateTime.tryParse(expiresAtVal);
      } else if (expiresAtVal is DateTime) {
        expiresAt = expiresAtVal;
      }
    }
    return OrderModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String?,
      quantityKg: (json['quantity_kg'] as num?)?.toDouble(),
      unitType: json['unit_type'] as String?,
      note: json['note'] as String? ?? '',
      buyerCity: json['buyer_city'] as String? ?? '',
      buyerPhone: json['buyer_phone'] as String? ?? '',
      buyerAddress: json['buyer_address'] as String?,
      buyerPostalCode: json['buyer_postal_code'] as String?,
      status: status,
      createdAt: date,
      cancellationReason: json['cancellation_reason'] as String?,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      deliveryMethod: deliveryMethodFromDb(json['delivery_method'] as String?),
      deliveryCity: json['delivery_city'] as String?,
      deliveryPointId: json['delivery_point_id'] as String?,
      deliveryPointLabel: json['delivery_point_label'] as String?,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryWeekday: (json['delivery_weekday'] as num?)?.toInt(),
      deliveryTimeFrom:
          normalizeDeliveryTimeString(json['delivery_time_from'] as String?),
      deliveryTimeTo:
          normalizeDeliveryTimeString(json['delivery_time_to'] as String?),
      deliveryFeeRsd: (json['delivery_fee_rsd'] as num?)?.toDouble(),
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      isReviewed: json['is_reviewed'] as bool?,
    );
  }

  bool get hasMultipleItems => productId == null;

  bool get hasSellerDelivery =>
      deliveryMethod == DeliveryMethod.sellerDelivery &&
      deliveryPointLabel != null &&
      deliveryAddress != null &&
      deliveryWeekday != null &&
      deliveryTimeFrom != null &&
      deliveryTimeTo != null;

  String get deliveryMethodLabel => deliveryMethod.label;

  String? get formattedDeliverySchedule {
    if (!hasSellerDelivery) return null;
    return '${sellerDeliveryWeekdayLabel(deliveryWeekday!)}, ${formatDeliveryWindow(deliveryTimeFrom!, deliveryTimeTo!)}';
  }

  OrderModel copyWith({
    String? counterpartyName,
    bool? isReviewed,
  }) {
    return OrderModel(
      id: id,
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
      status: status,
      createdAt: createdAt,
      cancellationReason: cancellationReason,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      deliveryMethod: deliveryMethod,
      deliveryCity: deliveryCity,
      deliveryPointId: deliveryPointId,
      deliveryPointLabel: deliveryPointLabel,
      deliveryAddress: deliveryAddress,
      deliveryWeekday: deliveryWeekday,
      deliveryTimeFrom: deliveryTimeFrom,
      deliveryTimeTo: deliveryTimeTo,
      deliveryFeeRsd: deliveryFeeRsd,
      totalAmount: totalAmount,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'quantity_kg': quantityKg,
      if (unitType != null) 'unit_type': unitType,
      'note': note,
      'buyer_city': buyerCity,
      'buyer_phone': buyerPhone,
      if (buyerAddress != null) 'buyer_address': buyerAddress,
      if (buyerPostalCode != null) 'buyer_postal_code': buyerPostalCode,
      'status': status.dbValue,
      'delivery_method': deliveryMethod.dbValue,
      if (deliveryCity != null) 'delivery_city': deliveryCity,
      if (deliveryPointId != null) 'delivery_point_id': deliveryPointId,
      if (deliveryPointLabel != null)
        'delivery_point_label': deliveryPointLabel,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (deliveryWeekday != null) 'delivery_weekday': deliveryWeekday,
      if (deliveryTimeFrom != null) 'delivery_time_from': deliveryTimeFrom,
      if (deliveryTimeTo != null) 'delivery_time_to': deliveryTimeTo,
      if (deliveryFeeRsd != null) 'delivery_fee_rsd': deliveryFeeRsd,
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
    };
  }
}
