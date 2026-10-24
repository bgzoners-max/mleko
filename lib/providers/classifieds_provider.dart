import 'dart:async';
import 'package:flutter/foundation.dart';

import '../constants/serbian_districts.dart';
import '../models/classified_ad_model.dart';
import '../models/classified_category_model.dart';
import '../models/classified_subscription_model.dart';
import '../services/classifieds/classified_subscriptions_service.dart';
import '../services/classifieds/classifieds_service.dart';
import '../services/core/logger_service.dart';

class ClassifiedsProvider extends ChangeNotifier {
  final ClassifiedsService _service;
  final ClassifiedSubscriptionsService _subService;

  ClassifiedsProvider({
    ClassifiedsService? service,
    ClassifiedSubscriptionsService? subscriptionService,
  })  : _service = service ?? ClassifiedsService(),
        _subService = subscriptionService ?? ClassifiedSubscriptionsService();

  List<ClassifiedCategoryModel> _categories =
      List.from(ClassifiedCategoryModel.fallbackCategories)
        ..sort(ClassifiedCategoryModel.compareCategories);
  List<ClassifiedAdModel> _ads = [];
  List<ClassifiedSubscriptionModel> _subscriptions = [];
  bool _subscriptionsLoaded = false;
  bool _categoriesLoaded = false;
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _requestSeq = 0;

  String? _selectedCategoryId;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedCondition;
  String? _selectedSellerType;
  String? _searchQuery;
  double? _minPrice;
  double? _maxPrice;
  ClassifiedSort _sort = ClassifiedSort.newest;
  Map<String, dynamic> _selectedAttributes = {};
  bool _onlyFeatured = false;
  bool _onlyUrgent = false;
  static const int _pageSize = 24;

  List<ClassifiedCategoryModel> get categories => _categories;
  List<ClassifiedAdModel> get ads => _ads;
  bool get categoriesLoaded => _categoriesLoaded;
  bool get loading => _loading;
  /// True during pull-to-refresh when existing data is already shown.
  bool get refreshing => _refreshing;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCity => _selectedCity;
  String? get selectedDistrict => _selectedDistrict;
  String? get selectedCondition => _selectedCondition;
  String? get selectedSellerType => _selectedSellerType;
  String? get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  ClassifiedSort get sort => _sort;
  Map<String, dynamic> get selectedAttributes =>
      Map.unmodifiable(_selectedAttributes);
  bool get onlyFeatured => _onlyFeatured;
  bool get onlyUrgent => _onlyUrgent;
  List<ClassifiedSubscriptionModel> get subscriptions => _subscriptions;
  bool get subscriptionsLoaded => _subscriptionsLoaded;


  bool isCategorySubscribed(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return false;
    return _subscriptions.any((s) => s.categoryId == categoryId);
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Kategorije se učitavaju jednom po sesiji; osvežavaju se preko refresh().
    if (_categoriesLoaded && !forceRefresh) return;

    // 1. Instant start iz lokalnog keša (offline spremnost i brzina)
    if (!forceRefresh) {
      try {
        final cached = await _service.getCachedCategories();
        if (cached.isNotEmpty) {
          _categories = cached;
          _categoriesLoaded = true;
          notifyListeners();
        }
      } catch (e, st) {
        LoggerService.debug('getCachedCategories error',
            extra: {'error': e.toString(), 'stackTrace': st.toString()});
      }
    }

    // 2. Učitavanje i sinhronizacija sa bazom (forceRefresh invalidira TTL keš)
    try {
      final items = await _service.getCategories(forceRefresh: forceRefresh);
      if (items.isNotEmpty) {
        items.sort(ClassifiedCategoryModel.compareCategories);
        _categories = items;
        _categoriesLoaded = true;
        notifyListeners();
      }
    } catch (e, st) {
      LoggerService.error('loadCategories error', e, stackTrace: st);
      if (_categories.isEmpty) {
        final fallback = List<ClassifiedCategoryModel>.from(
            ClassifiedCategoryModel.fallbackCategories)
          ..sort(ClassifiedCategoryModel.compareCategories);
        _categories = fallback;
        notifyListeners();
      }
    }

    // 3. Učitavanje brojača oglasa u pozadini (asinhrono bez blokiranja prikaza)
    unawaited(loadCategoryAdCounts());
  }

