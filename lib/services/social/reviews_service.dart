import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/buyer_review_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../models/app_error.dart';

class ReviewsService {
  static final ReviewsService _instance = ReviewsService._();
  factory ReviewsService() => _instance;
  ReviewsService._();

  final _client = Supabase.instance.client;

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    try {
      final list = await _client
          .from('reviews')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      return (list as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<ReviewModel>> getReviewsByBuyer(String buyerId) async {
    try {
      final list = await _client
          .from('reviews')
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);
      return (list as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<ReviewModel>> getReviewsForProduct(String productId) async {
    try {
      final list = await _client
          .from('reviews')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      return (list as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<SellerStatsModel> getSellerStats(String sellerId) async {
    try {
      final result = await _client.rpc(
        'get_seller_stats',
        params: {'p_seller_id': sellerId},
      );
      if (result == null) {
        return const SellerStatsModel(ordersCount: 0, reviewCount: 0);
      }
      final json = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      return SellerStatsModel.fromJson(json);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<double?> getAverageRatingForSeller(String sellerId) async {
    try {
      final result = await _client
          .from('reviews')
          .select('rating.avg()')
          .eq('seller_id', sellerId)
          .single();
      return (result['avg'] as num?)?.toDouble();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<double?> getAverageRatingForProduct(String productId) async {
    try {
      final result = await _client
          .from('reviews')
          .select('rating.avg()')
          .eq('product_id', productId)
          .single();
      return (result['avg'] as num?)?.toDouble();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<BuyerReviewModel>> getReviewsForBuyer(String buyerId) async {
    try {
      final list = await _client
          .from('buyer_reviews')
          .select()
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);
      return (list as List)
          .map((e) => BuyerReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e, st) {
      if (e.code == '42P01') return const [];
      throw AppError.from(e, stackTrace: st);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<double?> getAverageRatingForBuyer(String buyerId) async {
    try {
      final result = await _client
          .from('buyer_reviews')
          .select('rating.avg()')
          .eq('buyer_id', buyerId)
          .single();
      return (result['avg'] as num?)?.toDouble();
    } on PostgrestException catch (e) {
      if (e.code == '42P01') return null;
      rethrow;
    }
  }

  Future<bool> canReviewOrder(String buyerId, String orderId) async {
    try {
      final res = await _client
          .from('reviews')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('order_id', orderId)
          .maybeSingle();
      return res == null;
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
      final result = await _client.rpc('get_reviewable_order', params: {
        'p_buyer_id': buyerId,
        'p_seller_id': sellerId,
      });
      if (result == null) return null;
      final json = result is Map<String, dynamic>
          ? result
          : Map<String, dynamic>.from(result as Map);
      final orderId = json['order_id'] as String?;
      final productId = json['product_id'] as String?;
      final productName = json['product_name'] as String?;
      if (orderId == null || productId == null || productName == null) {
        return null;
      }
      return (
        orderId: orderId,
        productId: productId,
        productName: productName
      );
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
      await _client.from('reviews').insert({
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'order_id': orderId,
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> canSellerReviewBuyer(String sellerId, String orderId) async {
    final order = await _client
        .from('orders')
        .select('id, status')
        .eq('id', orderId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (order == null) return false;
    final status = order['status'] as String?;
    if (status != 'delivered' && status != 'arhivirano') return false;

    try {
      final existing = await _client
          .from('buyer_reviews')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('order_id', orderId)
          .maybeSingle();
      return existing == null;
    } on PostgrestException catch (e, st) {
      if (e.code == '42P01') return false;
      throw AppError.from(e, stackTrace: st);
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
      await _client.from('buyer_reviews').insert({
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'order_id': orderId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> addSellerReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      await _client.rpc('add_seller_reply', params: {
        'p_review_id': reviewId,
        'p_reply': reply,
      });
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
      await _client.rpc('add_buyer_reply', params: {
        'p_review_id': buyerReviewId,
        'p_reply': reply,
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
