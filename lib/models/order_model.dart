enum OrderStatus { sent, accepted, rejected, delivered, cancelledBySeller, archived }

extension OrderStatusX on OrderStatus {
  String get dbValue => switch (this) {
        OrderStatus.cancelledBySeller => 'cancelled_by_seller',
        OrderStatus.archived => 'arhivirano',
        _ => name,
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
  final OrderStatus status;
  final DateTime createdAt;
  final String? cancellationReason;
  final DateTime? archivedAt;
  final DateTime? expiresAt;
  /// Ukupna suma porudžbine (iz order_items ili legacy); null za stare porudžbine.
  final double? totalAmount;

  /// Ime druge strane — upisuje servis pri batch-učitavanju profila (bez N+1).
  /// Nije deo DB tabele, ne šalje se na insert/update.
  final String? counterpartyName;

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
    this.status = OrderStatus.sent,
    required this.createdAt,
    this.cancellationReason,
    this.archivedAt,
    this.expiresAt,
    this.totalAmount,
    this.counterpartyName,
  });

  bool get isArchived => status == OrderStatus.archived;

  String get statusLabel {
    switch (status) {
      case OrderStatus.sent:
        return 'Poslato';
      case OrderStatus.accepted:
        return 'Prihvaćeno';
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
      if (s.name == statusStr || s.dbValue == statusStr) {
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
      } else if (archivedAtVal is DateTime) archivedAt = archivedAtVal;
    }
    DateTime? expiresAt;
    final expiresAtVal = json['expires_at'];
    if (expiresAtVal != null) {
      if (expiresAtVal is String) {
        expiresAt = DateTime.tryParse(expiresAtVal);
      } else if (expiresAtVal is DateTime) expiresAt = expiresAtVal;
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
      status: status,
      createdAt: date,
      cancellationReason: json['cancellation_reason'] as String?,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
    );
  }

  bool get hasMultipleItems => productId == null;

  OrderModel copyWith({String? counterpartyName}) {
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
      status: status,
      createdAt: createdAt,
      cancellationReason: cancellationReason,
      archivedAt: archivedAt,
      expiresAt: expiresAt,
      totalAmount: totalAmount,
      counterpartyName: counterpartyName ?? this.counterpartyName,
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
      'status': status.dbValue,
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
    };
  }
}
