import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/buyer_review_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';
import '../../models/app_error.dart';

class ReviewsService {
  static final ReviewsService _instance = ReviewsService._();
  factory ReviewsService({SupabaseClient? client}) {
    if (client != null) return ReviewsService._(client: client);
    return _instance;
  }
  ReviewsService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

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
      // 1. Primarno koristi trigger-održavanu tabelu agregata bez povlačenja svih pojedinačnih redova
      final summary = await _client
          .from('product_review_summary')
          .select('avg_rating, review_count')
          .eq('product_id', productId)
          .maybeSingle();
      if (summary != null) {
        final count = (summary['review_count'] as num?)?.toInt() ?? 0;
        if (count == 0) return null;
        return (summary['avg_rating'] as num?)?.toDouble();
      }
      // 2. Fallback na RPC agregat
      final res = await _client.rpc(
        'get_product_stats',
        params: {'p_product_id': productId},
      );
      if (res != null && res is Map) {
        final count = (res['review_count'] as num?)?.toInt() ?? 0;
        if (count == 0) return null;
        return (res['avg_rating'] as num?)?.toDouble();
      }
      return null;
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
    final reviews = await getReviewsForBuyer(buyerId);
    return computeAverage(reviews.map((r) => r.rating));
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
      return (orderId: orderId, productId: productId, productName: productName);
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
    if (status != 'delivered' &&
        status != 'archived' &&
        status != 'arhivirano') {
      return false;
    }

    try {
      final existing = await _client
          .from('buyer_reviews')
          .select('id')
          .eq('seller_id', sellerId)
          .eq('order_id', orderId)
          .maybeSingle();
      return existing == null;
    } on PostgrestException catch (e, st) {
      // maybeSingle putanja: postgrest zamenjuje code HTTP statusom, pa
      // proveravamo i telo odgovora u kojem 42P01/PGRST205 ostaje vidljiv.
      if (e.code == '42P01' ||
          e.code == 'PGRST205' ||
          e.message.contains('42P01') ||
          e.message.contains('PGRST205')) {
        return false;
      }
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
