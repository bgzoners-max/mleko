/// Statistika i društveni dokaz (Social Proof) za proizvod.
///
/// Izdvojeno iz [ProductModel] radi modularnosti i smanjenja pretrpanosti (fat model).
class ProductStats {
  final bool sellerIsVerified;
  final double? avgRating;
  final int reviewCount;
  final int orderCount;

  const ProductStats({
    this.sellerIsVerified = false,
    this.avgRating,
    this.reviewCount = 0,
    this.orderCount = 0,
  });

  static const ProductStats empty = ProductStats();

  ProductStats copyWith({
    bool? sellerIsVerified,
    double? avgRating,
    int? reviewCount,
    int? orderCount,
  }) {
    return ProductStats(
      sellerIsVerified: sellerIsVerified ?? this.sellerIsVerified,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      orderCount: orderCount ?? this.orderCount,
    );
  }

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      sellerIsVerified: json['seller_is_verified'] as bool? ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seller_is_verified': sellerIsVerified,
      if (avgRating != null) 'avg_rating': avgRating,
      'review_count': reviewCount,
      'order_count': orderCount,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductStats &&
          runtimeType == other.runtimeType &&
          sellerIsVerified == other.sellerIsVerified &&
          avgRating == other.avgRating &&
          reviewCount == other.reviewCount &&
          orderCount == other.orderCount;

  @override
  int get hashCode => Object.hash(
        sellerIsVerified,
        avgRating,
        reviewCount,
        orderCount,
      );
}