  /// Rekurzivno izračunava i dodeljuje adCount kroz celo stablo kategorija.
  /// Svaki roditelj dobija zbir svojih direktnih oglasa i svih podkategorija.
  static List<ClassifiedCategoryModel> applyAdCountsToTree(
    List<ClassifiedCategoryModel> nodes,
    Map<String, int> directCounts,
  ) {
    ClassifiedCategoryModel processNode(ClassifiedCategoryModel node) {
      final updatedSubcategories = node.subcategories.map(processNode).toList();
      final subTotal = updatedSubcategories.fold<int>(0, (sum, c) => sum + c.adCount);
      final total = (directCounts[node.id] ?? 0) + subTotal;
      return node.copyWith(
        subcategories: updatedSubcategories,
        adCount: total,
      );
    }

    return nodes.map(processNode).toList();
  }

  /// Dobavlja brojače oglasa iz servisa i primenjuje ih na trenutno stablo kategorija.
  Future<void> loadCategoryAdCounts() async {
    try {
      final counts = await _service.getCategoryAdCounts();
      if (counts.isNotEmpty && _categories.isNotEmpty) {
        _categories = applyAdCountsToTree(_categories, counts);
        notifyListeners();
      }
    } catch (e) {
      LoggerService.warning('loadCategoryAdCounts error', extra: {'error': e.toString()});
    }
  }

  /// Returns the path of categories from root to the selected category (e.g. [Root, Sub2, Sub3]).
  List<ClassifiedCategoryModel> get categoryBreadcrumbs {
    if (_selectedCategoryId == null) return const [];
    final path = <ClassifiedCategoryModel>[];
    _findCategoryPath(_selectedCategoryId!, _categories, path);
    return path;
  }

  bool _findCategoryPath(
    String targetId,
    List<ClassifiedCategoryModel> nodes,
    List<ClassifiedCategoryModel> currentPath,
  ) {
    for (final node in nodes) {
      currentPath.add(node);
      if (node.id == targetId) return true;
      if (_findCategoryPath(targetId, node.subcategories, currentPath)) {
        return true;
      }
      currentPath.removeLast();
    }
    return false;
  }

  /// Rekurzivno pronalazi kategoriju po ID-u u stablu kategorija.
  ClassifiedCategoryModel? findCategory(String targetId) {
    return _findCategoryNode(targetId, _categories);
  }

  /// Returns the root category corresponding to the selected category (if any).
  ClassifiedCategoryModel? get activeRootCategory {
    final crumbs = categoryBreadcrumbs;
    return crumbs.isNotEmpty ? crumbs.first : null;
  }

  /// Returns the secondary category corresponding to the selected category (if any).
  ClassifiedCategoryModel? get activeSecondaryCategory {
    final crumbs = categoryBreadcrumbs;
    return crumbs.length >= 2 ? crumbs[1] : null;
  }

  /// Returns the tertiary category corresponding to the selected category (if any).
  ClassifiedCategoryModel? get activeTertiaryCategory {
    final crumbs = categoryBreadcrumbs;
    return crumbs.length >= 3 ? crumbs[2] : null;
  }

  /// Da li je stanje ("Novo" / "Polovno") primenjivo za trenutno izabranu kategoriju
  bool get isConditionApplicableForSelectedCategory {
    if (_selectedCategoryId == null) return true;
    final crumbs = categoryBreadcrumbs;
    if (crumbs.isNotEmpty) {
      final leaf = crumbs.last;
      return leaf.isConditionApplicable;
    }
    return ClassifiedAdModel.isConditionApplicableForCategory(
      categoryId: _selectedCategoryId,
    );
  }

