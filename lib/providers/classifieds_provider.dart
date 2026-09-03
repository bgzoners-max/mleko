import 'package:flutter/foundation.dart';

import '../models/classified_ad_model.dart';
import '../models/classified_category_model.dart';
import '../services/classifieds/classifieds_service.dart';

class ClassifiedsProvider extends ChangeNotifier {
  final ClassifiedsService _service;

  ClassifiedsProvider({ClassifiedsService? service})
      : _service = service ?? ClassifiedsService();

  List<ClassifiedCategoryModel> _categories = [];
  List<ClassifiedAdModel> _ads = [];
  bool _categoriesLoaded = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  String? _selectedCategoryId;
  String? _selectedCity;
  String? _searchQuery;
  ClassifiedSort _sort = ClassifiedSort.newest;
  static const int _pageSize = 24;

  List<ClassifiedCategoryModel> get categories => _categories;
  List<ClassifiedAdModel> get ads => _ads;
  bool get categoriesLoaded => _categoriesLoaded;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCity => _selectedCity;
  String? get searchQuery => _searchQuery;
  ClassifiedSort get sort => _sort;

  Future<void> loadCategories() async {
    if (_categoriesLoaded) return;
    try {
      _categories = await _service.getCategories();
      _categoriesLoaded = true;
      notifyListeners();
    } catch (_) {
      // Tihi fallback
    }
  }

  Future<void> loadInitialAds() async {
    _loading = true;
    _error = null;
    _hasMore = true;
    notifyListeners();

    try {
      final items = await _service.getAds(
        categoryId: _selectedCategoryId,
        city: _selectedCity,
        searchQuery: _searchQuery,
        sort: _sort,
        limit: _pageSize,
        offset: 0,
      );

      _ads = items;
      _hasMore = items.length >= _pageSize;
    } catch (e) {
      _error = 'Greška pri učitavanju oglasa.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final nextItems = await _service.getAds(
        categoryId: _selectedCategoryId,
        city: _selectedCity,
        searchQuery: _searchQuery,
        sort: _sort,
        limit: _pageSize,
        offset: _ads.length,
      );

      _ads = [..._ads, ...nextItems];
      _hasMore = nextItems.length >= _pageSize;
    } catch (_) {
      // Ne rušimo postojeću listu
    } finally {
      _loadingMore = false;
      notifyListeners();
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
    await loadCategories();
    await loadInitialAds();
  }
}
