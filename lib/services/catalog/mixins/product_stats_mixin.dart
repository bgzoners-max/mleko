import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/product_model.dart';
import '../../../models/user_model.dart';
import '../../../models/product_autoflag.dart';
import '../../../utils/search_utils.dart';
import '../../core/logger_service.dart';
import '../../core/retry_utils.dart';

mixin ProductStatsMixin {
  SupabaseClient get client;

  Future<Map<String, int>> getCategoryCounts({
    required List<String> categoryNames,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    String? searchQuery,
    String? excludeSellerId,
  }) async {
    if (categoryNames.isEmpty) return const {};

    final safeSearch = sanitizeProductSearchInput(searchQuery);
    final tokens =
        safeSearch != null ? nameSearchTokens(safeSearch) : const <String>[];

    final futures = categoryNames.map((categoryName) async {
      var query = client
          .from('products_with_ratings')
          .select()
          .eq('category', categoryName);

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
      for (final token in tokens) {
        query = query.ilike('name', '%$token%');
      }

      final response = await withRetry(() => query.count(CountOption.exact));
      return MapEntry(categoryName, response.count);
    });

    return Map<String, int>.fromEntries(await Future.wait(futures));
  }

  Future<List<UserModel>> getSellersInRegion(String region) async {
    if (region.isEmpty) return [];
    try {
      final productRows = await client
          .from('products')
          .select('seller_id')
          .eq('location', region);
      final sellerIds = (productRows as List)
          .map((e) => (e as Map)['seller_id']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      if (sellerIds.isEmpty) return [];
      final profiles = await client
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

  Future<Map<String, ({double avg, int count})>> getProductRatings() async {
    try {
      final res = await client.rpc('get_product_ratings');
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
    final res = await client.rpc('get_my_product_listing_autoflag_summary');
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
    final res = await client.rpc('get_my_product_listing_autoflags');
    return (res as List)
        .map((e) => ProductListingAutoflag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
