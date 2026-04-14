enum ProductDeliveryMode { none, allSellerPoints, selectedPoints }

extension ProductDeliveryModeX on ProductDeliveryMode {
  String get dbValue => switch (this) {
        ProductDeliveryMode.none => 'none',
        ProductDeliveryMode.allSellerPoints => 'all_seller_points',
        ProductDeliveryMode.selectedPoints => 'selected_points',
      };

  String get label => switch (this) {
        ProductDeliveryMode.none => 'Bez lične dostave domaćina',
        ProductDeliveryMode.allSellerPoints => 'Na svim mojim lokacijama',
        ProductDeliveryMode.selectedPoints => 'Samo na izabranim lokacijama',
      };
}

ProductDeliveryMode productDeliveryModeFromDb(String? value) {
  return switch (value) {
    'selected_points' => ProductDeliveryMode.selectedPoints,
    'all_seller_points' => ProductDeliveryMode.allSellerPoints,
    _ => ProductDeliveryMode.none,
  };
}

class ProductModel {
  static const String unitKg = 'kg';
  static const String unitL = 'L';
  static const String unitG = 'g';
  static const String unitPiece = 'kom';

  final String id;
  final String sellerId;
  final String category;
  final String name;
  final double pricePerKg;
  final double minOrderKg;
  final double? orderStep;
  final double availableKg;

