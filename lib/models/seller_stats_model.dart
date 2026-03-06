class SellerStatsModel {
  final int ordersCount;
  final double? avgRating;
  final int reviewCount;
  final double? avgResponseHours;

  const SellerStatsModel({
    required this.ordersCount,
    this.avgRating,
    required this.reviewCount,
    this.avgResponseHours,
  });

  factory SellerStatsModel.fromJson(Map<String, dynamic> json) {
    return SellerStatsModel(
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      avgResponseHours: (json['avg_response_hours'] as num?)?.toDouble(),
    );
  }

  /// "odgovara za 2h" / "odgovara za 1d" / null ako nema podataka
  String? get responseLabel {
    if (avgResponseHours == null) return null;
    final h = avgResponseHours!;
    if (h < 1) return 'odgovara za <1h';
    if (h < 24) return 'odgovara za ${h.round()}h';
    final days = (h / 24).round();
    return 'odgovara za ${days}d';
  }

  bool get hasAnyData =>
      ordersCount > 0 || avgRating != null || avgResponseHours != null;
}
