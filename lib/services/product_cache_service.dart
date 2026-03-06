import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import 'logger_service.dart';

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
    final now = DateTime.now();
    final expiresAt = DateTime.parse(json['expires_at'] as String);
    return CachedProductList(
      products: (json['products'] as List)
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      cachedAt: DateTime.parse(json['cached_at'] as String),
      expiresAt: expiresAt,
    );
  }
}

/// Servis za cache proizvoda - omogućava offline pregled
class ProductCacheService {
  static const String _prefix = 'mleko_cache_';
  static const Duration _defaultTTL = Duration(hours: 24);

  // Cache keys
  static const String homeProductsKey = '${_prefix}home';
  static String searchKey(String query) =>
      '${_prefix}search_${query.replaceAll(' ', '_')}';
  static String sellerKey(String sellerId) => '${_prefix}seller_$sellerId';
  static String categoryKey(String category) =>
      '${_prefix}category_${category.replaceAll(' ', '_')}';
  static String productKey(String productId) => '${_prefix}product_$productId';

  /// Cache proizvode sa default TTL (24h)
  Future<void> cacheProducts(
    String key,
    List<ProductModel> products, {
    Duration ttl = _defaultTTL,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final cachedList = CachedProductList(
        products: products,
        cachedAt: now,
        expiresAt: now.add(ttl),
      );
      final json = jsonEncode(cachedList);
      await prefs.setString(key, json);
      LoggerService.info('Cached products', extra: {
        'key': key,
        'count': products.length,
        'expiresAt': cachedList.expiresAt.toString(),
      });
    } catch (e, st) {
      LoggerService.error('Failed to cache products', error: e, stackTrace: st);
    }
  }

  /// Učitaj cachovanе proizvode
  Future<List<ProductModel>?> getCachedProducts(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(key);
      if (json == null) {
        LoggerService.warning('Cache miss', extra: {'key': key});
        return null;
      }

      final cached = CachedProductList.fromJson(jsonDecode(json));
      if (cached.isExpired) {
        LoggerService.warning('Cache expired', extra: {'key': key});
        await prefs.remove(key);
        return null;
      }

      LoggerService.info('Cache hit', extra: {
        'key': key,
        'count': cached.products.length,
        'age': DateTime.now().difference(cached.cachedAt).inMinutes,
      });
      return cached.products;
    } catch (e, st) {
      LoggerService.error('Failed to read cache', error: e, stackTrace: st);
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
      LoggerService.info('Cleared all product cache',
          extra: {'count': keys.length});
    } catch (e, st) {
      LoggerService.error('Failed to clear cache', error: e, stackTrace: st);
    }
  }

  /// Obriši određeni cache
  Future<void> clearKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      LoggerService.info('Cleared cache', extra: {'key': key});
    } catch (e, st) {
      LoggerService.error('Failed to clear cache key',
          error: e, stackTrace: st);
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
