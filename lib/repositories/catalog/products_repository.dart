import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';

/// Interfejs repozitorijuma za čitanje i perzistenciju proizvoda.
abstract interface class ProductsRepository {
  /// Učitava jedan proizvod po ID-ju (prioritetno iz view-a sa agregatima).
  Future<ProductModel?> getProduct(String id);

  /// Alias za [getProduct] po standardnom Repository obrascu.
  Future<ProductModel?> getProductById(String id);

  /// Učitava listu proizvoda po zadatim ID-jevima.
  Future<List<ProductModel>> getProductsByIds(List<String> ids);

  /// Učitava proizvode po kategorijama sa paginacijom.
  Future<({List<ProductModel> items, bool hasMore})> getProductsByCategories({
    required List<String> categoryNames,
    int limit = 20,
    int offset = 0,
  });

  /// Učitava sve proizvode za zadatog prodavca.
  Future<List<ProductModel>> getProductsBySeller(String sellerId);

  /// Kreira novi proizvod u bazi i vraća kreirani model.
  Future<ProductModel> createProduct(ProductModel product);

  /// Ažurira postojeći proizvod u bazi.
  Future<ProductModel> updateProduct(ProductModel product);

  /// Briše proizvod po ID-ju.
  Future<void> deleteProduct(String id);
}

/// Supabase implementacija [ProductsRepository].
class SupabaseProductsRepository implements ProductsRepository {
  final SupabaseClient? _customClient;

  SupabaseProductsRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<ProductModel?> getProduct(String id) async {
    try {
      final res = await _client
          .from('products_with_ratings')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res != null) return ProductModel.fromJson(res);
    } catch (_) {
      // Fallback na products tabelu ako view nije dostupan
    }

    final res = await _client
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return ProductModel.fromJson(res);
  }

  @override
  Future<ProductModel?> getProductById(String id) => getProduct(id);

  @override
  Future<List<ProductModel>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final list = await _client
        .from('products')
        .select()
        .inFilter('id', ids);
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<({List<ProductModel> items, bool hasMore})> getProductsByCategories({
    required List<String> categoryNames,
    int limit = 20,
    int offset = 0,
  }) async {
    if (categoryNames.isEmpty) return (items: <ProductModel>[], hasMore: false);
    const table = 'products_with_ratings';
    final list = await _client
        .from(table)
        .select()
        .inFilter('category', categoryNames)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    final rows = list as List;
    final products = rows
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: products, hasMore: products.length >= limit);
  }

  @override
  Future<List<ProductModel>> getProductsBySeller(String sellerId) async {
    final list = await _client
        .from('products')
        .select()
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (list as List)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    final res = await _client
        .from('products')
        .insert(product.toDbMap())
        .select()
        .single();
    return ProductModel.fromJson(res);
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    final res = await _client
        .from('products')
        .update(product.toDbMap(includeId: false, includeCreatedAt: false))
        .eq('id', product.id)
        .select()
        .single();
    return ProductModel.fromJson(res);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }
}
