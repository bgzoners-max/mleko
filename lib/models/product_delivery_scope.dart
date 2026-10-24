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

/// Konfiguracija opsega lične dostave za proizvod.
///
/// Izdvojeno iz [ProductModel] radi modularnosti i čiste raspodele odgovornosti.
class ProductDeliveryScope {
  final ProductDeliveryMode mode;
  final List<String> selectedPointIds;

  const ProductDeliveryScope({
    this.mode = ProductDeliveryMode.none,
    this.selectedPointIds = const [],
  });

  static const ProductDeliveryScope none = ProductDeliveryScope();

  bool get supportsSellerDelivery => mode != ProductDeliveryMode.none;
  bool get usesSelectedPoints => mode == ProductDeliveryMode.selectedPoints;

  ProductDeliveryScope copyWith({
    ProductDeliveryMode? mode,
    List<String>? selectedPointIds,
  }) {
    return ProductDeliveryScope(
      mode: mode ?? this.mode,
      selectedPointIds: selectedPointIds ?? this.selectedPointIds,
    );
  }

  factory ProductDeliveryScope.fromJson(Map<String, dynamic> json) {
    return ProductDeliveryScope(
      mode: productDeliveryModeFromDb(json['delivery_mode'] as String?),
      selectedPointIds: (json['selected_delivery_point_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_mode': mode.dbValue,
      'selected_delivery_point_ids': selectedPointIds,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDeliveryScope &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          _listEquals(selectedPointIds, other.selectedPointIds);

  @override
  int get hashCode => Object.hash(mode, Object.hashAll(selectedPointIds));

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
