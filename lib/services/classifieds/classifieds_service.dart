import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_error.dart';
import '../../models/classified_ad_model.dart';
import '../../models/classified_category_model.dart';
import '../../utils/search_utils.dart';

enum ClassifiedSort {
  newest,
  priceAsc,
  priceDesc,
  popular,
}

class ClassifiedsService {
  ClassifiedsService({SupabaseClient? client}) : _customClient = client;
  ClassifiedsService.test() : _customClient = null;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  static const String _categoriesCacheKey = 'cached_classified_categories_raw_json';

  static List<ClassifiedCategoryModel> _buildCategoryTree(List<dynamic> rawList) {
    final all = rawList
        .map((e) => ClassifiedCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final roots = all.where((c) => c.isRoot).toList();
    final childrenByParent = <String, List<ClassifiedCategoryModel>>{};

    for (final c in all.where((c) => !c.isRoot)) {
      if (c.parentId != null) {
        childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    ClassifiedCategoryModel buildSubtree(ClassifiedCategoryModel node) {
      final rawChildren = childrenByParent[node.id] ?? [];
      final nestedChildren = rawChildren.map(buildSubtree).toList();
      nestedChildren.sort(ClassifiedCategoryModel.compareCategories);
      return node.copyWith(subcategories: nestedChildren);
    }

    final list = roots.map(buildSubtree).toList();
    list.sort(ClassifiedCategoryModel.compareCategories);
    return list;
  }

  /// Učitava sve kategorije i grupiše podkategorije u roditelje.
  /// Rezultat se kešira u SharedPreferences za offline i instant start.
  Future<List<ClassifiedCategoryModel>> getCategories() async {
    try {
      final res = await _client
          .from('classified_categories')
          .select()
          .order('sort_order', ascending: true);

      final rawList = res as List;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_categoriesCacheKey, jsonEncode(rawList));
      } catch (cacheErr) {
        debugPrint('[ClassifiedsService] Categories cache write failed: $cacheErr');
      }

      return _buildCategoryTree(rawList);
    } catch (e, st) {
      final cached = await getCachedCategories();
      if (cached.isNotEmpty) {
        return cached;
      }
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Vraća kategorije iz lokalnog keša (SharedPreferences).
  Future<List<ClassifiedCategoryModel>> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_categoriesCacheKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List;
        return _buildCategoryTree(decoded);
      }
    } catch (e) {
      debugPrint('[ClassifiedsService] getCachedCategories error: $e');
    }
    return const [];
  }

  /// Kolone oglasa bez kolone 'phone' (zaštita privatnosti na nivou baze / API-ja).
  /// Telefon se ovlašćenim licima dobavlja kontrolisano preko RPC funkcije [getAdPhone].
  static const String _kAdColumns = '''
    id,
    user_id,
    title,
    description,
    price,
    currency,
    price_type,
    category_id,
    condition,
    images,
    city,
    phone_public,
    status,
    views_count,
    created_at,
    updated_at
  ''';

  /// Preuzima listu aktivnih oglasa uz opciono filtriranje i sortiranje.
  /// Napomena: iz bezbednosnih razloga, ova metoda nikada ne preuzima brojeve telefona.
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('classified_ads').select('''
        $_kAdColumns,
        profiles:user_id(display_name, farm_name, profile_image_url),
        classified_categories:category_id(name, is_condition_applicable)
      ''').eq('status', 'active');

      if (categoryIds != null && categoryIds.isNotEmpty) {
        query = query.inFilter('category_id', categoryIds);
      } else if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (city != null && city.isNotEmpty) {
        query = query.ilike('city', city);
      }

      if (condition != null && condition.isNotEmpty) {
        query = query.eq('condition', condition);
      }

      if (currency != null && currency.isNotEmpty) {
        query = query.eq('currency', currency);
      }

      if (minPrice != null && minPrice > 0) {
        query = query.gte('price', minPrice);
      }

