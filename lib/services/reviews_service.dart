import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import '../models/seller_stats_model.dart';

class ReviewsService {
  final _client = Supabase.instance.client;

  Future<List<ReviewModel>> getReviewsForSeller(String sellerId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (list as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Recenzije koje je kupac ostavio prodavcima (ocene kao kupac)
  Future<List<ReviewModel>> getReviewsByBuyer(String buyerId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);
    return (list as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReviewModel>> getReviewsForProduct(String productId) async {
    final list = await _client
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .order('created_at', ascending: false);
    return (list as List).map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Jedan DB round-trip: COUNT(delivered orders) + AVG(rating) + AVG(response time).
  /// Koristi PostgreSQL aggregate funkcije — nema iteracije na klijentu.
  Future<SellerStatsModel> getSellerStats(String sellerId) async {
    final result = await _client.rpc(
      'get_seller_stats',
      params: {'p_seller_id': sellerId},
    );
    if (result == null) return const SellerStatsModel(ordersCount: 0, reviewCount: 0);
    final json = result is Map<String, dynamic> ? result : Map<String, dynamic>.from(result as Map);
    return SellerStatsModel.fromJson(json);
  }

  Future<double?> getAverageRatingForSeller(String sellerId) async {
    final list = await _client
        .from('reviews')
        .select('rating')
        .eq('seller_id', sellerId);
    if ((list as List).isEmpty) return null;
    final sum = (list as List).fold<double>(0, (s, e) => s + ((e['rating'] as num?)?.toDouble() ?? 0));
    return sum / list.length;
  }

  Future<double?> getAverageRatingForProduct(String productId) async {
    final list = await _client
        .from('reviews')
        .select('rating')
        .eq('product_id', productId);
    if ((list as List).isEmpty) return null;
    final sum = (list as List).fold<double>(0, (s, e) => s + ((e['rating'] as num?)?.toDouble() ?? 0));
    return sum / list.length;
  }

  Future<bool> canReviewOrder(String buyerId, String orderId) async {
    final res = await _client
        .from('reviews')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('order_id', orderId)
        .maybeSingle();
    return res == null;
  }

  /// Vraća prvu isporučenu nerecenziranu porudžbinu za kupca i prodavca.
  /// Koristi get_reviewable_order RPC — jedan upit sa NOT EXISTS,
  /// umesto prethodnog N+1 loopa (canReviewOrder po svakoj porudžbini).
  Future<({String orderId, String productId, String productName})?> getReviewableOrder(
    String buyerId,
    String sellerId,
  ) async {
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
    if (orderId == null || productId == null || productName == null) return null;
    return (orderId: orderId, productId: productId, productName: productName);
  }

  Future<void> addReview({
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

  /// Prodavac odgovara na recenziju (ili menja odgovor unutar 24h).
  /// Baza baca exception ako nije vlasnik ili je prošlo 24h.
  Future<void> addSellerReply({
    required String reviewId,
    required String reply,
  }) async {
    await _client.rpc('add_seller_reply', params: {
      'p_review_id': reviewId,
      'p_reply': reply,
    });
  }
}
