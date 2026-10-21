import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/core/logger_service.dart';

/// Interfejs repozitorijuma za rad sa omiljenim prodavcima (praćenje prodavaca).
abstract interface class FavoriteSellersRepository {
  /// Vraća listu ID-jeva prodavaca koje korisnik prati.
  Future<List<String>> getFavoriteSellerIds(String userId);

  /// Proverava da li korisnik prati određenog prodavca.
  Future<bool> isFollowing(String userId, String sellerId);

  /// Započinje praćenje prodavca.
  Future<void> follow(String userId, String sellerId);

  /// Prekida praćenje prodavca.
  Future<void> unfollow(String userId, String sellerId);

  /// Vraća proizvode od praćenih prodavaca za datog korisnika.
  Future<List<ProductModel>> getProductsFromFavoriteSellers(String userId);

  /// Vraća broj pratilaca za zadatog prodavca.
  Future<int> getFollowersCount(String sellerId);

  /// Vraća listu modela korisnika (profila) za sve praćene prodavce.
  Future<List<UserModel>> getFavoriteSellersWithProfiles(String userId);
}

/// Supabase implementacija [FavoriteSellersRepository].
class SupabaseFavoriteSellersRepository implements FavoriteSellersRepository {
  final SupabaseClient? _customClient;

  SupabaseFavoriteSellersRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<String>> getFavoriteSellerIds(String userId) async {
    final list = await _client
        .from('favorite_sellers')
        .select('seller_id')
        .eq('user_id', userId);
    return (list as List).map((e) => e['seller_id'] as String).toList();
  }

  @override
  Future<bool> isFollowing(String userId, String sellerId) async {
    final res = await _client
        .from('favorite_sellers')
        .select('id')
        .eq('user_id', userId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    return res != null;
  }

  @override
  Future<void> follow(String userId, String sellerId) async {
    await _client.from('favorite_sellers').insert({
      'user_id': userId,
      'seller_id': sellerId,
    });
  }

  @override
  Future<void> unfollow(String userId, String sellerId) async {
    await _client
        .from('favorite_sellers')
        .delete()
        .eq('user_id', userId)
        .eq('seller_id', sellerId);
  }

  @override
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
      if (favIds.isEmpty) return const [];
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

  @override
  Future<int> getFollowersCount(String sellerId) async {
    final response = await _client
        .from('favorite_sellers')
        .select()
        .eq('seller_id', sellerId)
        .count(CountOption.exact);
    return response.count;
  }

  @override
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
      if (favIds.isEmpty) return const [];
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
