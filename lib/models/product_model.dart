import '../services/core/logger_service.dart';
import '../utils/product_formatting_utils.dart';
import '../utils/quantity_engine.dart';
import '../utils/sales_counter_formatter.dart';
import 'product_delivery_scope.dart';
import 'product_stats.dart';
import 'product_variant.dart';

export '../utils/product_formatting_utils.dart';
export 'product_delivery_scope.dart';
export 'product_stats.dart';
export 'product_variant.dart';

class ProductModel {
  static const String unitKg = 'kg';
  static const String unitL = 'L';
  static const String unitG = 'g';
  static const String unitMl = 'ml';
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

  /// Jedinica mere definisana u REPO_BIBLE.md §3:
  /// 'kg', 'L', 'kom', 'veza', 'pak'.
  /// Za 'L' su cena/min/available u litrima (0.75 = 750 ml).
  /// Legacy 'g' se u [fromJson] automatski normalizuje u 'kg'.
  final String unitType;
  final String description;
  final List<String> imageUrls;
  final List<String> pickupOptions;
  final String location;
  final bool isDomestic;
  final bool availableNow;
  final DateTime createdAt;

  final ProductDeliveryMode deliveryMode;
  final List<String> selectedDeliveryPointIds;
  final bool sellerIsVerified;
  final double? avgRating;
  final int reviewCount;
  final int orderCount;
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;

  static const String cartKeySeparator = '::';

  bool get hasVariants => variants.isNotEmpty;

  /// Vraća naslov grupe varijanti (npr. 'Ukus', 'Vrsta', 'Nadev', 'Pakovanje', 'Miris').
  String get variantGroupTitle {
    for (final v in variants) {
      if (v.group != null && v.group!.trim().isNotEmpty) {
        return v.group!.trim();
      }
    }
    final labels = variants.map((v) => v.label.toLowerCase()).join(' ');
    final hasPackageHints = labels.contains('ml') ||
        labels.contains(' g') ||
        labels.contains('kg') ||
        labels.contains(' l') ||
        labels.contains('pak') ||
        labels.contains('teg') ||
        labels.contains('fla');
    if (hasPackageHints) {
      return 'Pakovanje';
    }
    return 'Ukus';
  }

  /// Tekst poziva na akciju za biranje varijante (npr. 'Izaberi ukus:', 'Izaberi vrstu:', 'Izaberi nadev:').
  String get variantSelectorPrompt {
    final title = variantGroupTitle.trim();
    final lower = title.toLowerCase();
    if (lower.startsWith('izaberi')) {
      return title.endsWith(':') ? title : '$title:';
    }
    if (lower == 'ukus' || lower == 'ukusi' || lower.contains('ukus')) {
      return 'Izaberi ukus:';
    }
    if (lower == 'vrsta' || lower == 'sorta' || lower == 'vrste') {
      return 'Izaberi vrstu:';
    }
    if (lower == 'nadev' || lower == 'sastav') {
      return 'Izaberi nadev:';
    }
    if (lower == 'pakovanje' || lower == 'velicina' || lower == 'veličina') {
      return 'Izaberi pakovanje:';
    }
    if (lower == 'miris') {
      return 'Izaberi miris:';
    }
    return 'Izaberi $lower:';
  }

  /// Da li sve varijante ovog proizvoda imaju identičnu cenu.
  bool get hasUniformVariantPrice {
    if (variants.isEmpty) return false;
    final firstPrice = variants.first.price;
    return variants.every((v) => (v.price - firstPrice).abs() < 0.001);
  }

  String get baseName {
    final current = selectedVariant;
    if (current != null) {
      final suffix = ' (${current.label})';
      if (name.endsWith(suffix)) {
        return name.substring(0, name.length - suffix.length);
      }
    }
    return name;
  }

  String get cartKey => selectedVariant != null
      ? '$id$cartKeySeparator${selectedVariant!.id}'
      : id;

  static String extractProductId(String cartKey) {
    final idx = cartKey.indexOf(cartKeySeparator);
    return idx >= 0 ? cartKey.substring(0, idx) : cartKey;
  }

  static String? extractVariantId(String cartKey) {
    final idx = cartKey.indexOf(cartKeySeparator);
    if (idx < 0) return null;
    final variantId = cartKey.substring(idx + cartKeySeparator.length).trim();
    return variantId.isEmpty ? null : variantId;
  }

  ProductModel withSelectedVariant(ProductVariant? variant) {
    if (variant == null) {
      return copyWith(
        name: baseName,
        selectedVariant: null,
      );
    }
    return copyWith(
      name: '$baseName (${variant.label})',
      pricePerKg: variant.price,
      selectedVariant: variant,
    );
  }

