enum DeliveryMethod { agreement, sellerDelivery }

extension DeliveryMethodX on DeliveryMethod {
  String get dbValue => switch (this) {
        DeliveryMethod.agreement => 'agreement',
        DeliveryMethod.sellerDelivery => 'seller_delivery',
      };

  String get label => switch (this) {
        DeliveryMethod.agreement => 'Dogovor sa domaćinom',
        DeliveryMethod.sellerDelivery => 'Lična dostava domaćina',
      };
}

DeliveryMethod deliveryMethodFromDb(String? value) {
  return switch (value) {
    'seller_delivery' => DeliveryMethod.sellerDelivery,
    _ => DeliveryMethod.agreement,
  };
}

String sellerDeliveryWeekdayLabel(int weekday) {
  const labels = <String>[
    'Ponedeljak',
    'Utorak',
    'Sreda',
    'Četvrtak',
    'Petak',
    'Subota',
    'Nedelja',
  ];
  if (weekday < 1 || weekday > labels.length) return 'Nepoznat dan';
  return labels[weekday - 1];
}

String normalizeDeliveryTimeString(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return '';
  final parts = value.split(':');
  if (parts.length < 2) return value;
  final hour = parts[0].padLeft(2, '0');
  final minute = parts[1].padLeft(2, '0');
  return '$hour:$minute';
}

String formatDeliveryWindow(String timeFrom, String timeTo) {
  return '${normalizeDeliveryTimeString(timeFrom)} - ${normalizeDeliveryTimeString(timeTo)}';
}

String? formatRsdAmount(double? value) {
  if (value == null) return null;
  final rounded = value.roundToDouble();
  final text =
      rounded == value ? rounded.toStringAsFixed(0) : value.toStringAsFixed(2);
  return '$text RSD';
}

class SellerDeliverySlotModel {
  final String id;
  final String deliveryPointId;
  final int weekday;
  final String timeFrom;
  final String timeTo;
  final double? deliveryFeeRsd;
  final double? minOrderAmountRsd;
  final int? maxOrders;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SellerDeliverySlotModel({
    required this.id,
    required this.deliveryPointId,
    required this.weekday,
    required this.timeFrom,
    required this.timeTo,
    this.deliveryFeeRsd,
    this.minOrderAmountRsd,
    this.maxOrders,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SellerDeliverySlotModel.fromJson(Map<String, dynamic> json) {
    return SellerDeliverySlotModel(
      id: json['id'] as String? ?? '',
      deliveryPointId: json['delivery_point_id'] as String? ?? '',
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      timeFrom: normalizeDeliveryTimeString(json['time_from'] as String?),
      timeTo: normalizeDeliveryTimeString(json['time_to'] as String?),
      deliveryFeeRsd: (json['delivery_fee_rsd'] as num?)?.toDouble(),
      minOrderAmountRsd: (json['min_order_amount_rsd'] as num?)?.toDouble(),
      maxOrders: (json['max_orders'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'delivery_point_id': deliveryPointId,
      'weekday': weekday,
      'time_from': normalizeDeliveryTimeString(timeFrom),
      'time_to': normalizeDeliveryTimeString(timeTo),
      'delivery_fee_rsd': deliveryFeeRsd,
      'min_order_amount_rsd': minOrderAmountRsd,
      'max_orders': maxOrders,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      ...toInsertJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String get weekdayLabel => sellerDeliveryWeekdayLabel(weekday);
  String get timeRangeLabel => formatDeliveryWindow(timeFrom, timeTo);
}

class SellerDeliveryPointModel {
  final String id;
  final String sellerId;
  final String city;
  final String label;
  final String address;
  final double? lat;
  final double? lng;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SellerDeliverySlotModel> slots;

  const SellerDeliveryPointModel({
    required this.id,
    required this.sellerId,
    required this.city,
    required this.label,
    required this.address,
    this.lat,
    this.lng,
    this.notes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.slots = const [],
  });

  factory SellerDeliveryPointModel.fromJson(
    Map<String, dynamic> json, {
    List<SellerDeliverySlotModel> slots = const [],
  }) {
    return SellerDeliveryPointModel(
      id: json['id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      city: json['city'] as String? ?? '',
      label: json['label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      slots: slots,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'seller_id': sellerId,
      'city': city.trim(),
      'label': label.trim(),
      'address': address.trim(),
      'lat': lat,
      'lng': lng,
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      ...toInsertJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  SellerDeliveryPointModel copyWith({
    List<SellerDeliverySlotModel>? slots,
  }) {
    return SellerDeliveryPointModel(
      id: id,
      sellerId: sellerId,
      city: city,
      label: label,
      address: address,
      lat: lat,
      lng: lng,
      notes: notes,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      slots: slots ?? this.slots,
    );
  }

  List<SellerDeliverySlotModel> get activeSlots {
    final active = slots.where((slot) => slot.isActive).toList();
    active.sort((left, right) {
      final weekdayCompare = left.weekday.compareTo(right.weekday);
      if (weekdayCompare != 0) return weekdayCompare;
      return left.timeFrom.compareTo(right.timeFrom);
    });
    return active;
  }

  String get summaryLabel => '$label, $address';
}

class DeliverySelectionModel {
  final DeliveryMethod method;
  final String pointId;
  final String slotId;
  final String city;
  final String pointLabel;
  final String address;
  final int weekday;
  final String timeFrom;
  final String timeTo;
  final double? deliveryFeeRsd;
  final double? minOrderAmountRsd;

  const DeliverySelectionModel({
    required this.method,
    required this.pointId,
    required this.slotId,
    required this.city,
    required this.pointLabel,
    required this.address,
    required this.weekday,
    required this.timeFrom,
    required this.timeTo,
    this.deliveryFeeRsd,
    this.minOrderAmountRsd,
  });

  factory DeliverySelectionModel.fromPointAndSlot(
    SellerDeliveryPointModel point,
    SellerDeliverySlotModel slot,
  ) {
    return DeliverySelectionModel(
      method: DeliveryMethod.sellerDelivery,
      pointId: point.id,
      slotId: slot.id,
      city: point.city,
      pointLabel: point.label,
      address: point.address,
      weekday: slot.weekday,
      timeFrom: slot.timeFrom,
      timeTo: slot.timeTo,
      deliveryFeeRsd: slot.deliveryFeeRsd,
      minOrderAmountRsd: slot.minOrderAmountRsd,
    );
  }

  String get scheduleLabel =>
      '${sellerDeliveryWeekdayLabel(weekday)}, ${formatDeliveryWindow(timeFrom, timeTo)}';

  String? get feeLabel => formatRsdAmount(deliveryFeeRsd);
  String? get minOrderLabel => formatRsdAmount(minOrderAmountRsd);
}
