import 'review_model.dart';

/// Agregirani podaci potrebni za prikaz “rating badge” i prvih recenzija.
class ProductReviewsData {
  final double? averageRating;
  final List<ReviewModel> reviews;
  /// buyer_id → prikazno ime (za link na profil kupca)
  final Map<String, String> buyerDisplayNames;

  const ProductReviewsData({
    required this.averageRating,
    required this.reviews,
    this.buyerDisplayNames = const {},
  });

  int get count => reviews.length;
}

