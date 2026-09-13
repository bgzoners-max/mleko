class ClassifiedSubscriptionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String? categoryName;
  final String? categoryIconName;
  final String? searchQuery;
  final double? maxPrice;
  final String currency;
  final DateTime createdAt;

  const ClassifiedSubscriptionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.categoryName,
    this.categoryIconName,
    this.searchQuery,
    this.maxPrice,
    this.currency = 'EUR',
    required this.createdAt,
  });

  factory ClassifiedSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final cat = json['classified_categories'] as Map<String, dynamic>?;

    return ClassifiedSubscriptionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName:
          (cat?['name'] as String?) ?? json['category_name'] as String?,
      categoryIconName: (cat?['icon_name'] as String?) ??
          json['category_icon_name'] as String?,
      searchQuery: json['search_query'] as String?,
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'user_id': userId,
      'category_id': categoryId,
      if (searchQuery != null && searchQuery!.trim().isNotEmpty)
        'search_query': searchQuery!.trim(),
      if (maxPrice != null && maxPrice! > 0) 'max_price': maxPrice,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get criteriaSummary {
    final parts = <String>[];
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      parts.add('Reč: „${searchQuery!.trim()}”');
    }
    if (maxPrice != null && maxPrice! > 0) {
      parts.add('Do ${maxPrice!.toStringAsFixed(0)} $currency');
    }
    if (parts.isEmpty) {
      return 'Svi novi oglasi u kategoriji';
    }
    return parts.join(' • ');
  }
}
