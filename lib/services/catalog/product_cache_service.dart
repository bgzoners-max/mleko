import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product_model.dart';
import '../core/logger_service.dart';

/// Model za cachovan proizvod sa metapodacima
class CachedProductList {
  final List<ProductModel> products;
  final DateTime cachedAt;
  final DateTime expiresAt;

  CachedProductList({
    required this.products,
    required this.cachedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'products': products.map((p) => p.toJson()).toList(),
        'cached_at': cachedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

  factory CachedProductList.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.parse(json['expires_at'] as String);
    final rawProducts = json['products'] as List? ?? const [];
    final products = <ProductModel>[];
    for (final p in rawProducts) {
      try {
        final map = p as Map<String, dynamic>;
        if (map['id'] == null) continue;
        products.add(ProductModel.fromJson(map));
      } catch (e) {
        LoggerService.warning('Skipping corrupted product in cache',
            extra: {'error': e.toString()});
      }
    }
    return CachedProductList(
      products: products,
      cachedAt: DateTime.parse(json['cached_at'] as String),
      expiresAt: expiresAt,
    );
  }
}

/// Servis za cache proizvoda - omogućava offline pregled
class ProductCacheService {
  static const String _prefix = 'mleko_cache_';
  static const Duration _defaultTTL = Duration(hours: 24);
  static const int _maxMemoryCacheEntries = 200;
  static final Map<String, CachedProductList> _memoryCache = {};

  /// Broj trenutnih elemenata u memorijskom kešu (za testove i dijagnostiku)
  static int get memoryCacheSize => _memoryCache.length;

  /// Čisti isključivo in-memory keš
  static void clearMemoryCache() => _memoryCache.clear();

  /// Preuzima stavku iz memorijskog keša i pomera je na vrh (MRU).
  static CachedProductList? _getFromMemoryCache(String key) {
    final cached = _memoryCache.remove(key);
    if (cached == null) return null;
    if (cached.isExpired) return null;
    _memoryCache[key] = cached;
    return cached;
  }

  /// Upisuje stavku u memorijski keš i po potrebi izbacuje najstariju (LRU).
  static void _putIntoMemoryCache(String key, CachedProductList cached) {
    _memoryCache.remove(key);
    _memoryCache[key] = cached;
    if (_memoryCache.length > _maxMemoryCacheEntries) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
  }

  // Cache keys
  static const String homeProductsKey = '${_prefix}home';
  static String searchKey(String query) =>
      '${_prefix}search_${query.replaceAll(' ', '_')}';
  static String sellerKey(String sellerId) => '${_prefix}seller_$sellerId';
  static String categoryKey(String category) =>
      '${_prefix}category_${category.replaceAll(' ', '_')}';
  static String productKey(String productId) => '${_prefix}product_$productId';

  /// Sinhrono čitanje iz memorijskog keša (bez async čitanja iz storage-a)
  List<ProductModel>? getCachedProductsSync(String key) {
    final cached = _getFromMemoryCache(key);
    if (cached == null || cached.isExpired) return null;
    return cached.products;
  }

  /// Cache proizvode sa default TTL (24h)
  Future<void> cacheProducts(
    String key,
    List<ProductModel> products, {
    Duration ttl = _defaultTTL,
  }) async {
    final now = DateTime.now();
    final cachedList = CachedProductList(
      products: products,
      cachedAt: now,
      expiresAt: now.add(ttl),
    );
    _putIntoMemoryCache(key, cachedList);
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(cachedList);
      await prefs.setString(key, json);
      LoggerService.debug('Cached products', extra: {
        'key': key,
        'count': products.length,
        'expiresAt': cachedList.expiresAt.toString(),
      });
    } catch (e, st) {
      LoggerService.error('Failed to cache products', e, stackTrace: st);
    }
  }

  /// Učitaj cachovane proizvode
  Future<List<ProductModel>?> getCachedProducts(String key) async {
    final memCached = getCachedProductsSync(key);
    if (memCached != null) {
      return memCached;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(key);
      if (json == null) {
        LoggerService.debug('Cache miss', extra: {'key': key});
        return null;
      }

      final cached = CachedProductList.fromJson(jsonDecode(json));
      if (cached.isExpired) {
        LoggerService.debug('Cache expired', extra: {'key': key});
        await prefs.remove(key);
        _memoryCache.remove(key);
        return null;
      }

      _putIntoMemoryCache(key, cached);

      LoggerService.debug('Cache hit', extra: {
        'key': key,
        'count': cached.products.length,
        'age': DateTime.now().difference(cached.cachedAt).inMinutes,
      });
      return cached.products;
    } catch (e, st) {
      LoggerService.error('Failed to read cache', e, stackTrace: st);
      return null;
    }
  }

  /// Cache jedan proizvod
  Future<void> cacheProduct(ProductModel product,
      {Duration ttl = _defaultTTL}) async {
    await cacheProducts(productKey(product.id), [product], ttl: ttl);
  }

  /// Učitaj jedan cachovan proizvod
  Future<ProductModel?> getCachedProduct(String productId) async {
    final list = await getCachedProducts(productKey(productId));
    return list?.isNotEmpty == true ? list!.first : null;
  }

  /// Obriši sve cache (offline mode cleanup)
  Future<void> clearAll() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      LoggerService.debug('Cleared all product cache',
          extra: {'count': keys.length});
    } catch (e, st) {
      LoggerService.error('Failed to clear cache', e, stackTrace: st);
    }
  }

  /// Obriši određeni cache
  Future<void> clearKey(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      LoggerService.debug('Cleared cache', extra: {'key': key});
    } catch (e, st) {
      LoggerService.error('Failed to clear cache key', e, stackTrace: st);
    }
  }

  /// Učitaj i spoji sve važeće cachovane proizvode (deduplikovano po ID-u).
  Future<List<ProductModel>> getAllCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      final byId = <String, ProductModel>{};

      for (final key in keys) {
        final json = prefs.getString(key);
        if (json == null) continue;

        try {
          final cached = CachedProductList.fromJson(jsonDecode(json));
          if (cached.isExpired) {
            await prefs.remove(key);
            continue;
          }

          for (final product in cached.products) {
            byId[product.id] = product;
          }
        } catch (e, st) {
          LoggerService.warning(
            'Skipping invalid cache entry',
            extra: {'key': key, 'error': e.toString()},
          );
          LoggerService.debug('Invalid cache entry stack trace',
              extra: {'stackTrace': st.toString()});
        }
      }

      return byId.values.toList();
    } catch (e, st) {
      LoggerService.error('Failed to read all cached products', e,
          stackTrace: st);
      return [];
    }
  }

  /// Proverite koliko staro je cache-a
  Future<Duration?> getCacheAge(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(key);
      if (json == null) return null;
      final cached = CachedProductList.fromJson(jsonDecode(json));
      return DateTime.now().difference(cached.cachedAt);
    } catch (e) {
      return null;
    }
  }

  /// Список svih cache ključeva i njihove starosti
  Future<Map<String, Duration>> getAllCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = <String, Duration>{};
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        final age = await getCacheAge(key);
        if (age != null) stats[key] = age;
      }
      return stats;
    } catch (e) {
      return {};
    }
  }
}
