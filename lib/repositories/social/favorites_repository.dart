import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../services/core/logger_service.dart';

/// Interfejs repozitorijuma za rad sa omiljenim proizvodima korisnika.
abstract interface class FavoritesRepository {
  /// Vraća listu ID-jeva omiljenih proizvoda za datog korisnika.
  Future<List<String>> getFavoriteProductIds(String userId);

  /// Proverava da li je proizvod u listi omiljenih za datog korisnika.
  Future<bool> isFavorite(String userId, String productId);

  /// Dodaje proizvod u omiljene.
  Future<void> addFavorite(String userId, String productId);

  /// Uklanja proizvod iz omiljenih.
  Future<void> removeFavorite(String userId, String productId);

  /// Vraća punu listu [ProductModel] objekata za sve omiljene proizvode korisnika.
  Future<List<ProductModel>> getFavoriteProducts(String userId);
}

/// Supabase implementacija [FavoritesRepository].
class SupabaseFavoritesRepository implements FavoritesRepository {
  final SupabaseClient? _customClient;

  SupabaseFavoritesRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  bool _isMissingFavoritesTableError(Object e) {
    if (e is! PostgrestException) return false;
    if (e.code == 'PGRST205') return true;
    return e.message.contains('PGRST205');
  }

  @override
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
        return const [];
      }
      LoggerService.error('Failed to load favorite product IDs', e,
          stackTrace: st);
      rethrow;
    }
  }

  @override
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

  @override
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

  @override
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

  @override
  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    final favIds = await getFavoriteProductIds(userId);
    if (favIds.isEmpty) return const [];
    final list =
        await _client.from('products').select().inFilter('id', favIds);
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
