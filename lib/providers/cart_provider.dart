import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, Map<String, double>> _sellerItems = {};
  final ProductsService _productsService;
  static const _storageKey = 'mleko_seller_drafts';
  static const _legacyStorageKey = 'mleko_cart';

  Future<Map<String, List<({ProductModel product, double quantity})>>>?
      _groupedCache;
  final Map<String, Future<List<({ProductModel product, double quantity})>>>
      _bySellerCache = {};

  int get count =>
      _sellerItems.values.fold(0, (sum, items) => sum + items.length);
  bool get isEmpty => count == 0;
  int get sellerCount => _sellerItems.length;

  double? getQuantityForSeller(String sellerId, String productId) =>
      _sellerItems[sellerId]?[productId];
  bool containsInSeller(String sellerId, String productId) =>
      _sellerItems[sellerId]?.containsKey(productId) ?? false;
  Map<String, double> getSellerDraft(String sellerId) =>
      Map<String, double>.from(_sellerItems[sellerId] ?? const {});

  CartProvider({required ProductsService productsService})
      : _productsService = productsService {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        _sellerItems.clear();
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        for (final sellerEntry in decoded.entries) {
          final products = sellerEntry.value as Map<String, dynamic>;
          final parsed = <String, double>{};
          for (final productEntry in products.entries) {
            final qty = (productEntry.value as num?)?.toDouble();
            if (qty != null && qty > 0) parsed[productEntry.key] = qty;
          }
          if (parsed.isNotEmpty) _sellerItems[sellerEntry.key] = parsed;
        }
        _invalidateCache();
        notifyListeners();
        return;
      }

      await _migrateLegacyData(prefs);
    } catch (e) {
      LoggerService.warning('Failed to load cart from storage',
          extra: {'error': e.toString()});
      // Continue with empty cart, this is non-critical
    }
  }

  Future<void> _migrateLegacyData(SharedPreferences prefs) async {
    final legacyFlat = <String, double>{};

    final legacyJson = prefs.getString(_legacyStorageKey);
    if (legacyJson != null && legacyJson.isNotEmpty) {
      for (final entry in legacyJson.split(';')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final qty = double.tryParse(parts[1]);
          if (qty != null && qty > 0) legacyFlat[parts[0]] = qty;
        }
      }
    }

    final legacyIds = prefs.getStringList('mleko_cart_ids');
    if (legacyIds != null && legacyIds.isNotEmpty) {
      for (final id in legacyIds) {
        legacyFlat.putIfAbsent(id, () => 1.0);
      }
    }

    if (legacyFlat.isEmpty) return;

    // Batch load umesto N+1 petlje
    final products = await _productsService.getProductsByIds(legacyFlat.keys.toList());
    for (final entry in legacyFlat.entries) {
      final p = products[entry.key];
      if (p == null) continue;
      final sellerDraft =
          _sellerItems.putIfAbsent(p.sellerId, () => <String, double>{});
      sellerDraft[p.id] = entry.value;
    }

    await _save();
    await prefs.remove(_legacyStorageKey);
    await prefs.remove('mleko_cart_ids');
    _invalidateCache();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_sellerItems));
    } catch (e) {
      LoggerService.warning('Failed to save cart to storage',
          extra: {'error': e.toString()});
      // Continue anyway, this is non-critical
    }
  }

  void _invalidateCache([String? sellerId]) {
    _groupedCache = null;
    if (sellerId != null) {
      _bySellerCache.remove(sellerId);
    } else {
      _bySellerCache.clear();
    }
  }

  Future<void> addForSeller({
    required String sellerId,
    required String productId,
    double quantity = 1,
  }) async {
    if (quantity <= 0) return;
    final sellerDraft =
        _sellerItems.putIfAbsent(sellerId, () => <String, double>{});
    sellerDraft[productId] = (sellerDraft[productId] ?? 0) + quantity;
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  Future<void> setQuantityForSeller({
    required String sellerId,
    required String productId,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromSeller(sellerId: sellerId, productId: productId);
      return;
    }
    final sellerDraft =
        _sellerItems.putIfAbsent(sellerId, () => <String, double>{});
    sellerDraft[productId] = quantity;
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  Future<void> removeFromSeller({
    required String sellerId,
    required String productId,
  }) async {
    final sellerDraft = _sellerItems[sellerId];
    if (sellerDraft == null) return;
    sellerDraft.remove(productId);
    if (sellerDraft.isEmpty) _sellerItems.remove(sellerId);
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  Future<void> clearSeller(String sellerId) async {
    _sellerItems.remove(sellerId);
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  /// Ubacuje stavke porudžbine u korpu za datog prodavca (npr. „Ponovi porudžbinu”).
  /// Zamenjuje postojeće stavke tog prodavca.
  Future<void> setOrderItemsForSeller(
      String sellerId, List<OrderItemModel> items) async {
    if (items.isEmpty) {
      await clearSeller(sellerId);
      return;
    }
    _sellerItems.remove(sellerId);
    final sellerDraft = <String, double>{};
    for (final item in items) {
      if (item.quantityKg > 0) {
        sellerDraft[item.productId] = item.quantityKg;
      }
    }
    if (sellerDraft.isNotEmpty) _sellerItems[sellerId] = sellerDraft;
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  Future<void> clear() async {
    _sellerItems.clear();
    await _save();
    _invalidateCache();
    notifyListeners();
  }

  /// Backward-compatible wrappers (pozivi bez sellerId).
  Future<void> add(String productId, {double quantity = 1}) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await addForSeller(
        sellerId: p.sellerId, productId: p.id, quantity: quantity);
  }

  Future<void> setQuantity(String productId, double quantity) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await setQuantityForSeller(
        sellerId: p.sellerId, productId: p.id, quantity: quantity);
  }

  Future<void> remove(String productId) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await removeFromSeller(sellerId: p.sellerId, productId: p.id);
  }

  bool contains(String productId) {
    for (final items in _sellerItems.values) {
      if (items.containsKey(productId)) return true;
    }
    return false;
  }

  double? getQuantity(String productId) {
    for (final items in _sellerItems.values) {
      if (items.containsKey(productId)) return items[productId];
    }
    return null;
  }

  Future<List<({ProductModel product, double quantity})>> getProductsBySeller(
      String sellerId) async {
    final sellerDraft = _sellerItems[sellerId];
    if (sellerDraft == null || sellerDraft.isEmpty) return [];
    return _bySellerCache.putIfAbsent(sellerId, () async {
      // Batch load umesto N+1 petlje
      final productIds = sellerDraft.keys.toList();
      final products = await _productsService.getProductsByIds(productIds);
      final result = <({ProductModel product, double quantity})>[];
      for (final e in sellerDraft.entries) {
        final p = products[e.key];
        if (p != null) result.add((product: p, quantity: e.value));
      }
      return result;
    });
  }

  Future<Map<String, List<({ProductModel product, double quantity})>>>
      getProductsGroupedBySeller() async {
    return _groupedCache ??= () async {
      final grouped =
          <String, List<({ProductModel product, double quantity})>>{};
      for (final sellerId in _sellerItems.keys) {
        final sellerProducts = await getProductsBySeller(sellerId);
        if (sellerProducts.isNotEmpty) grouped[sellerId] = sellerProducts;
      }
      return grouped;
    }();
  }
}

