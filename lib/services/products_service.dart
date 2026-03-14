import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';
import 'logger_service.dart';
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

class ProductsService {
  final _client = Supabase.instance.client;

  /// Paginirani učitavanje proizvoda – za "load more" / beskonačan scroll
  /// Uvek koristi view products_with_ratings (ima avg_rating, order_count) – jedan poziv, bez getProductSalesCounts.
  /// searchQuery – server-side ILIKE pretraga po name i category.
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
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final pattern = '*$searchQuery*';
      query = query.or('name.ilike.$pattern,category.ilike.$pattern');
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
    final list = await ordered.range(offset, offset + limit - 1);
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

  /// Home ekran – jedan RPC (products + order_count + rating), limit 50, Realtime osvežavanje
  Stream<({List<ProductModel> products, Map<String, int> salesCounts, Map<String, ({double avg, int count})> ratings})>
      getHomeProducts({
    String? region,
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

    Future<void> refetch() async {
      try {
        final res = await _client.rpc(
          'get_home_products',
          params: {
            'p_limit': limit,
            'p_region': region,
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
          controller.add((products: products, salesCounts: salesCounts, ratings: ratings));
        }
      } catch (e, st) {
        LoggerService.error('Failed to load home products', e, stackTrace: st);

        // Fallback na cache kada je offline
        final cachedProducts =
            await cache.getCachedProducts(ProductCacheService.homeProductsKey);
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          LoggerService.info('Using cached home products as fallback');
          if (!controller.isClosed) {
            controller.add((products: cachedProducts, salesCounts: {}, ratings: {}));
          }
        } else if (!controller.isClosed) {
          controller.add((products: [], salesCounts: {}, ratings: {}));
        }
      }
    }

    // Prvo pokušaj emitovati cached proizvode (brz UX)
    cache
        .getCachedProducts(ProductCacheService.homeProductsKey)
        .then((cachedProducts) {
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        if (!controller.isClosed) {
          controller.add((products: cachedProducts, salesCounts: {}, ratings: {}));
        }
      }
      // Zatim fetch sa servera
      refetch();
    }).catchError((e) {
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

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
    };

    return controller.stream;
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
