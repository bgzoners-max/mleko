import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/app_error.dart';
import '../../models/product_sort.dart';
import 'mixins/product_search_mixin.dart';
import 'mixins/product_listing_mixin.dart';
import 'mixins/product_stats_mixin.dart';
import 'mixins/product_management_mixin.dart';

export '../../models/product_autoflag.dart';
export '../../models/product_sort.dart';
export '../../utils/search_utils.dart';

class ProductsService
    with
        ProductSearchMixin,
        ProductListingMixin,
        ProductStatsMixin,
        ProductManagementMixin {
  static final ProductsService _instance = ProductsService._();
  factory ProductsService({SupabaseClient? client}) {
    if (client != null) return ProductsService._(client: client);
    return _instance;
  }
  ProductsService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;

  @override
  SupabaseClient get client => _customClient ?? Supabase.instance.client;

  Future<Map<String, List<String>>> getSelectedDeliveryPointIdsForProducts(
    List<String> productIds,
  ) async {
    try {
      if (productIds.isEmpty) return const {};

      final rows = await client
          .from('product_delivery_points')
          .select('product_id, delivery_point_id')
          .inFilter('product_id', productIds);

      final map = <String, List<String>>{};
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final productId = row['product_id'] as String?;
        final deliveryPointId = row['delivery_point_id'] as String?;
        if (productId == null || deliveryPointId == null) continue;
        map.putIfAbsent(productId, () => []).add(deliveryPointId);
      }
      return map;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  @override
  Future<List<ProductModel>> attachSelectedDeliveryPointIds(
    List<ProductModel> products,
  ) async {
    try {
      final selectedModeProducts = products
          .where((product) => product.usesSelectedDeliveryPoints)
          .toList(growable: false);
      if (selectedModeProducts.isEmpty) return products;

      final idsByProduct = await getSelectedDeliveryPointIdsForProducts(
        selectedModeProducts.map((product) => product.id).toList(),
      );

      return products
          .map(
            (product) {
              final ids = idsByProduct[product.id];
              return ids != null
                  ? product.copyWith(selectedDeliveryPointIds: ids)
                  : product;
            },
          )
          .toList(growable: false);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  @override
  int compareProducts(ProductModel a, ProductModel b, ProductSort sort) {
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
        final rA = a.avgRating ?? 0.0;
        final rB = b.avgRating ?? 0.0;
        if (rA != rB) {
          return rB.compareTo(rA);
        }
        return b.createdAt.compareTo(a.createdAt);
    }
  }
}
