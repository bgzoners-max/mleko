import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../core/logger_service.dart';
import '../../core/retry_utils.dart';
import '../product_cache_service.dart';
import '../../../utils/search_utils.dart';

mixin ProductListingMixin {
  SupabaseClient get client;

  Future<List<ProductModel>> attachSelectedDeliveryPointIds(
      List<ProductModel> products);

  /// Najnoviji proizvodi za listu kategorija (parent category page).
  Future<({List<ProductModel> items, bool hasMore})> getProductsByCategories({
    required List<String> categoryNames,
    int limit = productsPageSize,
    int offset = 0,
  }) async {
    if (categoryNames.isEmpty) return (items: <ProductModel>[], hasMore: false);
    const table = 'products_with_ratings';
    final list = await withRetry(() => client
        .from(table)
        .select()
        .inFilter('category', categoryNames)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1));
    final rows = list as List;
    final products = rows
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: products, hasMore: products.length >= limit);
  }

  /// Stream proizvoda prodavca – Realtime umesto polling-a
  Stream<List<ProductModel>> getProductsBySeller(String sellerId,
      {Stream<void>? refreshTrigger}) {
    final controller = StreamController<List<ProductModel>>.broadcast();
    final cache = ProductCacheService();
    StreamSubscription? refreshSub;

    Future<void> refetch() async {
      try {
        final list = await client
            .from('products')
            .select()
            .eq('seller_id', sellerId)
            .order('created_at', ascending: false);
        final products = await attachSelectedDeliveryPointIds(
          (list as List)
              .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList(growable: false),
        );

        await cache.cacheProducts(
            ProductCacheService.sellerKey(sellerId), products);

        if (!controller.isClosed) {
          controller.add(products);
        }
      } catch (e, st) {
        LoggerService.error('Failed to refetch seller products', e,
            stackTrace: st, extra: {'sellerId': sellerId});

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

    final channel = client.channel('products-seller-$sellerId');
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
      client.removeChannel(channel);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  Future<List<ProductModel>> getProductsBySellerSnapshot(
      String sellerId) async {
    final list = await client
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    final products = (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return attachSelectedDeliveryPointIds(products);
  }

  Future<List<ProductModel>> getRelatedSellerProducts({
    required String sellerId,
    required String excludeProductId,
    int limit = 6,
  }) async {
    try {
      final res = await client.rpc(
        'get_related_seller_products',
        params: {
          'p_seller_id': sellerId,
          'p_exclude_product_id': excludeProductId,
          'p_limit': limit,
        },
      );

      final rows = res as List;
      return rows
          .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
          .toList(growable: false);
    } catch (e) {
      LoggerService.warning(
        'RPC get_related_seller_products failed, falling back to direct query',
        extra: {'sellerId': sellerId, 'error': e.toString()},
      );

      try {
        final rows = await client
            .from('products')
            .select(
              'id, seller_id, category, name, price_per_kg, min_order_kg, '
              'order_step, available_kg, unit_type, description, image_urls, '
              'pickup_options, location, is_domestic, available_now, '
              'delivery_mode, created_at, seller_is_verified',
            )
            .eq('seller_id', sellerId)
            .neq('id', excludeProductId)
            .eq('available_now', true)
            .order('created_at', ascending: false)
            .limit(limit);

        return (rows as List)
            .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
            .toList(growable: false);
      } catch (fallbackError, fallbackSt) {
        LoggerService.error(
          'Failed to fetch related seller products via fallback',
          fallbackError,
          stackTrace: fallbackSt,
          extra: {'sellerId': sellerId, 'excludeProductId': excludeProductId},
        );
        return const [];
      }
    }
  }

  Future<ProductModel?> getProduct(String id) async {
    final cache = ProductCacheService();
    try {
      final res =
          await client.from('products').select().eq('id', id).maybeSingle();
      if (res == null) {
        return null;
      }
      final product = (await attachSelectedDeliveryPointIds(
        [ProductModel.fromJson(res)],
      ))
          .first;
      await cache.cacheProduct(product);
      return product;
    } catch (e, st) {
      LoggerService.error('Failed to load product', e,
          stackTrace: st, extra: {'productId': id});
      final cachedProduct = await cache.getCachedProduct(id);
      if (cachedProduct != null) {
        LoggerService.info('Using cached product as fallback');
        return cachedProduct;
      }
      return null;
    }
  }

  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};

    final cache = ProductCacheService();
    final result = <String, ProductModel>{};
    final missingIds = <String>[];

    // Paralelno čitanje keša: `await` u petlji serijalizuje platform pozive,
    // dok Future.wait čini ukupno trajanje max umesto sum.
    final cachedProducts = await Future.wait(ids.map(cache.getCachedProduct));
    for (var i = 0; i < ids.length; i++) {
      final cached = cachedProducts[i];
      if (cached != null) {
        result[ids[i]] = cached;
      } else {
        missingIds.add(ids[i]);
      }
    }

    if (missingIds.isNotEmpty) {
      try {
        final res =
            await client.from('products').select().inFilter('id', missingIds);
        final products = await attachSelectedDeliveryPointIds(
          (res as List)
              .map((row) => ProductModel.fromJson(row as Map<String, dynamic>))
              .toList(growable: false),
        );
        for (final product in products) {
          result[product.id] = product;
          await cache.cacheProduct(product);
        }
      } catch (e, st) {
        LoggerService.error('Failed to load products batch', e,
            stackTrace: st, extra: {'count': missingIds.length});
      }
    }

    return result;
  }
}
