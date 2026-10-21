import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/buyer_review_model.dart';
import '../../models/review_model.dart';
import '../../models/seller_stats_model.dart';

/// Interfejs repozitorijuma za rad sa recenzijama kupaca i prodavaca.
abstract interface class ReviewsRepository {
  Future<List<ReviewModel>> getReviewsForSeller(String sellerId);
  Future<List<ReviewModel>> getReviewsByBuyer(String buyerId);
  Future<List<ReviewModel>> getReviewsForProduct(String productId);
  Future<SellerStatsModel> getSellerStats(String sellerId);
  Future<({double? avgRating, int reviewCount})?> getProductReviewSummary(
      String productId);
  Future<List<BuyerReviewModel>> getReviewsForBuyer(String buyerId);
  Future<bool> canReviewOrder(String buyerId, String orderId);
  Future<({String orderId, String productId, String productName})?>
      getReviewableOrder(String buyerId, String sellerId);
  Future<void> insertReview({
    required String buyerId,
    required String sellerId,
    required String orderId,
    required int rating,
    String? productId,
    String comment,
  });
  Future<bool> canSellerReviewBuyer(String sellerId, String orderId);
  Future<void> insertBuyerReview({
    required String sellerId,
    required String buyerId,
    required String orderId,
    required int rating,
    String comment,
  });
  Future<void> addSellerReply({
    required String reviewId,
    required String reply,
  });
  Future<void> addBuyerReply({
    required String buyerReviewId,
    required String reply,
  });
}

/// Supabase implementacija [ReviewsRepository].
class SupabaseReviewsRepository implements ReviewsRepository {
  final SupabaseClient? _customClient;

  SupabaseReviewsRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReviewModel>> getReviewsByBuyer(String buyerId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ReviewModel>> getReviewsForProduct(String productId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SellerStatsModel> getSellerStats(String sellerId) async {
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
  }

  @override
  Future<({double? avgRating, int reviewCount})?> getProductReviewSummary(
      String productId) async {
    // 1. Primarno koristi trigger-održavanu tabelu agregata
    final summary = await _client
        .from('product_review_summary')
        .select('avg_rating, review_count')
        .eq('product_id', productId)
        .maybeSingle();
    if (summary != null) {
      final count = (summary['review_count'] as num?)?.toInt() ?? 0;
      if (count == 0) return (avgRating: null, reviewCount: 0);
      return (
        avgRating: (summary['avg_rating'] as num?)?.toDouble(),
        reviewCount: count
      );
    }
    // 2. Fallback na RPC agregat
    final res = await _client.rpc(
      'get_product_stats',
      params: {'p_product_id': productId},
    );
    if (res != null && res is Map) {
      final count = (res['review_count'] as num?)?.toInt() ?? 0;
      if (count == 0) return (avgRating: null, reviewCount: 0);
      return (
        avgRating: (res['avg_rating'] as num?)?.toDouble(),
        reviewCount: count
      );
    }
    return null;
  }

  @override
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
    } on PostgrestException catch (e) {
      if (e.code == '42P01') return const [];
      rethrow;
    }
  }

  @override
  Future<bool> canReviewOrder(String buyerId, String orderId) async {
    final res = await _client
        .from('reviews')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('order_id', orderId)
        .maybeSingle();
    return res == null;
  }

  @override
  Future<({String orderId, String productId, String productName})?>
      getReviewableOrder(String buyerId, String sellerId) async {
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
  }

  @override
  Future<void> insertReview({
    required String buyerId,
    required String sellerId,
    required String orderId,
    required int rating,
    String? productId,
    String comment = '',
  }) async {
    await _client.from('reviews').insert({
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'order_id': orderId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    });
  }

  @override
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
    } on PostgrestException catch (e) {
      if (e.code == '42P01' ||
          e.code == 'PGRST205' ||
          e.message.contains('42P01') ||
          e.message.contains('PGRST205')) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<void> insertBuyerReview({
    required String sellerId,
    required String buyerId,
    required String orderId,
    required int rating,
    String comment = '',
  }) async {
    await _client.from('buyer_reviews').insert({
      'seller_id': sellerId,
      'buyer_id': buyerId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment,
    });
  }

  @override
  Future<void> addSellerReply({
    required String reviewId,
    required String reply,
  }) async {
    await _client.rpc('add_seller_reply', params: {
      'p_review_id': reviewId,
      'p_reply': reply,
    });
  }

  @override
  Future<void> addBuyerReply({
    required String buyerReviewId,
    required String reply,
  }) async {
    await _client.rpc('add_buyer_reply', params: {
      'p_review_id': buyerReviewId,
      'p_reply': reply,
    });
  }
}