      if (maxPrice != null && maxPrice > 0) {
        query = query.lte('price', maxPrice);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        // Sanitizacija uklanja karaktere koji mogu da probijaju
        // PostgREST `or` sintaksu i ILIKE wildcard-e (*, %, _).
        // Koristimo isti sanitizer kao i za proizvode (search_utils.dart).
        final q = sanitizeProductSearchInput(searchQuery);
        if (q != null && q.isNotEmpty) {
          query = query.or('title.ilike.%$q%,description.ilike.%$q%');
        }
      }

      PostgrestTransformBuilder<PostgrestList> transformQuery;
      switch (sort) {
        case ClassifiedSort.newest:
          transformQuery = query.order('created_at', ascending: false);
          break;
        case ClassifiedSort.priceAsc:
          transformQuery = query.order('price', ascending: true);
          break;
        case ClassifiedSort.priceDesc:
          transformQuery = query.order('price', ascending: false);
          break;
        case ClassifiedSort.popular:
          transformQuery = query.order('views_count', ascending: false);
          break;
      }

      final res = await transformQuery.range(offset, offset + limit - 1);
      return (res as List)
          .map((e) => ClassifiedAdModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Bezbedno dobavlja broj telefona za dati oglas preko SECURITY DEFINER funkcije.
  /// Vraća broj ako je oglas aktivan i `phone_public = true`, ili ako je trenutni korisnik vlasnik/admin.
  Future<String?> getAdPhone(String adId) async {
    try {
      final phoneRes = await _client.rpc(
        'get_classified_ad_phone',
        params: {'p_ad_id': adId},
      );
      return phoneRes as String?;
    } catch (_) {
      return null;
    }
  }

  /// Učitava detalje pojedinačnog oglasa (uključujući bezbedno preuzimanje telefona za ovlašćena lica)
  Future<ClassifiedAdModel?> getAd(String id) async {
    try {
      final res = await _client.from('classified_ads').select('''
        $_kAdColumns,
        profiles:user_id(display_name, farm_name, profile_image_url),
        classified_categories:category_id(name, is_condition_applicable)
      ''').eq('id', id).maybeSingle();

      if (res == null) return null;

      final phone = await getAdPhone(id);
      final adData = Map<String, dynamic>.from(res);
      adData['phone'] = phone;

      return ClassifiedAdModel.fromJson(adData);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Učitava sve oglase datog korisnika (aktivne, prodate, arhivirane)
  Future<List<ClassifiedAdModel>> getUserAds(String userId) async {
    try {
      final res = await _client
          .from('classified_ads')
          .select('''
            $_kAdColumns,
            classified_categories:category_id(name, is_condition_applicable)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((e) => ClassifiedAdModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Kreira novi oglas
  Future<ClassifiedAdModel> createAd(ClassifiedAdModel ad) async {
    try {
      final data = ad.toJson(includeId: false);
      final res = await _client
          .from('classified_ads')
          .insert(data)
          .select(_kAdColumns)
          .single();
      final createdData = Map<String, dynamic>.from(res);
      createdData['phone'] = ad.phone;
      return ClassifiedAdModel.fromJson(createdData);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Ažurira postojeći oglas
  Future<void> updateAd(ClassifiedAdModel ad) async {
    try {
      final data = ad.toJson(includeId: false, includeCreatedAt: false);
      data['updated_at'] = DateTime.now().toIso8601String();
      await _client.from('classified_ads').update(data).eq('id', ad.id);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Označava oglas kao prodat
  Future<void> markAsSold(String id) async {
    try {
      await _client.from('classified_ads').update({
        'status': 'sold',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Briše oglas
  Future<void> deleteAd(String id) async {
    try {
      await _client.from('classified_ads').delete().eq('id', id);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  final Set<String> _viewedAdIdsInSession = {};

  /// Povećava brojač pregleda oglasa uz zaštitu od višestrukog pozivanja u istoj sesiji
  Future<void> incrementViews(String id) async {
    if (_viewedAdIdsInSession.contains(id)) return;
    _viewedAdIdsInSession.add(id);
    try {
      await _client.rpc('increment_classified_ad_views', params: {'ad_id': id});
    } catch (_) {
      // Tihi fallback ako RPC nije dostupan
    }
  }
}
