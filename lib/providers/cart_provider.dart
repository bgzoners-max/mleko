import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_error.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';
import '../utils/quantity_engine.dart';
import 'package:mleko/services/services.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, Map<String, double>> _sellerItems = {};
  final ProductsService _productsService;
  static const _legacyDraftsStorageKey = 'mleko_seller_drafts';
  static const _legacyStorageKey = 'mleko_cart';

  static String storageKeyFor(String? userId) =>
      userId != null && userId.isNotEmpty ? 'mleko_cart_$userId' : 'mleko_cart_guest';

  Future<Map<String, List<({ProductModel product, double quantity})>>>?
      _groupedCache;
  final Map<String, Future<List<({ProductModel product, double quantity})>>>
      _bySellerCache = {};

  /// Lenjo izgrađen indeks `productId -> sellerId` za O(1) pretrage bez
  /// linearnog skeniranja svih prodavaca. Resetuje se u [_invalidateCache].
  Map<String, String>? _productSellerIndex;

  Map<String, String> get _productIndex {
    final cached = _productSellerIndex;
    if (cached != null) return cached;
    final map = <String, String>{};
    for (final entry in _sellerItems.entries) {
      for (final productId in entry.value.keys) {
        // Zadrži prvog prodavca (isti redosled kao stari linearni sken).
        map.putIfAbsent(productId, () => entry.key);
      }
    }
    return _productSellerIndex = map;
  }

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

  /// Postavlja aktivnog korisnika i bezbedno izoluje korpu po nalogu.
  /// Ako je prethodni nalog bio gost, spaja gostujuće stavke u korpu korisnika.
  /// Ako se nalog menja (Korisnik A -> Korisnik B), korpe se NE mešaju.
  Future<void> setUser(String? userId) async {
    await _initFuture;
    if (_currentUserId == userId) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Ako je prethodni korisnik bio gost (_currentUserId == null), a novi je prijavljeni korisnik:
    if (_currentUserId == null && userId != null && userId.isNotEmpty) {
      final guestItems = Map<String, Map<String, double>>.from(
        _sellerItems.map((k, v) => MapEntry(k, Map<String, double>.from(v))),
      );
      _currentUserId = userId;
      await prefs.setString('mleko_cart_user_id', userId);

      final userKey = storageKeyFor(userId);
      final userItems = _loadFromStorage(prefs, userKey);

      var hasClaimed = false;
      if (guestItems.isNotEmpty) {
        for (final sEntry in guestItems.entries) {
          final sellerMap = userItems.putIfAbsent(sEntry.key, () => {});
          for (final pEntry in sEntry.value.entries) {
            sellerMap[pEntry.key] = pEntry.value;
            hasClaimed = true;
          }
        }
        await prefs.remove(storageKeyFor(null));
      }

      _sellerItems.clear();
      _sellerItems.addAll(userItems);
      _hasMigratedFromGuest = hasClaimed;

      await _saveDirect(prefs);
      _invalidateCache();
      notifyListeners();
      return;
    }

    // 2. Ako prelazimo sa ulogovanog korisnika na drugog korisnika ili gosta:
    if (_currentUserId != null) {
      await _saveDirect(prefs);
    }

    _currentUserId = userId;
    _hasMigratedFromGuest = false;

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString('mleko_cart_user_id', userId);
    } else {
      await prefs.remove('mleko_cart_user_id');
    }

    final newKey = storageKeyFor(userId);
    final loaded = _loadFromStorage(prefs, newKey);
    _sellerItems.clear();
    _sellerItems.addAll(loaded);

    _invalidateCache();
    notifyListeners();
  }

  Future<void> claimGuestCart(String userId) async {
    await setUser(userId);
  }

  void dismissGuestCartBanner() {
    if (_hasMigratedFromGuest) {
      _hasMigratedFromGuest = false;
      notifyListeners();
    }
  }

  Future<void> clearForLogout() async {
    await _initFuture;
    final prefs = await SharedPreferences.getInstance();
    // Sačuvaj korpu odjavljenog korisnika pod njegovim ključem
    if (_currentUserId != null) {
      await _saveDirect(prefs);
    }
    _currentUserId = null;
    _hasMigratedFromGuest = false;
    _sellerItems.clear();
    await prefs.remove('mleko_cart_user_id');
    _invalidateCache();
    notifyListeners();
  }

  late final Future<void> _initFuture;
  Future<void> get loadFuture => _initFuture;

  CartProvider({required ProductsService productsService})
      : _productsService = productsService {
    _initFuture = _load();
  }

  Map<String, Map<String, double>> _loadFromStorage(
    SharedPreferences prefs,
    String key,
  ) {
    final stored = prefs.getString(key);
    if (stored == null || stored.isEmpty) return {};
    try {
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
      return loaded;
    } catch (_) {
      return {};
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('mleko_cart_user_id');
      if (savedUserId != null && savedUserId.isNotEmpty) {
        _currentUserId ??= savedUserId;
      }

      // 1. Migracija starog mleko_seller_drafts ključa ako postoji
      if (prefs.containsKey(_legacyDraftsStorageKey)) {
        final legacyDrafts = _loadFromStorage(prefs, _legacyDraftsStorageKey);
        if (legacyDrafts.isNotEmpty) {
          final targetKey = storageKeyFor(_currentUserId);
          if (!prefs.containsKey(targetKey)) {
            await prefs.setString(targetKey, jsonEncode(legacyDrafts));
          }
        }
        await prefs.remove(_legacyDraftsStorageKey);
      }

      // 2. Migracija najstarijeg flat formata mleko_cart
      await _migrateLegacyData(prefs);

      // 3. Učitavanje korpe za trenutnog korisnika / gosta
      final key = storageKeyFor(_currentUserId);
      final loaded = _loadFromStorage(prefs, key);

      // Spoji sa eventualnim stavkama koje su već unete u memoriju pre završetka _load()
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
    } catch (e) {
      LoggerService.warning('Failed to load cart from storage',
          extra: {'error': e.toString()});
      // Nastavi sa praznom korpom u slučaju greške
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
      final key = storageKeyFor(_currentUserId);
      await prefs.setString(key, jsonEncode(_sellerItems));
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
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

  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveCompleter ??= Completer<void>();

    _saveDebounceTimer = Timer(_saveDebounceDelay, () async {
      await _executeSave();
    });
  }

  Future<void> _executeSave() async {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    final completer = _saveCompleter;
    _saveCompleter = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await _saveDirect(prefs);
    } catch (e) {
      LoggerService.warning('Failed to save cart to storage',
          extra: {'error': e.toString()});
    } finally {
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Forsira trenutno upisivanje svih zaostalih promena u [SharedPreferences].
  Future<void> flush() async {
    await _initFuture;
    if (_saveDebounceTimer != null || _saveCompleter != null) {
      await _executeSave();
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  /// Invalidira keširane proizvode (po prodavcu ili kompletno) radi osvežavanja podataka.
  void invalidateProductsCache([String? sellerId]) => _invalidateCache(sellerId);

  void _invalidateCache([String? sellerId]) {
    _groupedCache = null;
    _productSellerIndex = null;
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
    ProductModel? product,
  }) async {
    if (quantity <= 0) return;
    await _initFuture;

    final resolvedProduct = product ?? await _productsService.getProduct(productId);
    final sellerDraft =
        _sellerItems.putIfAbsent(sellerId, () => <String, double>{});
    final currentQty = sellerDraft[productId] ?? 0.0;
    var targetQty = currentQty + quantity;

    if (resolvedProduct != null) {
      final step = resolvedProduct.quantityStep;
      final minQty = resolvedProduct.minOrderKg;

      if (!QuantityEngine.isValidQuantity(
        quantity: targetQty,
        minQuantity: minQty,
        step: step,
      )) {
        throw AppError(
          message: 'Invalid quantity for ${resolvedProduct.name}',
          userMessage:
              '${resolvedProduct.name}: količina mora biti od minimuma (${resolvedProduct.minOrderFormatted}) i u koracima od ${ProductModel.formatQuantityWithUnit(step, resolvedProduct.unitType)}.',
          type: ErrorType.validation,
        );
      }
      targetQty = QuantityEngine.normalizeQuantity(
        quantity: targetQty,
        minQuantity: minQty,
        step: step,
      );
    } else {
      targetQty = QuantityEngine.normalizeQuantity(
        quantity: targetQty,
        minQuantity: targetQty,
        step: 1.0,
      );
    }

    sellerDraft[productId] = targetQty;
    _invalidateCache(sellerId);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> setQuantityForSeller({
    required String sellerId,
    required String productId,
    required double quantity,
    ProductModel? product,
  }) async {
    await _initFuture;
    if (quantity <= 0) {
      await removeFromSeller(sellerId: sellerId, productId: productId);
      return;
    }

    final resolvedProduct = product ?? await _productsService.getProduct(productId);
    var targetQty = quantity;

    if (resolvedProduct != null) {
      final step = resolvedProduct.quantityStep;
      final minQty = resolvedProduct.minOrderKg;

      if (!QuantityEngine.isValidQuantity(
        quantity: targetQty,
        minQuantity: minQty,
        step: step,
      )) {
        throw AppError(
          message: 'Invalid quantity for ${resolvedProduct.name}',
          userMessage:
              '${resolvedProduct.name}: količina mora biti od minimuma (${resolvedProduct.minOrderFormatted}) i u koracima od ${ProductModel.formatQuantityWithUnit(step, resolvedProduct.unitType)}.',
          type: ErrorType.validation,
        );
      }
      targetQty = QuantityEngine.normalizeQuantity(
        quantity: targetQty,
        minQuantity: minQty,
        step: step,
      );
    } else {
      targetQty = QuantityEngine.normalizeQuantity(
        quantity: targetQty,
        minQuantity: targetQty,
        step: 1.0,
      );
    }

    final sellerDraft =
        _sellerItems.putIfAbsent(sellerId, () => <String, double>{});
    sellerDraft[productId] = targetQty;
    _invalidateCache(sellerId);
    notifyListeners();
    _scheduleSave();
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
    _invalidateCache(sellerId);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> clearSeller(String sellerId) async {
    await _initFuture;
    _sellerItems.remove(sellerId);
    _invalidateCache(sellerId);
    notifyListeners();
    _scheduleSave();
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
    _invalidateCache(sellerId);
    notifyListeners();
    _scheduleSave();
  }

  Future<void> clear() async {
    await _initFuture;
    _sellerItems.clear();
    _invalidateCache();
    notifyListeners();
    _scheduleSave();
  }

  /// Backward-compatible wrappers (pozivi bez sellerId).
  Future<void> add(String productId, {double quantity = 1}) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await addForSeller(
      sellerId: p.sellerId,
      productId: p.id,
      quantity: quantity,
      product: p,
    );
  }

  Future<void> setQuantity(String productId, double quantity) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await setQuantityForSeller(
      sellerId: p.sellerId,
      productId: p.id,
      quantity: quantity,
      product: p,
    );
  }

  Future<void> remove(String productId) async {
    final p = await _productsService.getProduct(productId);
    if (p == null) return;
    await removeFromSeller(sellerId: p.sellerId, productId: p.id);
  }

  bool contains(String productId) => _productIndex.containsKey(productId);

  double? getQuantity(String productId) {
    final sellerId = _productIndex[productId];
    return sellerId == null ? null : _sellerItems[sellerId]?[productId];
  }

  Future<List<({ProductModel product, double quantity})>> getProductsBySeller(
    String sellerId, {
    bool forceRefresh = false,
  }) async {
    await _initFuture;
    if (forceRefresh) {
      _invalidateCache(sellerId);
    }
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

