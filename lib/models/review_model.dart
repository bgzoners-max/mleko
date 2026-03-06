class ReviewModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? productId;
  final String? orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? sellerReply;
  final DateTime? sellerReplyAt;

  const ReviewModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.productId,
    this.orderId,
    required this.rating,
    this.comment = '',
    required this.createdAt,
    this.sellerReply,
    this.sellerReplyAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v == null) return fallback;
      if (v is String) return DateTime.tryParse(v) ?? fallback;
      if (v is DateTime) return v;
      return fallback;
    }

    final now = DateTime.now();
    final replyAtRaw = json['seller_reply_at'];
    DateTime? replyAt;
    if (replyAtRaw != null) {
      replyAt = replyAtRaw is String
          ? DateTime.tryParse(replyAtRaw)
          : replyAtRaw is DateTime
              ? replyAtRaw
              : null;
    }

    return ReviewModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      productId: json['product_id'] as String?,
      orderId: json['order_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: parseDate(json['created_at'], now),
      sellerReply: json['seller_reply'] as String?,
      sellerReplyAt: replyAt,
    );
  }

  /// Prodavac još nije odgovorio
  bool get hasNoReply => sellerReply == null || sellerReply!.isEmpty;

  /// Odgovor je kreiran pre manje od 24h — izmena je dozvoljena
  bool get isReplyEditable {
    if (hasNoReply) return true;
    if (sellerReplyAt == null) return false;
    return DateTime.now().difference(sellerReplyAt!) < const Duration(hours: 24);
  }
}
