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
  static final ClassifiedsService _instance = ClassifiedsService._();
  factory ClassifiedsService({SupabaseClient? client}) {
    if (client != null) return ClassifiedsService._(client: client);
    return _instance;
  }
  ClassifiedsService._({SupabaseClient? client}) : _customClient = client;
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
      nestedChildren.sort((a, b) => ClassifiedCategoryModel.compareSerbian(a.name, b.name));
      return node.copyWith(subcategories: nestedChildren);
    }

    final list = roots.map(buildSubtree).toList();
    list.sort((a, b) => ClassifiedCategoryModel.compareSerbian(a.name, b.name));
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

  /// Paginirani upit za oglase sa dinamičkim filterima
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
        *,
        profiles:user_id(display_name, farm_name, profile_image_url),
        classified_categories:category_id(name)
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

  /// Učitava detalje pojedinačnog oglasa
  Future<ClassifiedAdModel?> getAd(String id) async {
    try {
      final res = await _client.from('classified_ads').select('''
        *,
        profiles:user_id(display_name, farm_name, profile_image_url),
        classified_categories:category_id(name)
      ''').eq('id', id).maybeSingle();

      if (res == null) return null;
      return ClassifiedAdModel.fromJson(res);
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
            *,
            classified_categories:category_id(name)
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
      final res =
          await _client.from('classified_ads').insert(data).select().single();
      return ClassifiedAdModel.fromJson(res);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Ažurira postojeći oglas
  Future<void> updateAd(ClassifiedAdModel ad) async {
    try {
      final data = ad.toJson(includeId: false);
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

  /// Povećava brojač pregleda oglasa
  Future<void> incrementViews(String id) async {
    try {
      await _client.rpc('increment_classified_ad_views', params: {'ad_id': id});
    } catch (_) {
      // Tihi fallback ako RPC nije dostupan
    }
  }
}