  ProductModel resolveForCartKey(String cartKey) {
    final variantId = extractVariantId(cartKey);
    if (variantId == null) {
      if (variants.isNotEmpty && selectedVariant == null) {
        return withSelectedVariant(variants.first);
      }
      return this;
    }
    for (final v in variants) {
      if (v.id == variantId) {
        return withSelectedVariant(v);
      }
    }
    if (variants.isNotEmpty) {
      return withSelectedVariant(variants.first);
    }
    return this;
  }

  /// Modularne pod-komponente (rešenje za fat model):
  ProductDeliveryScope get deliveryScope => ProductDeliveryScope(
        mode: deliveryMode,
        selectedPointIds: selectedDeliveryPointIds,
      );

  ProductStats get stats => ProductStats(
        sellerIsVerified: sellerIsVerified,
        avgRating: avgRating,
        reviewCount: reviewCount,
        orderCount: orderCount,
      );

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
    this.orderCount = 0,
    this.variants = const [],
    this.selectedVariant,
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
    int? orderCount,
    ProductDeliveryScope? deliveryScope,
    ProductStats? stats,
    List<ProductVariant>? variants,
    Object? selectedVariant = _undefined,
  }) {
    final effectiveDeliveryScope = deliveryScope ??
        ((deliveryMode != null || selectedDeliveryPointIds != null)
            ? this.deliveryScope.copyWith(
                  mode: deliveryMode,
                  selectedPointIds: selectedDeliveryPointIds,
                )
            : this.deliveryScope);

    final resolvedAvgRating = identical(avgRating, _undefined)
        ? this.avgRating
        : avgRating as double?;

    final effectiveStats = stats ??
        ((sellerIsVerified != null ||
                !identical(avgRating, _undefined) ||
                reviewCount != null ||
                orderCount != null)
            ? this.stats.copyWith(
                  sellerIsVerified: sellerIsVerified,
                  avgRating: resolvedAvgRating,
                  reviewCount: reviewCount,
                  orderCount: orderCount,
                )
            : this.stats);

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
      deliveryMode: effectiveDeliveryScope.mode,
      selectedDeliveryPointIds: effectiveDeliveryScope.selectedPointIds,
      createdAt: createdAt ?? this.createdAt,
      sellerIsVerified: effectiveStats.sellerIsVerified,
      avgRating: effectiveStats.avgRating,
      reviewCount: effectiveStats.reviewCount,
      orderCount: effectiveStats.orderCount,
      variants: variants ?? this.variants,
      selectedVariant: identical(selectedVariant, _undefined)
          ? this.selectedVariant
          : selectedVariant as ProductVariant?,
    );
  }



  /// Alias za [pricePerKg]. Predstavlja cenu po jedinici definisanoj u [unitType]
  /// (npr. RSD/kg, RSD/L, RSD/kom, RSD/veza, RSD/pak).
  ///
  /// Baza podataka koristi kolonu `price_per_kg` iz istorijskih razloga, ali za proizvode
  /// sa jedinicama kom, L, veza, pak ova vrednost predstavlja cenu po toj celoj jedinici
  /// (npr. tegla meda, boca soka, veza sremuša ili pakovanje jaja).
  double get pricePerUnit => pricePerKg;

  bool get isVolumeUnit => unitType == unitL;

  /// Oznaka valute za prikaz — domaći ton ("din.").
  /// U podacima i u SEO strukturiranim podacima i dalje ostaje ISO kod "RSD".
  static const String priceCurrencyLabel = 'din.';

  /// Da li je proizvod definisan u podjedinici (grami ili mililitri, tj. minOrderKg < 1).
  bool get isSubUnitProduct =>
      (unitType == unitKg || unitType == unitL) &&
      minOrderKg > 0 &&
      minOrderKg < 1 &&
      selectedVariant == null;

  /// Brojčani deo cene, bez valute i jedinice (npr. "800" ili "199,99").
  String get priceNumber => _formatDecimal(pricePerKg);

  /// Ukupna cena za zadatu količinu [quantity].
  /// Za proizvode u gramima ili mililitrima (`isSubUnitProduct`, tj. `minOrderKg < 1`),
  /// `pricePerKg` je cena za to pakovanje (`minOrderKg`), pa se cena množi brojem pakovanja.
  double totalPriceForQuantity(double quantity) {
    if (isSubUnitProduct && minOrderKg > 0) {
      return ((quantity / minOrderKg) * pricePerKg * 100).round() / 100.0;
    }
    return (quantity * pricePerKg * 100).round() / 100.0;
  }

  /// Sufiks jedinice u ceni (npr. "/kg", "/L", "/330 ml", "/250 g", "/kom").
  String get priceUnitSuffix {
    if (isSubUnitProduct) {
      return '/${formatQuantity(minOrderKg)}';
    }
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

  static String _formatDecimal(double value) =>
      ProductFormattingUtils.formatDecimal(value);

  static String pluralSr(
    num count, {
    required String one,
    required String few,
    required String many,
  }) =>
      ProductFormattingUtils.pluralSr(count, one: one, few: few, many: many);


  /// Za prikaz količine: "2 kg" ili "100 g" ili "1,5 L" ili "750 ml" ili "2 veze" ili "3 pakovanja".
  String formatQuantity(double value) => formatQuantityWithUnit(value, unitType);

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
  String get availableFormatted => isSubUnitProduct
      ? formatQuantityWithUnit(availableKg, unitPiece)
      : formatQuantity(availableKg);

  /// Formatiran podatak o broju prodaja (Social Proof: npr. '10+ prodaja', '50+ prodaja').
  /// Vraća `null` ako ima manje od 10 prodaja kako se ne bi prikazivali niski brojevi.
  String? get salesBadgeText => formatSalesCount(orderCount);

  /// Proizvod je dostupan za narudžbinu (autoritativno pravilo: REPO_BIBLE.md §11).
  bool get isAvailable => availableNow;

  /// Da li postoji evidentirano brojno stanje zaliha (informativni karakter).
  bool get hasStockInfo => availableKg > 0;

  /// Maksimalni preporučeni limit za UI stepper (REPO_BIBLE.md §11).
  double get maxOrderQuantity => QuantityEngine.resolveMaxQuantity(
        minQuantity: minOrderKg,
        step: quantityStep,
      );

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
      unitL || unitMl => unitL,
      unitPiece => unitPiece,
      unitVeza => unitVeza,
      unitPak => unitPak,
      // 'g' se u modelu normalizuje u 'kg' (sa minOrderKg < 1 za grame)
      _ => unitKg,
    };
    final minOrder = (json['min_order_kg'] as num?)?.toDouble() ?? 1;
    final parsedOrderStep = (json['order_step'] as num?)?.toDouble();
    if (parsedOrderStep == null || parsedOrderStep <= 0) {
      LoggerService.warning(
        'ProductModel.fromJson: order_step is missing or non-positive, falling back to min_order_kg',
        extra: {'id': json['id'], 'name': json['name'], 'fallback': minOrder},
      );
    }
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
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      variants: ProductVariant.listFromDynamic(json['variants']),
    );


  }

  static double parseQuantityKg(String text) =>
      ProductFormattingUtils.parseQuantityKg(text);

  static double parseQuantityL(String text) =>
      ProductFormattingUtils.parseQuantityL(text);

  static String formatQuantityWithUnit(double value, String unitType) =>
      ProductFormattingUtils.formatQuantityWithUnit(value, unitType);

  static double parseQuantityG(String text) =>
      ProductFormattingUtils.parseQuantityG(text);

  static double parseQuantityMl(String text) =>
      ProductFormattingUtils.parseQuantityMl(text);


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
      'name': baseName,
      'price_per_kg': pricePerKg,
      'min_order_kg': minOrderKg,
      'order_step': (orderStep != null && orderStep! > 0)
          ? orderStep
          : (minOrderKg > 0 ? minOrderKg : 1.0),
      'available_kg': availableKg,
      'unit_type': unitType,
      'description': description,
      'image_urls': imageUrls,
      'pickup_options': pickupOptions,
      'location': location,
      'is_domestic': isDomestic,
      'available_now': availableNow,
      'delivery_mode': deliveryMode.dbValue,
      'variants': variants.map((v) => v.toJson()).toList(),
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
      'variants': variants.map((v) => v.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sellerId == other.sellerId &&
          category == other.category &&
          name == other.name &&
          pricePerKg == other.pricePerKg &&
          minOrderKg == other.minOrderKg &&
          orderStep == other.orderStep &&
          availableKg == other.availableKg &&
          unitType == other.unitType &&
          description == other.description &&
          location == other.location &&
          isDomestic == other.isDomestic &&
          availableNow == other.availableNow &&
          deliveryScope == other.deliveryScope &&
          stats == other.stats &&
          createdAt == other.createdAt &&
          selectedVariant == other.selectedVariant &&
          _listEquals(variants, other.variants) &&
          _listEquals(imageUrls, other.imageUrls) &&
          _listEquals(pickupOptions, other.pickupOptions);

  @override
  int get hashCode => Object.hash(
        id,
        sellerId,
        category,
        name,
        pricePerKg,
        minOrderKg,
        orderStep,
        availableKg,
        unitType,
        isDomestic,
        availableNow,
        deliveryScope,
        stats,
        createdAt,
        selectedVariant,
        Object.hashAll(variants),
      );


  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'ProductModel(id: $id, name: $name, price: $priceFormatted, unit: $unitType, available: $availableNow)';
}
