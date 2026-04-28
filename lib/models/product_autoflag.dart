class ProductListingAutoflag {
  final String productId;
  final String sellerId;
  final String name;
  final String category;
  final int sameCategoryDuplicates;
  final int crossCategoryDuplicates;
  final bool missingImage;
  final bool missingOrigin;
  final bool missingShelfLife;
  final bool missingPickup;
  final List<String> issues;
  final bool hasIssues;

  const ProductListingAutoflag({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.sameCategoryDuplicates,
    required this.crossCategoryDuplicates,
    required this.missingImage,
    required this.missingOrigin,
    required this.missingShelfLife,
    required this.missingPickup,
    required this.issues,
    required this.hasIssues,
  });

  factory ProductListingAutoflag.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List<dynamic>?;
    return ProductListingAutoflag(
      productId: (json['product_id'] ?? '').toString(),
      sellerId: (json['seller_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      sameCategoryDuplicates:
          (json['same_category_duplicates'] as num?)?.toInt() ?? 0,
      crossCategoryDuplicates:
          (json['cross_category_duplicates'] as num?)?.toInt() ?? 0,
      missingImage: json['missing_image'] as bool? ?? false,
      missingOrigin: json['missing_origin'] as bool? ?? false,
      missingShelfLife: json['missing_shelf_life'] as bool? ?? false,
      missingPickup: json['missing_pickup'] as bool? ?? false,
      issues: rawIssues?.map((e) => e.toString()).toList() ?? const [],
      hasIssues: json['has_issues'] as bool? ?? false,
    );
  }
}

class ProductListingAutoflagSummary {
  final int totalProducts;
  final int cleanProducts;
  final int problemProducts;
  final double problemRatePercent;

  const ProductListingAutoflagSummary({
    required this.totalProducts,
    required this.cleanProducts,
    required this.problemProducts,
    required this.problemRatePercent,
  });

  factory ProductListingAutoflagSummary.fromJson(Map<String, dynamic> json) {
    return ProductListingAutoflagSummary(
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      cleanProducts: (json['clean_products'] as num?)?.toInt() ?? 0,
      problemProducts: (json['problem_products'] as num?)?.toInt() ?? 0,
      problemRatePercent:
          (json['problem_rate_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}
