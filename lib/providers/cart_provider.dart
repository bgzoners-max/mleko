import 'dart:async';
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

  // Debouncing za _save() da spreči race conditions pri rapid-fire pozivima
  Timer? _saveDebounceTimer;
  static const _saveDebounceDelay = Duration(milliseconds: 100);
  Completer<void>? _saveCompleter; // Za serialization save operacija

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

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  bool _hasMigratedFromGuest = false;
  bool get hasMigratedFromGuest => _hasMigratedFromGuest;

  Future<void> claimGuestCart(String userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    if (count > 0) {
      _hasMigratedFromGuest = true;
    }
    await _save();
    notifyListeners();
  }

  void dismissGuestCartBanner() {
    if (_hasMigratedFromGuest) {
      _hasMigratedFromGuest = false;
      notifyListeners();
    }
  }

  Future<void> clearForLogout() async {
    _currentUserId = null;
    _hasMigratedFromGuest = false;
    await _save();
    notifyListeners();
  }

  late final Future<void> _initFuture;
  Future<void> get loadFuture => _initFuture;

  CartProvider({required ProductsService productsService})
      : _productsService = productsService {
    _initFuture = _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('mleko_cart_user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _currentUserId ??= savedUserId;
      }
      final stored = prefs.getString(_storageKey);
      if (stored != null && stored.isNotEmpty) {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        final loaded = <String, Map<String, double>>{};
        for (final sellerEntry in decoded.entries) {
          final products = sellerEntry.value as Map<String, dynamic>;
          final parsed = <String, double>{};
          for (final productEntry in products.entries) {
            final qty = (productEntry.value as num?)?.toDouble();
            if (qty != null && qty > 0) parsed[productEntry.key] = qty;
          }
          if (parsed.isNotEmpty) loaded[sellerEntry.key] = parsed;
        }

        // Spoji sa eventualnim stavkama koje su već unete u memoriju
        for (final entry in _sellerItems.entries) {
          final sellerMap = loaded.putIfAbsent(entry.key, () => {});
          for (final pEntry in entry.value.entries) {
            sellerMap[pEntry.key] = pEntry.value;
          }
        }
        _sellerItems.clear();
        _sellerItems.addAll(loaded);

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

    await _saveDirect(prefs);
    await prefs.remove(_legacyStorageKey);
    await prefs.remove('mleko_cart_ids');
    _invalidateCache();
    notifyListeners();
  }

  Future<void> _saveDirect(SharedPreferences prefs) async {
    try {
      await prefs.setString(_storageKey, jsonEncode(_sellerItems));
      if (_currentUserId != null) {
        await prefs.setString('mleko_cart_user_id', _currentUserId!);
      } else {
        await prefs.remove('mleko_cart_user_id');
      }
    } catch (e) {
      LoggerService.warning('Failed to save cart to storage',
          extra: {'error': e.toString()});
      // Continue anyway, this is non-critical
    }
  }

  Future<void> _save() async {
    await _initFuture;
    
    // Cancel previous debounce timer
    _saveDebounceTimer?.cancel();
    
    // Create a completer for this save operation
    final completer = Completer<void>();
    
    // If there's already a save in progress, wait for it
    if (_saveCompleter != null && !_saveCompleter!.isCompleted) {
      await _saveCompleter!.future;
    }
    
    _saveCompleter = completer;
    
    // Debounce: wait a bit before actually saving
    _saveDebounceTimer = Timer(_saveDebounceDelay, () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _saveDirect(prefs);
        completer.complete();
      } catch (e) {
        LoggerService.warning('Failed to save cart to storage',
            extra: {'error': e.toString()});
        completer.complete(); // Complete even on error to unblock queue
      }
    });
    
    // Wait for the debounced save to complete
    await completer.future;
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
    await _initFuture;
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
    await _initFuture;
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
    await _initFuture;
    final sellerDraft = _sellerItems[sellerId];
    if (sellerDraft == null) return;
    sellerDraft.remove(productId);
    if (sellerDraft.isEmpty) _sellerItems.remove(sellerId);
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  Future<void> clearSeller(String sellerId) async {
    await _initFuture;
    _sellerItems.remove(sellerId);
    await _save();
    _invalidateCache(sellerId);
    notifyListeners();
  }

  /// Ubacuje stavke porudžbine u korpu za datog prodavca (npr. „Ponovi porudžbinu”).
  /// Zamenjuje postojeće stavke tog prodavca.
  Future<void> setOrderItemsForSeller(
      String sellerId, List<OrderItemModel> items) async {
    await _initFuture;
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
    await _initFuture;
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
    await _initFuture;
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
    await _initFuture;
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

