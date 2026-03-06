import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class FavoritesService {
  final _client = Supabase.instance.client;

  Future<List<String>> getFavoriteProductIds(String userId) async {
    final list = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', userId);
    return (list as List).map((e) => e['product_id'] as String).toList();
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final res = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();
    return res != null;
  }

  Future<void> addFavorite(String userId, String productId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFavorite(String userId, String productId) async {
    await _client.from('favorites').delete().eq('user_id', userId).eq('product_id', productId);
  }

  Future<void> toggleFavorite(String userId, String productId) async {
    final isFav = await isFavorite(userId, productId);
    if (isFav) {
      await removeFavorite(userId, productId);
    } else {
      await addFavorite(userId, productId);
    }
  }

  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    final favIds = await getFavoriteProductIds(userId);
    if (favIds.isEmpty) return [];
    final list = await _client.from('products').select().inFilter('id', favIds);
    return (list as List).map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<ProductModel>> streamFavoriteProducts(String userId, {Stream<void>? refreshTrigger}) async* {
    while (true) {
      final products = await getFavoriteProducts(userId);
      yield products;
      if (refreshTrigger != null) {
        await Future.any([
          Future.delayed(const Duration(seconds: 5)),
          refreshTrigger.first,
        ]);
      } else {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  }
}