  /// Jedinica: 'kg' ili 'L'. Za L su cena/min/available u litrima (0.75 = 750 ml).
  final String unitType;
  final String description;
  final List<String> imageUrls;
  final List<String> pickupOptions;
  final String location;
  final bool isDomestic;
  final bool availableNow;
  final ProductDeliveryMode deliveryMode;
  final List<String> selectedDeliveryPointIds;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.category,
    required this.name,
    required this.pricePerKg,
    required this.minOrderKg,
    this.orderStep,
    required this.availableKg,
    this.unitType = 'kg',
    required this.description,
    required this.imageUrls,
    required this.pickupOptions,
    required this.location,
    this.isDomestic = true,
    this.availableNow = true,
    this.deliveryMode = ProductDeliveryMode.none,
    this.selectedDeliveryPointIds = const [],
    required this.createdAt,
  });

  bool get isVolumeUnit => unitType == unitL;

  String get priceFormatted {
    if (unitType == unitL) {
      return '${pricePerKg.toStringAsFixed(0)} RSD/L';
    }
    if (unitType == unitPiece) {
      return '${pricePerKg.toStringAsFixed(0)} RSD/kom';
    }
    // Za kg i g: cena je izražena po kilogramu
    return '${pricePerKg.toStringAsFixed(0)} RSD/kg';
  }

  /// Za prikaz količine: "2 kg" ili "1.5 L" ili "750 ml"
  String formatQuantity(double value) {
    if (unitType == unitL) {
      if (value < 1 && value > 0) return '${(value * 1000).round()} ml';
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} L';
    }
    if (unitType == unitG) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    if (unitType == unitPiece) {
      return '${value.toStringAsFixed(0)} kom';
    }
    // default: kg
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';
  }

  String get quantityUnitLabel {
    switch (unitType) {
      case unitL:
        return 'L';
      case unitG:
        return 'g';
      case unitPiece:
        return 'kom';
      default:
        return 'kg';
    }
  }

  String get minOrderFormatted => formatQuantity(minOrderKg);
  String get availableFormatted => formatQuantity(availableKg);

  /// Proizvod je dostupan za narudžbinu (ima na stanju i availableNow)
  bool get isAvailable => availableKg > 0 && availableNow;

  bool get supportsSellerDelivery => deliveryMode != ProductDeliveryMode.none;

  bool get usesSelectedDeliveryPoints =>
      deliveryMode == ProductDeliveryMode.selectedPoints;

  /// Korak kojim se menja količina u UI-u (step), nezavisno od minimalne količine.
  double get quantityStep {
    final explicitStep = orderStep;
    if (explicitStep != null && explicitStep > 0) {
      return explicitStep;
    }

    if (minOrderKg > 0) {
      return minOrderKg;
    }

    switch (unitType) {
      case unitL:
        // Tečnosti (mleko, sok) – osnovni korak 1L; specijalni slučajevi (0.5L) mogu se rešiti kasnije po kategoriji.
        return 1.0;
      case unitG:
        // 50g
        return 0.05;
      case unitPiece:
        // 10 kom
        return 10.0;
      default:
        // kg – 1 kg
        return 1.0;
    }
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final images = json['image_urls'] as List<dynamic>?;
    final pickup = json['pickup_options'] as List<dynamic>?;
    final createdAt = json['created_at'];
    DateTime date = DateTime.now();
    if (createdAt != null) {
      if (createdAt is String) {
        date = DateTime.tryParse(createdAt) ?? date;
      } else if (createdAt is DateTime) {
        date = createdAt;
      }
    }
    final unit = json['unit_type'] as String?;
    final unitType = switch (unit) {
      unitL => unitL,
      unitG => unitG,
      unitPiece => unitPiece,
      _ => unitKg,
    };
    final minOrder = (json['min_order_kg'] as num?)?.toDouble() ?? 1;
    final parsedOrderStep = (json['order_step'] as num?)?.toDouble();
    final normalizedOrderStep = (parsedOrderStep != null && parsedOrderStep > 0)
        ? parsedOrderStep
        : minOrder;

    final id = json['id'];

    return ProductModel(
      id: id is String ? id : (id?.toString() ?? ''),
      sellerId: json['seller_id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0,
      minOrderKg: minOrder,
      orderStep: normalizedOrderStep,
      availableKg: (json['available_kg'] as num?)?.toDouble() ?? 0,
      unitType: unitType,
      description: json['description'] as String? ?? '',
      imageUrls: images?.map((e) => e.toString()).toList() ?? [],
      pickupOptions: pickup?.map((e) => e.toString()).toList() ?? [],
      location: json['location'] as String? ?? '',
      isDomestic: json['is_domestic'] as bool? ?? true,
      availableNow: json['available_now'] as bool? ?? true,
      deliveryMode: productDeliveryModeFromDb(json['delivery_mode'] as String?),
      selectedDeliveryPointIds:
          (json['selected_delivery_point_ids'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      createdAt: date,
    );
  }

  /// Parsira unos količine za L: "750" → 0.75, "0.75" → 0.75, "1" → 1. Brojevi >= 100 tretiraju se kao ml.
  static double parseQuantityL(String text) {
    final v = double.tryParse(text.replaceAll(',', '.').trim());
    if (v == null) return 0;
    if (v >= 100) return v / 1000; // ml u litre
    return v;
  }

  /// Formatira količinu za prikaz (npr. u porudžbini) kada imamo samo vrednost i jedinicu.
  static String formatQuantityWithUnit(double value, String unitType) {
    if (unitType == unitL) {
      if (value < 1 && value > 0) return '${(value * 1000).round()} ml';
      return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} L';
    }
    if (unitType == unitG) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    if (unitType == unitPiece) {
      return '${value.toStringAsFixed(0)} kom';
    }
    // default: kg
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} kg';
  }

  /// Parsira unos količine za g: "100" → 0.1, "250" → 0.25, "1000" → 1.0.
  static double parseQuantityG(String text) {
    final v = double.tryParse(text.replaceAll(',', '.').trim());
    if (v == null) return 0;
    return v / 1000; // grami u kilograme
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category': category,
      'name': name,
      'price_per_kg': pricePerKg,
      'min_order_kg': minOrderKg,
      if (orderStep != null) 'order_step': orderStep,
      'available_kg': availableKg,
      'unit_type': unitType,
      'description': description,
      'image_urls': imageUrls,
      'pickup_options': pickupOptions,
      'location': location,
      'is_domestic': isDomestic,
      'available_now': availableNow,
      'delivery_mode': deliveryMode.dbValue,
    };
  }
}
