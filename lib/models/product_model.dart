import '../utils/quantity_engine.dart';

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
  static const String unitVeza = 'veza';
  static const String unitPak = 'pak';

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
  final bool sellerIsVerified;
  final double? avgRating;
  final int reviewCount;

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
    this.sellerIsVerified = false,
    this.avgRating,
    this.reviewCount = 0,
  });

  // Sentinel vrednost za copyWith da razlikuje "nije prosleđeno" od "prosleđeno null"
  static const Object _undefined = Object();

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? category,
    String? name,
    double? pricePerKg,
    double? minOrderKg,
    Object? orderStep = _undefined,
    double? availableKg,
    String? unitType,
    String? description,
    List<String>? imageUrls,
    List<String>? pickupOptions,
    String? location,
    bool? isDomestic,
    bool? availableNow,
    ProductDeliveryMode? deliveryMode,
    List<String>? selectedDeliveryPointIds,
    DateTime? createdAt,
    bool? sellerIsVerified,
    Object? avgRating = _undefined,
    int? reviewCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      category: category ?? this.category,
      name: name ?? this.name,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      minOrderKg: minOrderKg ?? this.minOrderKg,
      orderStep: identical(orderStep, _undefined) ? this.orderStep : orderStep as double?,
      availableKg: availableKg ?? this.availableKg,
      unitType: unitType ?? this.unitType,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      pickupOptions: pickupOptions ?? this.pickupOptions,
      location: location ?? this.location,
      isDomestic: isDomestic ?? this.isDomestic,
      availableNow: availableNow ?? this.availableNow,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      selectedDeliveryPointIds:
          selectedDeliveryPointIds ?? this.selectedDeliveryPointIds,
      createdAt: createdAt ?? this.createdAt,
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      avgRating: identical(avgRating, _undefined) ? this.avgRating : avgRating as double?,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  bool get isVolumeUnit => unitType == unitL;

  /// Oznaka valute za prikaz — domaći ton ("din.").
  /// U podacima i u SEO strukturiranim podacima i dalje ostaje ISO kod "RSD".
  static const String priceCurrencyLabel = 'din.';

  /// Brojčani deo cene, bez valute i jedinice (npr. "800").
  String get priceNumber => pricePerKg.toStringAsFixed(0);

  /// Sufiks jedinice u ceni (npr. "/kg", "/L", "/kom").
  String get priceUnitSuffix {
    switch (unitType) {
      case unitL:
        return '/L';
      case unitPiece:
        return '/kom';
      case unitVeza:
        return '/veza';
      case unitPak:
        return '/pak';
      default:
        // Za kg i g: cena je izražena po kilogramu
        return '/kg';
    }
  }

  /// Cena u formatu za prikaz, npr. "800 din./kg" ili "500 din./L".
  String get priceFormatted =>
      '$priceNumber $priceCurrencyLabel$priceUnitSuffix';

  /// Srpska konvencija decimala: zarez umesto tačke ("1,5" umesto "1.5").
  static String _formatDecimal(double value) {
    final decimals = value.truncateToDouble() == value ? 0 : 1;
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  /// Za prikaz količine: "2 kg" ili "100 g" ili "1,5 L" ili "750 ml"
  String formatQuantity(double value) {
    if (unitType == unitL) {
      if (value < 1 && value > 0) return '${(value * 1000).round()} ml';
      return '${_formatDecimal(value)} L';
    }
    if (unitType == unitG) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    if (unitType == unitPiece) {
      return '${value.toStringAsFixed(0)} kom';
    }
    if (unitType == unitVeza) {
      return '${value.toStringAsFixed(0)} veza';
    }
    if (unitType == unitPak) {
      return '${value.toStringAsFixed(0)} pak';
    }
    // default: kg (vrednosti manje od 1 kg se automatski prikazuju u gramima, npr. 0.1 -> 100 g)
    if (value < 1 && value > 0) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    return '${_formatDecimal(value)} kg';
  }

  String get quantityUnitLabel {
    switch (unitType) {
      case unitL:
        return 'L';
      case unitG:
        return 'g';
      case unitPiece:
        return 'kom';
      case unitVeza:
        return 'veza';
      case unitPak:
        return 'pak';
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

  /// Korak kojim se menja količina u UI-u (step), usklađen sa REPO_BIBLE.md i QuantityEngine.
  double get quantityStep => QuantityEngine.resolveStep(
        orderStep: orderStep,
        minQuantity: minOrderKg,
      );

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
      unitVeza => unitVeza,
      unitPak => unitPak,
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
      sellerIsVerified: json['seller_is_verified'] as bool? ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Parsira unos količine za kg: "0.1" / "0,1" → 0.1, "100g" / "100 g" → 0.1, "500g" → 0.5, "1.5 kg" → 1.5.
  static double parseQuantityKg(String text) {
    var raw = text.trim().toLowerCase();
    if (raw.isEmpty) return 0;

    final isGrams = (raw.endsWith('grama') ||
            raw.endsWith('gram') ||
            raw.endsWith('gr') ||
            raw.endsWith('g')) &&
        !raw.contains('kg');

    if (isGrams) {
      final numPart = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
      final v = double.tryParse(numPart.replaceAll(',', '.'));
      if (v != null && v > 0) return v / 1000.0;
    }

    raw = raw.replaceAll('kg', '').replaceAll(',', '.').trim();
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return 0;

    return v;
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
      return '${_formatDecimal(value)} L';
    }
    if (unitType == unitG) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    if (unitType == unitPiece) {
      return '${value.toStringAsFixed(0)} kom';
    }
    if (unitType == unitVeza) {
      return '${value.toStringAsFixed(0)} veza';
    }
    if (unitType == unitPak) {
      return '${value.toStringAsFixed(0)} pak';
    }
    // default: kg (vrednosti manje od 1 kg se prikazuju u gramima, npr. 0.1 -> 100 g)
    if (value < 1 && value > 0) {
      final grams = (value * 1000).round();
      return '$grams g';
    }
    return '${_formatDecimal(value)} kg';
  }

  /// Parsira unos količine za g: "100" → 0.1, "250" → 0.25, "1000" → 1.0.
  static double parseQuantityG(String text) {
    final v = double.tryParse(text.replaceAll(',', '.').trim());
    if (v == null) return 0;
    return v / 1000; // grami u kilograme
  }

  /// Mapa za perzistenciju u tabelu `products`.
  /// Isključuje izvedena polja iz SQL view-a (seller_is_verified, avg_rating, review_count)
  /// i relacione kolekcije (selected_delivery_point_ids) koje ne postoje kao kolone u tabeli `products`.
  Map<String, dynamic> toDbMap({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
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
      if (includeCreatedAt) 'created_at': createdAt.toIso8601String(),
    };
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
      'selected_delivery_point_ids': selectedDeliveryPointIds,
      'created_at': createdAt.toIso8601String(),
      'seller_is_verified': sellerIsVerified,
      if (avgRating != null) 'avg_rating': avgRating,
      'review_count': reviewCount,
    };
  }
}
