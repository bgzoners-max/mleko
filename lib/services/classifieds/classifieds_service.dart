import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_error.dart';
import '../../models/classified_ad_model.dart';
import '../../models/classified_category_model.dart';
import '../../models/classified_seller_stats_model.dart';
import '../../utils/search_utils.dart';
import '../communication/push_service.dart';
import '../core/logger_service.dart';

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

  static const String _categoriesCacheKey = 'cached_classified_categories_payload_v5';
  static const int _categoriesCacheVersion = 5;
  static const Duration _categoriesCacheTtl = Duration(hours: 24);

  // Brojači neuspelih RPC poziva za telemetriju
  static int _failedViewsRpcCount = 0;
  static int _failedInteractionsRpcCount = 0;

  static int get failedViewsRpcCount => _failedViewsRpcCount;
  static int get failedInteractionsRpcCount => _failedInteractionsRpcCount;
  static int get totalRpcFailures => _failedViewsRpcCount + _failedInteractionsRpcCount;

  @visibleForTesting
  static void resetFailureCountsForTesting() {
    _failedViewsRpcCount = 0;
    _failedInteractionsRpcCount = 0;
  }

  @visibleForTesting
  static Future<void> clearCategoriesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_categoriesCacheKey);
    await prefs.remove('cached_classified_categories_raw_json');
  }

  @visibleForTesting
  static List<ClassifiedCategoryModel> buildCategoryTreeForTesting(List<dynamic> rawList) =>
      _buildCategoryTree(rawList);

  static List<ClassifiedCategoryModel> _buildCategoryTree(List<dynamic> rawList) {
    final all = rawList
        .map((e) => ClassifiedCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Ukloni zastarele duplikate ako postoje kanonski pandani
    const obsoleteIds = {
      'stocarstvo_zivotinje',
      'prodaja_kuca',
      'industrijski_placevi',
      'gume_felne',
      'auto_multimedija_navigacija',
      'stampaci_skeneri_toneri',
      'mrezna_oprema_ruteri',
      'memorije_hard_diskovi',
      'mali_kuhinjski_aparati',
      'aparati_za_kafu',
    };
    all.removeWhere((c) => obsoleteIds.contains(c.id));

    // Osiguraj postojanje 'zivinarstvo' i 'stocarska_oprema' pod 'poljoprivreda'
    if (!all.any((c) => c.id == 'zivinarstvo')) {
      all.add(const ClassifiedCategoryModel(
        id: 'zivinarstvo',
        name: 'Živinarstvo i peradarstvo',
        iconName: 'egg',
        parentId: 'poljoprivreda',
        sortOrder: 52,
        isConditionApplicable: false,
      ));
    }
    if (!all.any((c) => c.id == 'stocarska_oprema')) {
      all.add(const ClassifiedCategoryModel(
        id: 'stocarska_oprema',
        name: 'Stočarska oprema i muzilice',
        iconName: 'precision_manufacturing',
        parentId: 'poljoprivreda',
        sortOrder: 54,
        isConditionApplicable: true,
      ));
    }

    final roots = all.where((c) => c.isRoot).toList();
    final childrenByParent = <String, List<ClassifiedCategoryModel>>{};

    for (final c in all.where((c) => !c.isRoot)) {
      if (c.parentId != null) {
        childrenByParent.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Bezbednosna garancija: osiguraj da pod 'smartfoni' uvek postoji 'smartfoni_ostalo' (Ostale marke)
    final smartfoniChildren = childrenByParent['smartfoni'];
    if (smartfoniChildren != null &&
        !smartfoniChildren.any((c) => c.id == 'smartfoni_ostalo')) {
      smartfoniChildren.add(const ClassifiedCategoryModel(
        id: 'smartfoni_ostalo',
        name: 'Ostale marke',
        iconName: 'smartphone',
        parentId: 'smartfoni',
        sortOrder: 999,
      ));
    }

    ClassifiedCategoryModel buildSubtree(ClassifiedCategoryModel node) {
      final rawChildren = childrenByParent[node.id] ?? [];
      final nestedChildren = rawChildren.map((c) {
        // Kanon je server (isConditionApplicable iz baze/view-a).
        // Zaštita u stablu obezbeđuje konzistentnost u slučaju zastarelog keša
        // (ako je roditelj neprimenljiv, podkategorija takođe ne može imati stanje).
        final effectiveApplicable = node.isConditionApplicable && c.isConditionApplicable;
        final updatedChild = c.isConditionApplicable != effectiveApplicable
            ? c.copyWith(isConditionApplicable: effectiveApplicable)
            : c;
        return buildSubtree(updatedChild);
      }).toList()
        ..sort(ClassifiedCategoryModel.compareCategories);
      return node.copyWith(subcategories: nestedChildren);
    }

    final list = roots.map(buildSubtree).toList()
      ..sort(ClassifiedCategoryModel.compareCategories);
    return list;
  }

  /// Učitava sve kategorije i grupiše podkategorije u roditelje.
  /// Rezultat se kešira u SharedPreferences uz verziju i TTL (24h).
  /// Ako je [forceRefresh] false i keš je svež (< 24h), vraća keširane podatke bez mrežnog poziva.
  Future<List<ClassifiedCategoryModel>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await getCachedCategories(allowExpired: false);
      if (cached.isNotEmpty) {
        return cached;
      }
    }

    try {
      final res = await _client
          .from('classified_categories')
          .select()
          .order('sort_order', ascending: true);

      final rawList = res as List;
      try {
        final prefs = await SharedPreferences.getInstance();
        final payload = {
          'version': _categoriesCacheVersion,
          'fetched_at': DateTime.now().toIso8601String(),
          'data': rawList,
        };
        await prefs.setString(_categoriesCacheKey, jsonEncode(payload));
      } catch (cacheErr) {
        LoggerService.warning(
          '[ClassifiedsService] Categories cache write failed',
          extra: {'error': cacheErr.toString()},
        );
      }

      return _buildCategoryTree(rawList);
    } catch (e, st) {
      // Offline fallback: probaj keš čak i ako je istekao (allowExpired: true)
      final cached = await getCachedCategories(allowExpired: true);
      if (cached.isNotEmpty) {
        return cached;
      }
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Vraća kategorije iz lokalnog keša (SharedPreferences).
  /// [allowExpired] određuje da li se vraća keš stariji od 24h (npr. za offline start).
  Future<List<ClassifiedCategoryModel>> getCachedCategories({bool allowExpired = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_categoriesCacheKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          final version = decoded['version'] as int? ?? 1;
          if (version != _categoriesCacheVersion) {
            // Zastarela verzija keša
            return const [];
          }

          final fetchedAtStr = decoded['fetched_at'] as String?;
          if (fetchedAtStr != null && !allowExpired) {
            final fetchedAt = DateTime.tryParse(fetchedAtStr);
            if (fetchedAt != null &&
                DateTime.now().difference(fetchedAt) > _categoriesCacheTtl) {
              // Keš je istekao (> 24h)
              return const [];
            }
          }

          final rawData = decoded['data'] as List?;
          if (rawData != null) {
            return _buildCategoryTree(rawData);
          }
        } else if (decoded is List && allowExpired) {
          // Kompatibilnost sa starim keš formatom
          return _buildCategoryTree(decoded);
        }
      }
    } catch (e) {
      LoggerService.warning(
        '[ClassifiedsService] getCachedCategories error',
        extra: {'error': e.toString()},
      );
    }
    return const [];
  }

  /// Preuzima broj aktivnih oglasa po kategorijama preko RPC funkcije [get_category_ad_counts].
  /// Vraća mapu { category_id: count }.
  Future<Map<String, int>> getCategoryAdCounts() async {
    try {
      final res = await _client.rpc('get_category_ad_counts');
      if (res is List) {
        final map = <String, int>{};
        for (final row in res) {
          if (row is Map && row['category_id'] != null) {
            final catId = row['category_id'].toString();
            final count = (row['ad_count'] as num?)?.toInt() ?? 0;
            map[catId] = count;
          }
        }
        return map;
      }
    } catch (e) {
      LoggerService.warning(
        '[ClassifiedsService] getCategoryAdCounts error',
        extra: {'error': e.toString()},
      );
    }
    return const {};
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
    seller_type,
    views_count,
    attributes,
    is_featured,
    featured_until,
    is_urgent,
    reports_count,
    call_clicks_count,
    shares_count,
    created_at,
    updated_at
  ''';

  /// Preuzima listu aktivnih oglasa uz opciono filtriranje, sortiranje i paginaciju.
  /// Podržava keyset paginaciju preko [lastCreatedAt] za sortiranje po najnovijem (O(1)),
  /// uz [offset] fallback za ostale vrste sortiranja ili pretrage.
  /// Napomena: iz bezbednosnih razloga, ova metoda nikada ne preuzima brojeve telefona.
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    List<String>? cities,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    Map<String, dynamic>? attributeFilters,
    bool? onlyFeatured,
    bool? onlyUrgent,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
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

      if (cities != null && cities.isNotEmpty) {
        query = query.inFilter('city', cities);
      } else if (city != null && city.isNotEmpty) {
        query = query.ilike('city', city);
      }

      if (sellerType != null && sellerType.isNotEmpty) {
        query = query.eq('seller_type', sellerType);
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

      if (onlyFeatured == true) {
        query = query.eq('is_featured', true);
      }

      if (onlyUrgent == true) {
        query = query.eq('is_urgent', true);
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

      if (attributeFilters != null && attributeFilters.isNotEmpty) {
        for (final entry in attributeFilters.entries) {
          final val = entry.value;
          if (val == null) continue;
          final strVal = val.toString().trim();
          if (strVal.isEmpty) continue;

          if (entry.key.startsWith('min_')) {
            final actualKey = entry.key.substring(4);
            query = query.filter('attributes->$actualKey', 'gte', val);
          } else if (entry.key.startsWith('max_')) {
            final actualKey = entry.key.substring(4);
            query = query.filter('attributes->$actualKey', 'lte', val);
          } else {
            // JSON containment operator (JSONB @> {"key": value})
            query = query.contains('attributes', {entry.key: val});
          }
        }
      }

      // Keyset paginacija za sortiranje po najnovijem (eliminiše O(N) skeniranje)
      final isKeysetApplicable =
          sort == ClassifiedSort.newest && lastCreatedAt != null;
      if (isKeysetApplicable) {
        query = query.lt('created_at', lastCreatedAt.toIso8601String());
      }

      PostgrestTransformBuilder<PostgrestList> transformQuery;
      switch (sort) {
        case ClassifiedSort.newest:
          transformQuery = query
              .order('is_featured', ascending: false)
              .order('created_at', ascending: false);
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

      final res = isKeysetApplicable
          ? await transformQuery.limit(limit)
          : await transformQuery.range(offset, offset + limit - 1);

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
    } catch (e, st) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('prekoračen') ||
          msg.contains('p0001') ||
          msg.contains('limit')) {
        throw AppError(
          message: 'Phone reveal rate limit reached',
          userMessage:
              'Dostigli ste limit za pregled brojeva telefona. Pokušajte ponovo kasnije.',
          type: ErrorType.network,
          stackTrace: st,
        );
      }
      return null;
    }
  }

  /// Učitava detalje pojedinačnog oglasa.
  /// Zaštita od botova i automatskih scrapera (Click-to-Reveal):
  /// Ne preuzimamo automatski broj telefona pri učitavanju stranice za posetioce.
  /// Broj se automatski dohvata isključivo ako je ulogovani korisnik vlasnik oglasa
  /// (potrebno za formu izmene oglasa), dok posetioci broj otkrivaju na klik preko [getAdPhone].
  Future<ClassifiedAdModel?> getAd(String id) async {
    try {
      final res = await _client.from('classified_ads').select('''
        $_kAdColumns,
        profiles:user_id(display_name, farm_name, profile_image_url),
        classified_categories:category_id(name, is_condition_applicable)
      ''').eq('id', id).maybeSingle();

      if (res == null) return null;

      final currentUid = _client.auth.currentUser?.id;
      final ownerId = res['user_id'] as String?;
      String? phone;
      if (currentUid != null && currentUid == ownerId) {
        phone = await getAdPhone(id);
      }

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
      final data = ad.toUpdateMap();
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

  /// Proverava da je trenutni korisnik prijavljen i poseduje admin prava.
  /// Centralizuje bezbednosnu proveru koju dele sve admin-only akcije
  /// (npr. istaknutost i hitnost oglasa).
  Future<void> _assertAdmin() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw AppError(
        message: 'Unauthorized: no authenticated user',
        userMessage: 'Morate biti prijavljeni za ovu akciju.',
        type: ErrorType.unauthorized,
      );
    }

    final profile = await _client
        .from('profiles')
        .select('is_admin')
        .eq('id', currentUserId)
        .maybeSingle();

    final isAdmin = profile?['is_admin'] as bool? ?? false;
    if (!isAdmin) {
      throw AppError(
        message: 'Forbidden: admin privileges required',
        userMessage: 'Nemate dozvolu za ovu akciju.',
        type: ErrorType.forbidden,
      );
    }
  }

  /// Ažurira status istaknutosti oglasa (samo za admine)
  Future<void> updateAdFeatured(String adId, bool isFeatured, {DateTime? until}) async {
    try {
      await _assertAdmin();

      await _client.from('classified_ads').update({
        'is_featured': isFeatured,
        'featured_until': isFeatured ? until?.toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', adId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Ažurira status hitnosti oglasa (samo za admine)
  Future<void> updateAdUrgent(String adId, bool isUrgent) async {
    try {
      await _assertAdmin();

      await _client.from('classified_ads').update({
        'is_urgent': isUrgent,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', adId);
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

  // Dedup pregledanih oglasa u sesiji (FIFO/insertion-order, max 100 da spreči memory leak)
  static const int _maxViewedAdsInSession = 100;
  final Set<String> _viewedAdIdsInSession = <String>{};

  /// Povećava brojač pregleda oglasa uz zaštitu od višestrukog pozivanja u istoj sesiji i deduplikaciju
  Future<void> incrementViews(String id) async {
    if (_viewedAdIdsInSession.contains(id)) return;
    
    // FIFO eviction: ako je Set pun, ukloni najstarije dodat element
    if (_viewedAdIdsInSession.length >= _maxViewedAdsInSession) {
      _viewedAdIdsInSession.remove(_viewedAdIdsInSession.first);
    }
    
    _viewedAdIdsInSession.add(id);
    try {
      String? installationId;
      try {
        installationId = await PushService.getInstallationId();
      } catch (_) {
        // Fallback ako secure storage / prefs nisu dostupni (npr. u testovima ili webu)
      }

      final params = <String, dynamic>{'ad_id': id};
      if (installationId != null && installationId.isNotEmpty) {
        params['p_viewer_id'] = installationId;
      }

      await _client.rpc('increment_classified_ad_views', params: params);
    } catch (e, st) {
      _failedViewsRpcCount++;
      LoggerService.warning(
        '[ClassifiedsService] increment_classified_ad_views failed (total failures: $_failedViewsRpcCount)',
        extra: {
          'ad_id': id,
          'error': e.toString(),
          'failed_count': _failedViewsRpcCount,
          'stack': st.toString(),
        },
      );
    }
  }

  /// Beleži interakciju kupca sa oglasom (poziv ili deljenje).
  Future<void> recordInteraction(String adId, String type) async {
    try {
      await _client.rpc(
        'increment_classified_ad_interaction',
        params: {
          'ad_id': adId,
          'p_type': type,
        },
      );
    } catch (e, st) {
      _failedInteractionsRpcCount++;
      LoggerService.warning(
        '[ClassifiedsService] increment_classified_ad_interaction failed (total failures: $_failedInteractionsRpcCount)',
        extra: {
          'ad_id': adId,
          'type': type,
          'error': e.toString(),
          'failed_count': _failedInteractionsRpcCount,
          'stack': st.toString(),
        },
      );
    }
  }

  /// Preuzima agregiranu analitiku i statistiku oglasa za prodavca.
  Future<ClassifiedSellerStatsModel> getSellerStats(String sellerId) async {
    try {
      final res = await _client.rpc(
        'get_seller_classifieds_stats',
        params: {'p_seller_id': sellerId},
      );
      if (res is Map) {
        return ClassifiedSellerStatsModel.fromJson(Map<String, dynamic>.from(res));
      }
      return const ClassifiedSellerStatsModel();
    } catch (_) {
      return const ClassifiedSellerStatsModel();
    }
  }
}