  ClassifiedCategoryModel? _findCategoryNode(
    String id,
    List<ClassifiedCategoryModel> nodes,
  ) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findCategoryNode(id, node.subcategories);
      if (found != null) return found;
    }
    return null;
  }

  void _collectAllDescendantIds(ClassifiedCategoryModel cat, Set<String> result) {
    result.add(cat.id);
    for (final sub in cat.subcategories) {
      _collectAllDescendantIds(sub, result);
    }
  }

  List<String>? _resolveCategoryIds() {
    if (_selectedCategoryId == null) return null;

    final node = _findCategoryNode(_selectedCategoryId!, _categories);
    if (node == null) return [_selectedCategoryId!];

    final ids = <String>{};
    _collectAllDescendantIds(node, ids);
    return ids.toList();
  }

  Future<void> loadInitialAds() async {
    // Race-safety: svako menjanje filtera/pretrage pokreće novi zahtev.
    // Samo poslednji zahtev sme da upiše rezultate (request token).
    final requestId = ++_requestSeq;

    // If we already have data, use a subtle refresh indicator instead of
    // the full-screen spinner so categories remain visible.
    if (_ads.isNotEmpty) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      final catIds = _resolveCategoryIds();
      List<String>? districtCities;
      if (_selectedDistrict != null) {
        final dist = SerbianDistricts.findDistrictById(_selectedDistrict!);
        if (dist != null) {
          districtCities = dist.cities;
        }
      }

      final items = await _service.getAds(
        categoryIds: catIds,
        city: _selectedCity,
        cities: districtCities,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        condition: _selectedCondition,
        sellerType: _selectedSellerType,
        searchQuery: _searchQuery,
        attributeFilters:
            _selectedAttributes.isNotEmpty ? _selectedAttributes : null,
        onlyFeatured: _onlyFeatured ? true : null,
        onlyUrgent: _onlyUrgent ? true : null,
        sort: _sort,
        limit: _pageSize,
        offset: 0,
      );

      if (requestId != _requestSeq) return; // stari odgovor – ignoriši
      _ads = items;
      _hasMore = items.length >= _pageSize;
    } catch (e, st) {
      if (requestId != _requestSeq) return;
      LoggerService.error('loadInitialAds error', e, stackTrace: st);
      _error = 'Greška pri učitavanju oglasa.';
    } finally {
      if (requestId == _requestSeq) {
        _loading = false;
        _refreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestSeq; // čitamo tekući; loadInitialAds povećava brojač
    _loadingMore = true;
    notifyListeners();

    try {
      final catIds = _resolveCategoryIds();
      List<String>? districtCities;
      if (_selectedDistrict != null) {
        final dist = SerbianDistricts.findDistrictById(_selectedDistrict!);
        if (dist != null) {
          districtCities = dist.cities;
        }
      }

      final lastCreatedAt = (_sort == ClassifiedSort.newest && _ads.isNotEmpty)
          ? _ads.last.createdAt
          : null;
      final nextItems = await _service.getAds(
        categoryIds: catIds,
        city: _selectedCity,
        cities: districtCities,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        condition: _selectedCondition,
        sellerType: _selectedSellerType,
        searchQuery: _searchQuery,
        attributeFilters:
            _selectedAttributes.isNotEmpty ? _selectedAttributes : null,
        onlyFeatured: _onlyFeatured ? true : null,
        onlyUrgent: _onlyUrgent ? true : null,
        sort: _sort,
        limit: _pageSize,
        offset: _ads.length,
        lastCreatedAt: lastCreatedAt,
      );

      if (requestId != _requestSeq) return; // filter se promenio – odbaci
      _ads = [..._ads, ...nextItems];
      _hasMore = nextItems.length >= _pageSize;
    } catch (e, st) {
      // Ne rušimo postojeću listu, ali beležimo grešku
      LoggerService.warning('loadMoreAds error',
          extra: {'error': e.toString(), 'stackTrace': st.toString()});
    } finally {
      _loadingMore = false;
      if (requestId == _requestSeq) {
        notifyListeners();
      }
    }
  }

  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _selectedAttributes = {};
    if (!isConditionApplicableForSelectedCategory && _selectedCondition != null) {
      _selectedCondition = null;
    }
    loadInitialAds();
  }

  void setAttributeFilter(String key, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      removeAttributeFilter(key);
      return;
    }
    _selectedAttributes = Map<String, dynamic>.from(_selectedAttributes);
    _selectedAttributes[key] = value;
    loadInitialAds();
  }

  void removeAttributeFilter(String key) {
    if (!_selectedAttributes.containsKey(key)) return;
    _selectedAttributes = Map<String, dynamic>.from(_selectedAttributes);
    _selectedAttributes.remove(key);
    loadInitialAds();
  }

  void clearAttributeFilters() {
    if (_selectedAttributes.isEmpty && !_onlyFeatured && !_onlyUrgent) return;
    _selectedAttributes = {};
    _onlyFeatured = false;
    _onlyUrgent = false;
    loadInitialAds();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _selectedCity = null;
    _selectedDistrict = null;
    _selectedCondition = null;
    _selectedSellerType = null;
    _searchQuery = null;
    _minPrice = null;
    _maxPrice = null;
    _selectedAttributes = {};
    _onlyFeatured = false;
    _onlyUrgent = false;
    _sort = ClassifiedSort.newest;
    loadInitialAds();
  }

  void setOnlyFeatured(bool value) {
    if (_onlyFeatured == value) return;
    _onlyFeatured = value;
    loadInitialAds();
  }

  void setOnlyUrgent(bool value) {
    if (_onlyUrgent == value) return;
    _onlyUrgent = value;
    loadInitialAds();
  }

  Future<void> toggleAdFeatured(String adId, bool isFeatured, {DateTime? until}) async {
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx >= 0) {
      _ads[idx] = _ads[idx].copyWith(
        isFeatured: isFeatured,
        featuredUntil: until,
      );
      notifyListeners();
    }
    try {
      await _service.updateAdFeatured(adId, isFeatured, until: until);
    } catch (e) {
      if (idx >= 0) {
        _ads[idx] = _ads[idx].copyWith(isFeatured: !isFeatured);
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> toggleAdUrgent(String adId, bool isUrgent) async {
    final idx = _ads.indexWhere((a) => a.id == adId);
    if (idx >= 0) {
      _ads[idx] = _ads[idx].copyWith(isUrgent: isUrgent);
      notifyListeners();
    }
    try {
      await _service.updateAdUrgent(adId, isUrgent);
    } catch (e) {
      if (idx >= 0) {
        _ads[idx] = _ads[idx].copyWith(isUrgent: !isUrgent);
        notifyListeners();
      }
      rethrow;
    }
  }

  void selectCity(String? city) {
    if (_selectedCity == city && _selectedDistrict == null) return;
    _selectedCity = city;
    _selectedDistrict = null;
    loadInitialAds();
  }

  void selectDistrict(String? districtId) {
    if (_selectedDistrict == districtId && _selectedCity == null) return;
    _selectedDistrict = districtId;
    _selectedCity = null;
    loadInitialAds();
  }

  void setPriceRange({double? minPrice, double? maxPrice}) {
    if (_minPrice == minPrice && _maxPrice == maxPrice) return;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    loadInitialAds();
  }

  void clearAllFilters() {
    _selectedCategoryId = null;
    _selectedCity = null;
    _selectedDistrict = null;
    _selectedCondition = null;
    _selectedSellerType = null;
    _searchQuery = null;
    _minPrice = null;
    _maxPrice = null;
    _selectedAttributes = {};
    _onlyFeatured = false;
    _onlyUrgent = false;
    loadInitialAds();
  }

  void selectCondition(String? condition) {
    if (_selectedCondition == condition) return;
    _selectedCondition = condition;
    loadInitialAds();
  }

  void selectSellerType(String? sellerType) {
    if (_selectedSellerType == sellerType) return;
    _selectedSellerType = sellerType;
    loadInitialAds();
  }

  void search(String? query) {
    _searchQuery = query;
    loadInitialAds();
  }

  void changeSort(ClassifiedSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    loadInitialAds();
  }

  int _subscriptionsSession = 0;

  Future<void> loadSubscriptions() async {
    final session = ++_subscriptionsSession;
    try {
      final list = await _subService.getSubscriptions();
      if (session != _subscriptionsSession) return;
      _subscriptions = list;
      _subscriptionsLoaded = true;
      notifyListeners();
    } catch (e) {
      if (session != _subscriptionsSession) return;
      LoggerService.warning('loadSubscriptions error',
          extra: {'error': e.toString()});
    }
  }

  Future<bool> toggleCategorySubscription({
    required String categoryId,
    String? searchQuery,
    double? maxPrice,
    String currency = 'EUR',
  }) async {
    final existingIndex =
        _subscriptions.indexWhere((s) => s.categoryId == categoryId);
    if (existingIndex >= 0) {
      final sub = _subscriptions[existingIndex];
      _subscriptions = List.from(_subscriptions)..removeAt(existingIndex);
      notifyListeners();
      try {
        await _subService.unsubscribe(sub.id);
        return false; // unsubscribed
      } catch (e) {
        _subscriptions = List.from(_subscriptions)..insert(existingIndex, sub);
        notifyListeners();
        rethrow;
      }
    } else {
      try {
        final newSub = await _subService.subscribe(
          categoryId: categoryId,
          searchQuery: searchQuery,
          maxPrice: maxPrice,
          currency: currency,
        );
        _subscriptions = [newSub, ..._subscriptions];
        notifyListeners();
        return true; // subscribed
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> removeSubscription(String subscriptionId) async {
    final existingIndex =
        _subscriptions.indexWhere((s) => s.id == subscriptionId);
    if (existingIndex < 0) return;
    final sub = _subscriptions[existingIndex];
    _subscriptions = List.from(_subscriptions)..removeAt(existingIndex);
    notifyListeners();
    try {
      await _subService.unsubscribe(subscriptionId);
    } catch (e) {
      _subscriptions = List.from(_subscriptions)..insert(existingIndex, sub);
      notifyListeners();
      rethrow;
    }
  }

  void clearSubscriptions() {
    _subscriptionsSession++;
    _subscriptions = [];
    _subscriptionsLoaded = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    // Force-reload categories in case they changed (reset guard first).
    _categoriesLoaded = false;
    await Future.wait([
      loadCategories(forceRefresh: true),
      loadInitialAds(),
      loadSubscriptions(),
    ]);
  }
}
