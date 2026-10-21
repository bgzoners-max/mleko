import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../repositories/social/favorite_sellers_repository.dart';

class FavoriteSellersService {
  static final FavoriteSellersService _instance =
      FavoriteSellersService._internal();

  factory FavoriteSellersService({
    FavoriteSellersRepository? repository,
    SupabaseClient? client,
  }) {
    if (repository != null || client != null) {
      return FavoriteSellersService._(repository: repository, client: client);
    }
    return _instance;
  }

  FavoriteSellersService._({
    FavoriteSellersRepository? repository,
    SupabaseClient? client,
  }) : _repository =
            repository ?? SupabaseFavoriteSellersRepository(client: client);

  FavoriteSellersService._internal()
      : _repository = SupabaseFavoriteSellersRepository();

  final FavoriteSellersRepository _repository;

  Future<List<String>> getFavoriteSellerIds(String userId) async {
    return _repository.getFavoriteSellerIds(userId);
  }

  Future<bool> isFollowing(String userId, String sellerId) async {
    return _repository.isFollowing(userId, sellerId);
  }

  Future<void> follow(String userId, String sellerId) async {
    await _repository.follow(userId, sellerId);
  }

  Future<void> unfollow(String userId, String sellerId) async {
    await _repository.unfollow(userId, sellerId);
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
    return _repository.getProductsFromFavoriteSellers(userId);
  }

  Future<int> getFollowersCount(String sellerId) async {
    return _repository.getFollowersCount(sellerId);
  }

  Future<List<UserModel>> getFavoriteSellersWithProfiles(String userId) async {
    return _repository.getFavoriteSellersWithProfiles(userId);
  }
}

