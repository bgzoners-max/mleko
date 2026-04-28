import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/app_error.dart';
import '../core/logger_service.dart';
import '../core/retry_utils.dart';
import 'product_cache_service.dart';

import '../../models/product_autoflag.dart';
import '../../models/product_sort.dart';
import '../../utils/search_utils.dart';
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
  factory ProductsService() => _instance;
  ProductsService._();

  @override
  final client = Supabase.instance.client;

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
            (product) => ProductModel(
              id: product.id,
              sellerId: product.sellerId,
              category: product.category,
              name: product.name,
              pricePerKg: product.pricePerKg,
              minOrderKg: product.minOrderKg,
              orderStep: product.orderStep,
              availableKg: product.availableKg,
              unitType: product.unitType,
              description: product.description,
              imageUrls: product.imageUrls,
              pickupOptions: product.pickupOptions,
              location: product.location,
              isDomestic: product.isDomestic,
              availableNow: product.availableNow,
              deliveryMode: product.deliveryMode,
              selectedDeliveryPointIds:
                  idsByProduct[product.id] ?? product.selectedDeliveryPointIds,
              createdAt: product.createdAt,
            ),
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
        return b.createdAt.compareTo(a.createdAt);
    }
  }
}
