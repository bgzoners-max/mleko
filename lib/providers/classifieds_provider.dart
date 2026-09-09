import 'package:flutter/foundation.dart';

import '../models/classified_ad_model.dart';
import '../models/classified_category_model.dart';
import '../services/classifieds/classifieds_service.dart';

class ClassifiedsProvider extends ChangeNotifier {
  final ClassifiedsService _service;

  ClassifiedsProvider({ClassifiedsService? service})
      : _service = service ?? ClassifiedsService();

  List<ClassifiedCategoryModel> _categories =
      List.from(ClassifiedCategoryModel.fallbackCategories)
        ..sort(ClassifiedCategoryModel.compareCategories);
  List<ClassifiedAdModel> _ads = [];
  bool _categoriesLoaded = false;
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _requestSeq = 0;

  String? _selectedCategoryId;
  String? _selectedCity;
  String? _searchQuery;
  ClassifiedSort _sort = ClassifiedSort.newest;
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
  String? get searchQuery => _searchQuery;
  ClassifiedSort get sort => _sort;

  Future<void> loadCategories() async {
    // Kategorije se učitavaju jednom po sesiji; osvežavaju se preko refresh().
    if (_categoriesLoaded) return;

    // 1. Instant start iz lokalnog keša (offline spremnost i brzina)
    try {
      final cached = await _service.getCachedCategories();
      if (cached.isNotEmpty) {
        _categories = cached;
        notifyListeners();
      }
    } catch (_) {}

    // 2. Učitavanje i sinhronizacija sa bazom
    try {
      final items = await _service.getCategories();
      if (items.isNotEmpty) {
        items.sort(ClassifiedCategoryModel.compareCategories);
        _categories = items;
        _categoriesLoaded = true;
        notifyListeners();
      }
    } catch (e, st) {
      debugPrint('[ClassifiedsProvider] loadCategories error: $e\n$st');
      if (_categories.isEmpty) {
        final fallback = List<ClassifiedCategoryModel>.from(
            ClassifiedCategoryModel.fallbackCategories)
          ..sort(ClassifiedCategoryModel.compareCategories);
        _categories = fallback;
        notifyListeners();
      }
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
      final items = await _service.getAds(
        categoryIds: catIds,
        city: _selectedCity,
        searchQuery: _searchQuery,
        sort: _sort,
        limit: _pageSize,
        offset: 0,
      );

      if (requestId != _requestSeq) return; // stari odgovor – ignoriši
      _ads = items;
      _hasMore = items.length >= _pageSize;
    } catch (e, st) {
      if (requestId != _requestSeq) return;
      debugPrint('[ClassifiedsProvider] loadInitialAds error: $e\n$st');
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
      final nextItems = await _service.getAds(
        categoryIds: catIds,
        city: _selectedCity,
        searchQuery: _searchQuery,
        sort: _sort,
        limit: _pageSize,
        offset: _ads.length,
      );

      if (requestId != _requestSeq) return; // filter se promenio – odbaci
      _ads = [..._ads, ...nextItems];
      _hasMore = nextItems.length >= _pageSize;
    } catch (_) {
      // Ne rušimo postojeću listu
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
    loadInitialAds();
  }

  void selectCity(String? city) {
    if (_selectedCity == city) return;
    _selectedCity = city;
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

  Future<void> refresh() async {
    // Force-reload categories in case they changed (reset guard first).
    _categoriesLoaded = false;
    await Future.wait([loadCategories(), loadInitialAds()]);
  }
}
