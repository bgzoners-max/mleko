import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../core/logger_service.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService({SupabaseClient? client}) {
    if (client != null) return FavoritesService._(client);
    return _instance;
  }
  FavoritesService._([SupabaseClient? client]) : _customClient = client;
  FavoritesService._internal() : _customClient = null;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  bool _isMissingFavoritesTableError(Object e) {
    return e is PostgrestException && e.code == 'PGRST205';
  }

  Future<List<String>> getFavoriteProductIds(String userId) async {
    try {
      final list = await _client
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);
      return (list as List).map((e) => e['product_id'] as String).toList();
    } catch (e, st) {
      if (_isMissingFavoritesTableError(e)) {
        LoggerService.warning(
          'Favorites table missing. Returning empty favorites list.',
          extra: {'error': e.toString()},
        );
        return [];
      }
      LoggerService.error('Failed to load favorite product IDs', e,
          stackTrace: st);
      rethrow;
    }
  }

  Future<bool> isFavorite(String userId, String productId) async {
    try {
      final res = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      return res != null;
    } catch (e, st) {
      if (_isMissingFavoritesTableError(e)) {
        return false;
      }
      LoggerService.error('Failed to check favorite status', e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> addFavorite(String userId, String productId) async {
    try {
      await _client.from('favorites').insert({
        'user_id': userId,
        'product_id': productId,
      });
    } catch (e, st) {
      if (_isMissingFavoritesTableError(e)) {
        LoggerService.warning('Favorites table missing. Skipping addFavorite.');
        return;
      }
      LoggerService.error('Failed to add favorite', e, stackTrace: st);
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String productId) async {
    try {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e, st) {
      if (_isMissingFavoritesTableError(e)) {
        LoggerService.warning(
            'Favorites table missing. Skipping removeFavorite.');
        return;
      }
      LoggerService.error('Failed to remove favorite', e, stackTrace: st);
      rethrow;
    }
  }


  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    final favIds = await getFavoriteProductIds(userId);
    if (favIds.isEmpty) return [];
    final list = await _client.from('products').select().inFilter('id', favIds);
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ProductModel>> streamFavoriteProducts(String userId,
      {Stream<void>? refreshTrigger}) async* {
    final controller = StreamController<void>();

    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!controller.isClosed) controller.add(null);
    });

    StreamSubscription? triggerSub;
    if (refreshTrigger != null) {
      triggerSub = refreshTrigger.listen((_) {
        if (!controller.isClosed) controller.add(null);
      });
    }

    try {
      yield await getFavoriteProducts(userId);

      await for (final _ in controller.stream) {
        yield await getFavoriteProducts(userId);
      }
    } finally {
      timer.cancel();
      await triggerSub?.cancel();
      await controller.close();
    }
  }
}
