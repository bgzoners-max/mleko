import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_error.dart';
import '../../models/classified_ad_model.dart';

/// Servis za praćenje / čuvanje malih oglasa (`public.classified_ad_favorites`).
class ClassifiedAdFavoritesService {
  ClassifiedAdFavoritesService({SupabaseClient? client})
      : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  static const String _kAdSelect = '''
    id, user_id, title, description, price, currency, price_type,
    category_id, condition, images, city, phone_public, status,
    seller_type, views_count, favorites_count, attributes,
    is_featured, featured_until, is_urgent, reports_count,
    call_clicks_count, shares_count, created_at, updated_at,
    profiles:user_id(display_name, farm_name, profile_image_url),
    classified_categories:category_id(name, is_condition_applicable)
  ''';

  Future<bool> isFavorite(String userId, String adId) async {
    try {
      final res = await _client
          .from('classified_ad_favorites')
          .select('ad_id')
          .eq('user_id', userId)
          .eq('ad_id', adId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getFavoriteAdIds(String userId) async {
    try {
      final res = await _client
          .from('classified_ad_favorites')
          .select('ad_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (res as List)
          .map((e) => (e as Map)['ad_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> addFavorite(String userId, String adId) async {
    try {
      await _client.from('classified_ad_favorites').upsert(
        {'user_id': userId, 'ad_id': adId},
        onConflict: 'user_id,ad_id',
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> removeFavorite(String userId, String adId) async {
    try {
      await _client
          .from('classified_ad_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('ad_id', adId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> toggleFavorite(String userId, String adId) async {
    final currentlyFav = await isFavorite(userId, adId);
    if (currentlyFav) {
      await removeFavorite(userId, adId);
      return false;
    } else {
      await addFavorite(userId, adId);
      return true;
    }
  }

  /// Vraća sve sačuvane male oglase korisnika (najnovije sačuvani prvi).
  Future<List<ClassifiedAdModel>> getFavoriteAds(String userId) async {
    try {
      final ids = await getFavoriteAdIds(userId);
      if (ids.isEmpty) return const [];

      final res = await _client
          .from('classified_ads')
          .select(_kAdSelect)
          .inFilter('id', ids);

      final byId = <String, ClassifiedAdModel>{};
      for (final row in (res as List)) {
        final ad = ClassifiedAdModel.fromJson(row as Map<String, dynamic>);
        byId[ad.id] = ad;
      }

      return ids
          .map((id) => byId[id])
          .whereType<ClassifiedAdModel>()
          .toList(growable: false);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
