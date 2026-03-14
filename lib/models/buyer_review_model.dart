class BuyerReviewModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String? orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const BuyerReviewModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    this.orderId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory BuyerReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v == null) return fallback;
      if (v is String) return DateTime.tryParse(v) ?? fallback;
      if (v is DateTime) return v;
      return fallback;
    }

    final now = DateTime.now();
    return BuyerReviewModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      buyerId: json['buyer_id'] as String,
      orderId: json['order_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: parseDate(json['created_at'], now),
    );
  }
}
