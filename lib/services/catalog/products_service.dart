import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../core/logger_service.dart';
import 'product_cache_service.dart';

/// Način sortiranja proizvoda
enum ProductSort {
  dateDesc,
  dateAsc,
  priceAsc,
  priceDesc,
  location,
  ratingDesc,
}

extension ProductSortX on ProductSort {
  String get label {
    switch (this) {
      case ProductSort.dateDesc:
        return 'Najnovije';
      case ProductSort.dateAsc:
        return 'Najstarije';
      case ProductSort.priceAsc:
        return 'Cena: najniža';
      case ProductSort.priceDesc:
        return 'Cena: najviša';
      case ProductSort.location:
        return 'Lokacija';
      case ProductSort.ratingDesc:
        return 'Najbolje ocenjeni';
    }
  }
}

/// Veličina jedne stranice pri paginaciji
const int productsPageSize = 20;

/// Maksimalan broj reči u upitu (AND pretraga po nazivu).
const int _kMaxSearchTokens = 8;

/// Čisti tekstualni upit; vraća `null` ako nema smislenog sadržaja.
String? _sanitizeProductSearchInput(String? searchQuery) {
  if (searchQuery == null) return null;
  final trimmed = searchQuery.trim();
  if (trimmed.isEmpty) return null;
  final limited = trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
  final safe = limited
      .replaceAll(RegExp(r'[*%_]'), '')
      .replaceAll(
        RegExp(r'[^\p{L}\p{N}\s\-_.]+', unicode: true),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return safe.isEmpty ? null : safe;
}

/// Tokeni za pretragu — samo naziv proizvoda; sve reči moraju biti podstring naziva (AND).
List<String> _nameSearchTokens(String safe) {
  return safe
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .take(_kMaxSearchTokens)
      .map((t) => t.toLowerCase())
      .toList();
}

class ProductListingAutoflag {
  final String productId;
  final String sellerId;
  final String name;
  final String category;
  final int sameCategoryDuplicates;
  final int crossCategoryDuplicates;
  final bool missingImage;
  final bool missingOrigin;
  final bool missingShelfLife;
  final bool missingPickup;
  final List<String> issues;
  final bool hasIssues;

  const ProductListingAutoflag({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.sameCategoryDuplicates,
    required this.crossCategoryDuplicates,
    required this.missingImage,
    required this.missingOrigin,
    required this.missingShelfLife,
    required this.missingPickup,
    required this.issues,
    required this.hasIssues,
  });

  factory ProductListingAutoflag.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'] as List<dynamic>?;
    return ProductListingAutoflag(
      productId: (json['product_id'] ?? '').toString(),
      sellerId: (json['seller_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      sameCategoryDuplicates:
          (json['same_category_duplicates'] as num?)?.toInt() ?? 0,
      crossCategoryDuplicates:
          (json['cross_category_duplicates'] as num?)?.toInt() ?? 0,
      missingImage: json['missing_image'] as bool? ?? false,
      missingOrigin: json['missing_origin'] as bool? ?? false,
      missingShelfLife: json['missing_shelf_life'] as bool? ?? false,
      missingPickup: json['missing_pickup'] as bool? ?? false,
      issues: rawIssues?.map((e) => e.toString()).toList() ?? const [],
      hasIssues: json['has_issues'] as bool? ?? false,
    );
  }
}

class ProductListingAutoflagSummary {
  final int totalProducts;
  final int cleanProducts;
  final int problemProducts;
  final double problemRatePercent;

  const ProductListingAutoflagSummary({
    required this.totalProducts,
    required this.cleanProducts,
    required this.problemProducts,
    required this.problemRatePercent,
  });

  factory ProductListingAutoflagSummary.fromJson(Map<String, dynamic> json) {
    return ProductListingAutoflagSummary(
      totalProducts: (json['total_products'] as num?)?.toInt() ?? 0,
      cleanProducts: (json['clean_products'] as num?)?.toInt() ?? 0,
      problemProducts: (json['problem_products'] as num?)?.toInt() ?? 0,
      problemRatePercent:
          (json['problem_rate_percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Pokreće [op] do [maxAttempts] puta. Pravi pauzu prije svakog ponovnog pokušaja.
/// Ne ponavlja ukoliko je izuzetak [AuthException] ili [StorageException].
Future<T> _withRetry<T>(
  Future<T> Function() op, {
  int maxAttempts = 3,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await op();
    } catch (e) {
      final isAuth = e is AuthException;
      if (isAuth || attempt >= maxAttempts) rethrow;
      await Future.delayed(Duration(milliseconds: 300 * attempt));
    }
  }
}

class ProductsService {
  final _client = Supabase.instance.client;

  int _compareProducts(ProductModel a, ProductModel b, ProductSort sort) {
    switch (sort) {
      case ProductSort.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case ProductSort.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case ProductSort.priceAsc:
        return a.pricePerKg.compareTo(b.pricePerKg);
      case ProductSort.priceDesc:
        return b.pricePerKg.compareTo(a.pricePerKg);
      case ProductSort.location:
        return a.location.toLowerCase().compareTo(b.location.toLowerCase());
      case ProductSort.ratingDesc:
        // Lokalno nemamo rating podatke za sve proizvode, fallback na novije.
        return b.createdAt.compareTo(a.createdAt);
    }
  }

  /// Paginirani učitavanje proizvoda – za "load more" / beskonačan scroll
  /// Uvek koristi view products_with_ratings (ima avg_rating, order_count) – jedan poziv, bez getProductSalesCounts.
  /// searchQuery – server-side pretraga samo po **nazivu** proizvoda (`name`).
  /// Više reči = AND (svaka reč mora da se pojavi u nazivu). Kategorija iz filtera
  /// i dalje koristi `eq('category', …)` — tekstualni upit ne traži po polju kategorije
  /// (izbegava lažne pogotke tipa „Jogurt“ za „mleko“ jer je kategorija „Jogurt i kiselo mleko“).
  Future<
      ({
        List<ProductModel> items,
        bool hasMore,
        Map<String, int> salesCounts,
        Map<String, ({double avg, int count})> ratings
      })> getProductsPage({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    String? searchQuery,
    ProductSort sort = ProductSort.dateDesc,
    int limit = productsPageSize,
    int offset = 0,
  }) async {
    const table = 'products_with_ratings';
    var query = _client.from(table).select();
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (region != null && region.isNotEmpty) {
      query = query.eq('location', region);
    }
    if (availableNow == true) {
      query = query.eq('available_now', true);
    }
    if (minPrice != null) {
      query = query.gte('price_per_kg', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price_per_kg', maxPrice);
    }
    final safeSearch = _sanitizeProductSearchInput(searchQuery);
    if (safeSearch != null) {
      final tokens = _nameSearchTokens(safeSearch);
      // Svaki token mora da se poklopi sa nazivom (AND) — preciznije od OR name/category.
      for (final token in tokens) {
        query = query.ilike('name', '%$token%');
      }
    }

    final (orderColumn, orderAsc) = switch (sort) {
      ProductSort.dateDesc => ('created_at', false),
      ProductSort.dateAsc => ('created_at', true),
      ProductSort.priceAsc => ('price_per_kg', true),
      ProductSort.priceDesc => ('price_per_kg', false),
      ProductSort.location => ('location', true),
      ProductSort.ratingDesc => ('avg_rating', false),
    };
    var ordered = query.order(orderColumn, ascending: orderAsc);
    if (sort == ProductSort.ratingDesc) {
      ordered = ordered.order('created_at', ascending: false);
    }
    final list = await _withRetry(() => ordered.range(offset, offset + limit - 1));
    final rows = list as List;
    final products = rows
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final salesCounts = <String, int>{};
    final ratings = <String, ({double avg, int count})>{};
    for (final row in rows) {
      final id = (row as Map)['id']?.toString();
      if (id != null) {
        salesCounts[id] = ((row['order_count'] as num?)?.toInt()) ?? 0;
        final avgRating = (row['avg_rating'] as num?)?.toDouble();
        final reviewCount = (row['review_count'] as num?)?.toInt() ?? 0;
        if (avgRating != null && reviewCount > 0) {
          ratings[id] = (avg: avgRating, count: reviewCount);
        }
      }
    }
    return (
      items: products,
      hasMore: products.length >= limit,
      salesCounts: salesCounts,
      ratings: ratings
    );
  }

  /// Lokalna pretraga kroz cache za offline scenario.
  Future<
      ({
        List<ProductModel> items,
        bool hasMore,
        Map<String, int> salesCounts
      })> searchCachedProductsPage({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    String? searchQuery,
    ProductSort sort = ProductSort.dateDesc,
    int limit = productsPageSize,
    int offset = 0,
  }) async {
    final cache = ProductCacheService();
    final safeSearch = _sanitizeProductSearchInput(searchQuery);
    final tokens =
        safeSearch != null ? _nameSearchTokens(safeSearch) : <String>[];

    final allCached = await cache.getAllCachedProducts();
    var filtered = allCached.where((p) {
      if (category != null && category.isNotEmpty && p.category != category) {
        return false;
      }
      if (region != null && region.isNotEmpty && p.location != region) {
        return false;
      }
      if (availableNow == true && !p.availableNow) {
        return false;
      }
      if (minPrice != null && p.pricePerKg < minPrice) {
        return false;
      }
      if (maxPrice != null && p.pricePerKg > maxPrice) {
        return false;
      }
      if (tokens.isEmpty) {
        return true;
      }

      final name = p.name.toLowerCase();
      return tokens.every((t) => name.contains(t));
    }).toList();

    filtered.sort((a, b) => _compareProducts(a, b, sort));

    if (offset >= filtered.length) {
      return (
        items: <ProductModel>[],
        hasMore: false,
        salesCounts: <String, int>{},
      );
    }

    final end =
        (offset + limit) > filtered.length ? filtered.length : (offset + limit);
    final page = filtered.sublist(offset, end);

    LoggerService.info('Local cache search completed', extra: {
      'query': safeSearch ?? '',
      'tokens': tokens,
      'total': filtered.length,
      'returned': page.length,
      'offset': offset,
      'limit': limit,
    });

    return (
      items: page,
      hasMore: end < filtered.length,
      salesCounts: <String, int>{},
    );
  }

  Future<List<ProductModel>> _fetchProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    ProductSort sort = ProductSort.dateDesc,
  }) async {
    const table = 'products_with_ratings';
    var query = _client.from(table).select();
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (region != null && region.isNotEmpty) {
      query = query.eq('location', region);
    }
    if (availableNow == true) {
      query = query.eq('available_now', true);
    }
    if (minPrice != null) {
      query = query.gte('price_per_kg', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price_per_kg', maxPrice);
    }

    final (orderColumn, orderAsc) = switch (sort) {
      ProductSort.dateDesc => ('created_at', false),
      ProductSort.dateAsc => ('created_at', true),
      ProductSort.priceAsc => ('price_per_kg', true),
      ProductSort.priceDesc => ('price_per_kg', false),
      ProductSort.location => ('location', true),
      ProductSort.ratingDesc => ('avg_rating', false),
    };
    var ordered = query.order(orderColumn, ascending: orderAsc);
    if (sort == ProductSort.ratingDesc) {
      ordered = ordered.order('created_at', ascending: false);
    }
    final list = await ordered;
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Stream proizvoda – Realtime umesto polling-a. Osvežava se odmah pri promeni u bazi.
  Stream<List<ProductModel>> getProducts({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    ProductSort sort = ProductSort.dateDesc,
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<List<ProductModel>>.broadcast();
    final cache = ProductCacheService();
    StreamSubscription? refreshSub;

    // Create cache key based on filter parameters
    final cacheKey = 'mleko_cache_products_'
        '${category ?? 'all'}_'
        '${minPrice ?? 'no'}_${maxPrice ?? 'no'}_'
        '${region ?? 'all'}_'
        '${availableNow ?? 'all'}_'
        '${sort.name}';

    Future<void> refetch() async {
      try {
        final list = await _fetchProducts(
          category: category,
          minPrice: minPrice,
          maxPrice: maxPrice,
          region: region,
          availableNow: availableNow,
          sort: sort,
        );

        // Cache filtered products
        await cache.cacheProducts(cacheKey, list);

        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (e, st) {
        LoggerService.error('Failed to refetch products', e, stackTrace: st);

        // Fallback na cache
        final cachedList = await cache.getCachedProducts(cacheKey);
        if (cachedList != null && cachedList.isNotEmpty) {
          LoggerService.info('Using cached filtered products as fallback');
          if (!controller.isClosed) {
            controller.add(cachedList);
          }
        }
      }
    }

    // Prvo emituj cache, zatim refetch
    cache.getCachedProducts(cacheKey).then((cachedList) {
      if (cachedList != null && cachedList.isNotEmpty) {
        if (!controller.isClosed) {
          controller.add(cachedList);
        }
      }
      refetch();
    }).catchError((e) {
      refetch();
    });

    final channel = _client.channel('products-list');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Home ekran – jedan RPC (products + order_count + rating), limit 50, Realtime osvežavanje.
  /// Ako je [regionNotifier] prosleđen, region se čita pri svakom refetch (i pri promeni notifiera).
  Stream<
      ({
        List<ProductModel> products,
        Map<String, int> salesCounts,
        Map<String, ({double avg, int count})> ratings
      })> getHomeProducts({
    String? region,
    ValueNotifier<String?>? regionNotifier,
    String? category,
    int limit = 50,
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<
        ({
          List<ProductModel> products,
          Map<String, int> salesCounts,
          Map<String, ({double avg, int count})> ratings
        })>.broadcast();
    final cache = ProductCacheService();
    StreamSubscription? refreshSub;
    VoidCallback? regionListener;
    var isFetching = false;
    var hasQueuedRefetch = false;

    Future<void> runSingleFetch() async {
      final currentRegion = regionNotifier?.value ?? region;
      try {
        final res = await _client.rpc(
          'get_home_products',
          params: {
            'p_limit': limit,
            'p_region': currentRegion,
            'p_category': category,
          },
        );
        final list = res as List;
        final products = list
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final salesCounts = <String, int>{};
        final ratings = <String, ({double avg, int count})>{};
        for (final row in list) {
          final id = (row as Map)['id']?.toString();
          if (id != null) {
            salesCounts[id] = ((row['order_count'] as num?)?.toInt()) ?? 0;
            final avgRating = (row['avg_rating'] as num?)?.toDouble();
            final reviewCount = (row['review_count'] as num?)?.toInt() ?? 0;
            if (avgRating != null && reviewCount > 0) {
              ratings[id] = (avg: avgRating, count: reviewCount);
            }
          }
        }

        // Cache novo učitane proizvode
        await cache.cacheProducts(
            ProductCacheService.homeProductsKey, products);

        if (!controller.isClosed) {
          controller.add(
              (products: products, salesCounts: salesCounts, ratings: ratings));
        }
      } catch (e, st) {
        LoggerService.error('Failed to load home products', e, stackTrace: st);

        // Fallback na cache kada je offline
        final cachedProducts =
            await cache.getCachedProducts(ProductCacheService.homeProductsKey);
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          LoggerService.info('Using cached home products as fallback');
          if (!controller.isClosed) {
            controller
                .add((products: cachedProducts, salesCounts: {}, ratings: {}));
          }
        } else if (!controller.isClosed) {
          controller.add((products: [], salesCounts: {}, ratings: {}));
        }
      }
    }

    // Coalesce burst triggers (realtime + refresh + region) into minimal network calls.
    Future<void> refetch() async {
      if (isFetching) {
        hasQueuedRefetch = true;
        return;
      }
      isFetching = true;
      try {
        do {
          hasQueuedRefetch = false;
          await runSingleFetch();
        } while (hasQueuedRefetch);
      } finally {
        isFetching = false;
      }
    }

    // Prvo pokušaj emitovati cached proizvode (brz UX)
    cache
        .getCachedProducts(ProductCacheService.homeProductsKey)
        .then((cachedProducts) {
      if (controller.isClosed) return;
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        controller
            .add((products: cachedProducts, salesCounts: {}, ratings: {}));
      }
      // Zatim fetch sa servera
      refetch();
    }).catchError((e) {
      if (controller.isClosed) return;
      // Ako cache read fail, direktno fetch
      refetch();
    });

    final channel = _client.channel('home-products');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    if (regionNotifier != null) {
      regionListener = () => refetch();
      regionNotifier.addListener(regionListener);
    }

    controller.onCancel = () {
      refreshSub?.cancel();
      if (regionNotifier != null && regionListener != null) {
        regionNotifier.removeListener(regionListener);
      }
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  /// Prodavci koji imaju proizvode u datom regionu (za sekciju „Prodavci u tvom okruženju”).
  Future<List<UserModel>> getSellersInRegion(String region) async {
    if (region.isEmpty) return [];
    try {
      final productRows = await _client
          .from('products')
          .select('seller_id')
          .eq('location', region);
      final sellerIds = (productRows as List)
          .map((e) => (e as Map)['seller_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      if (sellerIds.isEmpty) return [];
      final profiles = await _client
          .from('profiles')
          .select()
          .inFilter('id', sellerIds)
          .eq('role', 'seller');
      return (profiles as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      LoggerService.error('getSellersInRegion failed', e, stackTrace: st);
      return [];
    }
  }

  /// Prosečna ocena i broj recenzija po proizvodu (za sortiranje)
  Future<Map<String, ({double avg, int count})>> getProductRatings() async {
    try {
      final res = await _client.rpc('get_product_ratings');
      final map = <String, ({double avg, int count})>{};
      for (final row in res as List) {
        final id = row['product_id']?.toString();
        if (id != null) {
          map[id] = (
            avg: (row['avg_rating'] as num?)?.toDouble() ?? 0,
            count: (row['review_count'] as num?)?.toInt() ?? 0,
          );
        }
      }
      return map;
    } catch (e, st) {
      LoggerService.error('Failed to get product ratings', e, stackTrace: st);
      return {};
    }
  }

  Future<ProductListingAutoflagSummary>
      getMyProductListingAutoflagSummary() async {
    final res = await _client.rpc('get_my_product_listing_autoflag_summary');
    final row = (res as List).cast<Map<String, dynamic>>();
    if (row.isEmpty) {
      return const ProductListingAutoflagSummary(
        totalProducts: 0,
        cleanProducts: 0,
        problemProducts: 0,
        problemRatePercent: 0,
      );
    }
    return ProductListingAutoflagSummary.fromJson(row.first);
  }

  Future<List<ProductListingAutoflag>> getMyProductListingAutoflags() async {
    final res = await _client.rpc('get_my_product_listing_autoflags');
    return (res as List)
        .map((e) => ProductListingAutoflag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Stream proizvoda prodavca – Realtime umesto polling-a
  Stream<List<ProductModel>> getProductsBySeller(String sellerId,
      {Stream<void>? refreshTrigger}) {
    final controller = StreamController<List<ProductModel>>.broadcast();
    final cache = ProductCacheService();
    StreamSubscription? refreshSub;

    Future<void> refetch() async {
      try {
        final list = await _client
            .from('products')
            .select()
            .eq('seller_id', sellerId)
            .order('created_at', ascending: false);
        final products = (list as List)
            .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
            .toList();

        // Cache nove proizvode
        await cache.cacheProducts(
            ProductCacheService.sellerKey(sellerId), products);

        if (!controller.isClosed) {
          controller.add(products);
        }
      } catch (e, st) {
        LoggerService.error('Failed to refetch seller products', e,
            stackTrace: st, extra: {'sellerId': sellerId});

        // Fallback na cache
        final cachedProducts = await cache
            .getCachedProducts(ProductCacheService.sellerKey(sellerId));
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          LoggerService.info('Using cached seller products as fallback');
          if (!controller.isClosed) {
            controller.add(cachedProducts);
          }
        }
      }
    }

    // Prvo emituj cache, zatim refetch
    cache
        .getCachedProducts(ProductCacheService.sellerKey(sellerId))
        .then((cachedProducts) {
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        if (!controller.isClosed) {
          controller.add(cachedProducts);
        }
      }
      refetch();
    }).catchError((e) {
      refetch();
    });

    final channel = _client.channel('products-seller-$sellerId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: sellerId,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<List<ProductModel>> getProductsBySellerSnapshot(
      String sellerId) async {
    final list = await _client
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductModel?> getProduct(String id) async {
    final cache = ProductCacheService();
    try {
      final res =
          await _client.from('products').select().eq('id', id).maybeSingle();
      if (res == null) {
        return null;
      }
      final product = ProductModel.fromJson(res);
      // Cache product
      await cache.cacheProduct(product);
      return product;
    } catch (e, st) {
      LoggerService.error('Failed to load product', e,
          stackTrace: st, extra: {'productId': id});
      // Fallback na cache
      final cachedProduct = await cache.getCachedProduct(id);
      if (cachedProduct != null) {
        LoggerService.info('Using cached product as fallback');
        return cachedProduct;
      }
      return null;
    }
  }

  /// Batch učitavanje više proizvoda odjednom – zamenjuje N+1 petlje.
  /// Vraća mapu ID → ProductModel; nedostajući IDs nisu uključeni.
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};

    final cache = ProductCacheService();
    final result = <String, ProductModel>{};
    final missingIds = <String>[];

    // Prvo pokušaj iz cache-a
    for (final id in ids) {
      final cached = await cache.getCachedProduct(id);
      if (cached != null) {
        result[id] = cached;
      } else {
        missingIds.add(id);
      }
    }

    // Batch fetch missing iz DB
    if (missingIds.isNotEmpty) {
      try {
        final res = await _client
            .from('products')
            .select()
            .inFilter('id', missingIds);
        for (final row in res as List) {
          final product = ProductModel.fromJson(row as Map<String, dynamic>);
          result[product.id] = product;
          // Cache za kasnije
          await cache.cacheProduct(product);
        }
      } catch (e, st) {
        LoggerService.error('Failed to load products batch', e,
            stackTrace: st, extra: {'count': missingIds.length});
        // Fallback: vraći samo cacheirane
      }
    }

    return result;
  }

  Future<String> addProduct(ProductModel product) async {
    final data = product.toJson();
    final res =
        await _client.from('products').insert(data).select('id').single();
    return (res)['id'] as String;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _client
        .from('products')
        .update(product.toJson())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<void> updateAvailableNow(String productId, bool availableNow) async {
    await _client
        .from('products')
        .update({'available_now': availableNow}).eq('id', productId);
  }
}
