import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../core/logger_service.dart';

class FavoriteSellersService {
  static final FavoriteSellersService _instance = FavoriteSellersService._();
  factory FavoriteSellersService() => _instance;
  FavoriteSellersService._();

  final _client = Supabase.instance.client;

  Future<List<String>> getFavoriteSellerIds(String userId) async {
    final list = await _client
        .from('favorite_sellers')
        .select('seller_id')
        .eq('user_id', userId);
    return (list as List).map((e) => e['seller_id'] as String).toList();
  }

  Future<bool> isFollowing(String userId, String sellerId) async {
    final res = await _client
        .from('favorite_sellers')
        .select('id')
        .eq('user_id', userId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    return res != null;
  }

  Future<void> follow(String userId, String sellerId) async {
    await _client.from('favorite_sellers').insert({
      'user_id': userId,
      'seller_id': sellerId,
    });
  }

  Future<void> unfollow(String userId, String sellerId) async {
    await _client
        .from('favorite_sellers')
        .delete()
        .eq('user_id', userId)
        .eq('seller_id', sellerId);
  }

  Future<void> toggleFollow(String userId, String sellerId) async {
    final following = await isFollowing(userId, sellerId);
    if (following) {
      await unfollow(userId, sellerId);
    } else {
      await follow(userId, sellerId);
    }
  }

  Future<List<ProductModel>> getProductsFromFavoriteSellers(
      String userId) async {
    try {
      final res = await _client.rpc('get_products_from_favorite_sellers',
          params: {'p_user_id': userId});
      return (res as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.warning(
        'RPC get_products_from_favorite_sellers failed, using fallback',
        extra: {'userId': userId, 'error': e.toString()},
      );
      final favIds = await getFavoriteSellerIds(userId);
      if (favIds.isEmpty) return [];
      final list = await _client
          .from('products')
          .select()
          .inFilter('seller_id', favIds)
          .order('created_at', ascending: false);
      return (list as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<int> getFollowersCount(String sellerId) async {
    final response = await _client
        .from('favorite_sellers')
        .select()
        .eq('seller_id', sellerId)
        .count(CountOption.exact);
    return response.count;
  }

  Future<List<UserModel>> getFavoriteSellersWithProfiles(String userId) async {
    try {
      final res = await _client.rpc('get_favorite_sellers_with_profiles',
          params: {'p_user_id': userId});
      return (res as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      LoggerService.warning(
        'RPC get_favorite_sellers_with_profiles failed, using fallback query',
        extra: {'userId': userId, 'error': e.toString()},
      );
      final favIds = await getFavoriteSellerIds(userId);
      if (favIds.isEmpty) return [];
      final list = await _client
          .from('public_profiles')
          .select()
          .inFilter('id', favIds);
      return (list as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}
