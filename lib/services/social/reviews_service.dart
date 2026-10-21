import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/buyer_review_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../models/app_error.dart';
import '../../repositories/social/reviews_repository.dart';

class ReviewsService {
  static final ReviewsService _instance = ReviewsService._();

  factory ReviewsService({
    ReviewsRepository? repository,
    SupabaseClient? client,
  }) {
    if (repository != null || client != null) {
      return ReviewsService._(repository: repository, client: client);
    }
    return _instance;
  }

  ReviewsService._({
    ReviewsRepository? repository,
    SupabaseClient? client,
  }) : _repository = repository ?? SupabaseReviewsRepository(client: client);

  final ReviewsRepository _repository;

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    try {
      return await _repository.getReviewsForSeller(sellerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<ReviewModel>> getReviewsByBuyer(String buyerId) async {
    try {
      return await _repository.getReviewsByBuyer(buyerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<ReviewModel>> getReviewsForProduct(String productId) async {
    try {
      return await _repository.getReviewsForProduct(productId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<SellerStatsModel> getSellerStats(String sellerId) async {
    try {
      return await _repository.getSellerStats(sellerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Izračunava prosečnu ocenu iz liste ocena na strani klijenta.
  /// Prihvata bilo koji `Iterable<int>` — radi i za ReviewModel i za BuyerReviewModel.
  static double? computeAverage(Iterable<int> ratings) {
    var sum = 0;
    var count = 0;
    for (final rating in ratings) {
      sum += rating;
      count++;
    }
    return count == 0 ? null : sum / count;
  }

  Future<double?> getAverageRatingForSeller(String sellerId) async {
    final stats = await getSellerStats(sellerId);
    return stats.avgRating;
  }

  Future<double?> getAverageRatingForProduct(String productId) async {
    try {
      final summary = await _repository.getProductReviewSummary(productId);
      return summary?.avgRating;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<BuyerReviewModel>> getReviewsForBuyer(String buyerId) async {
    try {
      return await _repository.getReviewsForBuyer(buyerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<double?> getAverageRatingForBuyer(String buyerId) async {
    final reviews = await getReviewsForBuyer(buyerId);
    return computeAverage(reviews.map((r) => r.rating));
  }

  Future<bool> canReviewOrder(String buyerId, String orderId) async {
    try {
      return await _repository.canReviewOrder(buyerId, orderId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<({String orderId, String productId, String productName})?>
      getReviewableOrder(
    String buyerId,
    String sellerId,
  ) async {
    try {
      return await _repository.getReviewableOrder(buyerId, sellerId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> addReview({
    required String buyerId,
    required String sellerId,
    required String orderId,
    required int rating,
    String? productId,
    String comment = '',
  }) async {
    try {
      await _repository.insertReview(
        buyerId: buyerId,
        sellerId: sellerId,
        orderId: orderId,
        rating: rating,
        productId: productId,
        comment: comment,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> canSellerReviewBuyer(String sellerId, String orderId) async {
    try {
      return await _repository.canSellerReviewBuyer(sellerId, orderId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> addBuyerReview({
    required String sellerId,
    required String buyerId,
    required String orderId,
    required int rating,
    String comment = '',
  }) async {
    try {
      await _repository.insertBuyerReview(
        sellerId: sellerId,
        buyerId: buyerId,
        orderId: orderId,
        rating: rating,
        comment: comment,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> addSellerReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _repository.addSellerReply(reviewId: reviewId, reply: reply);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Kupac odgovara na recenziju prodavca (jedan odgovor; izmena do 24h).
  Future<void> addBuyerReply({
    required String buyerReviewId,
    required String reply,
  }) async {
    try {
      await _repository.addBuyerReply(
        buyerReviewId: buyerReviewId,
        reply: reply,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
