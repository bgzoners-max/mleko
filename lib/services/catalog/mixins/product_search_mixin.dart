import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../models/product_sort.dart';
import '../../../utils/refetch_throttle.dart';
import '../../../utils/search_utils.dart';
import '../../core/logger_service.dart';
import '../../core/retry_utils.dart';
import '../product_cache_service.dart';

mixin ProductSearchMixin {
  SupabaseClient get client;

  int compareProducts(ProductModel a, ProductModel b, ProductSort sort);

  /// Paginirani učitavanje proizvoda – za “load more” / beskonačan scroll.
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
    String? excludeSellerId,
    ProductSort sort = ProductSort.dateDesc,
    int limit = 20, // Preuzeto iz productsPageSize konstante ako postoji
    int offset = 0,
  }) async {
    final safeSearch = sanitizeProductSearchInput(searchQuery);

    final List<dynamic> rawRows;

    if (safeSearch != null) {
      final params = <String, dynamic>{
        'p_query': safeSearch,
        'p_limit': limit + 1,
        'p_offset': offset,
      };
      if (category != null && category.isNotEmpty) {
        params['p_category'] = category;
      }
      if (region != null && region.isNotEmpty) {
        params['p_region'] = region;
      }
      if (availableNow == true) {
        params['p_available_now'] = true;
      }
      if (excludeSellerId != null && excludeSellerId.isNotEmpty) {
        params['p_exclude_seller_id'] = excludeSellerId;
      }
      final dynamic response = await withRetry(
          () => client.rpc('search_products_fts', params: params));
      rawRows = response is List ? response : const <dynamic>[];
    } else {
      const table = 'products_with_ratings';
      var query = client.from(table).select();
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (excludeSellerId != null && excludeSellerId.isNotEmpty) {
        query = query.neq('seller_id', excludeSellerId);
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
      rawRows =
          await withRetry(() => ordered.range(offset, offset + limit));
    }

    final rows = rawRows
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final products = rows
        .map((e) => ProductModel.fromJson(e))
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
    final hasMore = products.length > limit;
    if (hasMore) {
      products.removeLast();
    }

    if (safeSearch != null && offset == 0 && products.isNotEmpty) {
      unawaited(ProductCacheService().cacheProducts(
        ProductCacheService.searchKey(safeSearch),
        products,
      ));
    }

    return (
      items: products,
      hasMore: hasMore,
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
    int limit = 20,
    int offset = 0,
  }) async {
    final cache = ProductCacheService();
    final safeSearch = sanitizeProductSearchInput(searchQuery);
    final tokens =
        safeSearch != null ? nameSearchTokens(safeSearch) : <String>[];

    final allCached = await cache.getAllCachedProducts();
    final filtered = allCached.where((p) {
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

      return matchesAllSearchTokens(p.name, tokens);
    }).toList();

    filtered.sort((a, b) => compareProducts(a, b, sort));

    if (offset >= filtered.length) {
      return (
        items: <ProductModel>[],
        hasMore: false,
        salesCounts: <String, int>{},
      );
    }

    final end =
        (offset + limit + 1) > filtered.length ? filtered.length : (offset + limit + 1);
    final page = filtered.sublist(offset, end);

    LoggerService.debug('Local cache search completed', extra: {
      'query': safeSearch ?? '',
      'tokens': tokens,
      'total': filtered.length,
      'returned': page.length,
      'offset': offset,
      'limit': limit,
    });

    final hasMore = page.length > limit;
    if (hasMore) {
      page.removeLast();
    }

    return (
      items: page,
      hasMore: hasMore,
      salesCounts: <String, int>{},
    );
  }

  /// Home ekran – jedan RPC (products + order_count + rating), limit 50, Realtime osvežavanje.
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
    // Maksimalna učestanost refetch-a izazvana realtime događajima.
    // Eksplicitno osvežavanje (pull-to-refresh, promena regije) ide odmah.
    const throttleInterval = Duration(seconds: 2);
    final realtimeThrottle = RefetchThrottle(minInterval: throttleInterval);
    Timer? realtimeThrottleTimer;
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

    final initialRegion = regionNotifier?.value ?? region;
    final initialCacheKey = initialRegion != null
        ? '${ProductCacheService.homeProductsKey}_$initialRegion'
        : ProductCacheService.homeProductsKey;
    final syncCached = cache.getCachedProductsSync(initialCacheKey);
    ({
      List<ProductModel> products,
      Map<String, int> salesCounts,
      Map<String, ({double avg, int count})> ratings
    })? lastEmitted = (syncCached != null && syncCached.isNotEmpty)
        ? (
            products: syncCached,
            salesCounts: <String, int>{},
            ratings: <String, ({double avg, int count})>{}
          )
        : null;

    Future<void> runSingleFetch() async {
      final currentRegion = regionNotifier?.value ?? region;
      final cacheKey = currentRegion != null
          ? '${ProductCacheService.homeProductsKey}_$currentRegion'
          : ProductCacheService.homeProductsKey;
      try {
        final res = await client.rpc(
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

        await cache.cacheProducts(cacheKey, products);

        final emittedData =
            (products: products, salesCounts: salesCounts, ratings: ratings);
        lastEmitted = emittedData;
        if (!controller.isClosed) {
          controller.add(emittedData);
        }
      } catch (e, st) {
        LoggerService.error('Failed to load home products', e, stackTrace: st);

        final cachedProducts = await cache.getCachedProducts(cacheKey);
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          LoggerService.info('Using cached home products as fallback');
          final fallbackData = (
            products: cachedProducts,
            salesCounts: <String, int>{},
            ratings: <String, ({double avg, int count})>{}
          );
          lastEmitted = fallbackData;
          if (!controller.isClosed) {
            controller.add(fallbackData);
          }
        } else if (!controller.isClosed) {
          final emptyData = (
            products: <ProductModel>[],
            salesCounts: <String, int>{},
            ratings: <String, ({double avg, int count})>{}
          );
          lastEmitted = emptyData;
          controller.add(emptyData);
        }
      }
    }

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

    // Realtime callback: filtrira promene van izabranog regiona i guši pljusak
    // promena u kratkom prozoru (max 1 RPC na 2 s) da ne plavi bazu pozivima.
    void scheduleThrottledRealtimeRefetch(PostgresChangePayload payload) {
      final currentRegion = regionNotifier?.value ?? region;
      if (currentRegion != null && currentRegion.isNotEmpty) {
        final row = payload.newRecord.isNotEmpty
            ? payload.newRecord
            : payload.oldRecord;
        if (row.isNotEmpty) {
          final rowRegion = row['location']?.toString();
          if (rowRegion != null &&
              rowRegion.isNotEmpty &&
              rowRegion != currentRegion) {
            return; // Promena nije vezana za izabran region.
          }
        }
      }

      if (realtimeThrottle.tryAcquire()) {
        unawaited(refetch());
        return;
      }
      realtimeThrottleTimer ??= Timer(realtimeThrottle.remainingWait, () {
        realtimeThrottleTimer = null;
        if (controller.isClosed) return;
        realtimeThrottle.tryAcquire();
        unawaited(refetch());
      });
    }

    cache.getCachedProducts(initialCacheKey).then((cachedProducts) {
      if (controller.isClosed) return;
      if (cachedProducts != null && cachedProducts.isNotEmpty) {
        final cachedData = (
          products: cachedProducts,
          salesCounts: <String, int>{},
          ratings: <String, ({double avg, int count})>{}
        );
        lastEmitted = cachedData;
        controller.add(cachedData);
      }
      refetch();
    }).catchError((e) {
      if (controller.isClosed) return;
      refetch();
    });

    final channel = client.channel('home-products');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products',
          callback: scheduleThrottledRealtimeRefetch,
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    if (regionNotifier != null) {
      regionListener = () => refetch();
      regionNotifier.addListener(regionListener);
    }

    controller.onCancel = () {
      refreshSub?.cancel();
      realtimeThrottleTimer?.cancel();
      realtimeThrottleTimer = null;
      if (regionNotifier != null && regionListener != null) {
        regionNotifier.removeListener(regionListener);
      }
      client.removeChannel(channel);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return Stream.multi(
      (multiController) {
        if (lastEmitted != null) {
          multiController.add(lastEmitted!);
        }
        final sub = controller.stream.listen(
          multiController.add,
          onError: multiController.addError,
          onDone: multiController.close,
        );
        multiController.onCancel = () {
          sub.cancel();
        };
      },
      isBroadcast: true,
    );
  }
}
