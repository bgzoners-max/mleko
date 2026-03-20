import 'review_model.dart';

/// Agregirani podaci potrebni za prikaz “rating badge” i prvih recenzija.
class ProductReviewsData {
  final double? averageRating;
  final List<ReviewModel> reviews;

  const ProductReviewsData({
    required this.averageRating,
    required this.reviews,
  });

  int get count => reviews.length;
}

