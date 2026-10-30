import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/location_provider.dart';
import '../utils/image_precache_utils.dart';
import '../widgets/search/search_body_content.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategory, this.initialQuery});

  final String? initialCategory;
  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _searchHistoryService = SearchHistoryService();
  ProductsService? _productsService;
  String? _category;
  String? _region;
  bool? _availableNow;
  ProductSort _sort = ProductSort.dateDesc;
  Map<String, int> _salesCounts = {};
  Map<String, ({double avg, int count})> _ratings = {};
  Map<String, int> _categoryCounts = {};

  List<ProductModel> _products = [];
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _isInitialized = false;
  int _querySeq = 0;
  String? _searchError;
  late Future<List<String>> _historyFuture;
  String? _currentSellerIdToExclude;
  String _lastCategoryCountRequestKey = '';
  final Set<String> _preloadedImages = <String>{};

  void _warmupProductImages(List<ProductModel> products) {
    warmupProductImages(
      context: context,
      products: products,
      preloadedUrls: _preloadedImages,
      isMounted: () => mounted,
      topCountWithSecondary: 4,
      maxTotalUrls: 12,
    );
  }

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _lastSearchText = widget.initialQuery!;
    }
    _historyFuture = _searchHistoryService.getHistory();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _category = widget.initialCategory;
      _loadFirstPage();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newService = context.read<ProductsService>();
    final serviceChanged = _productsService != newService;
    _productsService = newService;

    context.read<CategoriesProvider>().load();
    final user = context.read<AppState>().user;
    final favorites = context.read<FavoritesProvider>();
    if (user != null && !user.isGuest && !favorites.isLoaded) {
      favorites.load(user.id);
    }
    _currentSellerIdToExclude = null;

    if (!_isInitialized || serviceChanged) {
      _isInitialized = true;
      final loc = context.read<LocationProvider>();
      _region ??= loc.selectedRegion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFirstPage();
      });
    }
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    final querySeq = ++_querySeq;
    final currentQuery = _debouncedQuery.trim().toLowerCase();

    setState(() {
      if (_products.isEmpty) {
        _loading = true;
      } else {
        _loadingMore = false;
      }
      _searchError = null;
      _offset = 0;
      _hasMore = true;
    });

    if (currentQuery.isNotEmpty &&
        _category == null &&
        _region == null &&
        _availableNow != true) {
      final cached = await ProductCacheService()
          .getCachedProducts(ProductCacheService.searchKey(currentQuery));
      if (cached != null &&
          cached.isNotEmpty &&
          querySeq == _querySeq &&
          mounted) {
        setState(() {
          _products = cached;
          _loading = false;
        });
      }
    }

    final resultResponse = await ErrorHandlerService().executeWithResult(
      'Search products (first page)',
      () => _productsService!.getProductsPage(
        category: _category,
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        excludeSellerId: _currentSellerIdToExclude,
        sort: _sort,
        limit: productsPageSize,
        offset: 0,
      ),
    );

    if (!mounted || querySeq != _querySeq) return;

    if (resultResponse.isSuccess) {
      final result = resultResponse.data!;
      setState(() {
        _products = result.items;
        _salesCounts = result.salesCounts;
        _ratings = result.ratings;
        _offset = result.items.length;
        _hasMore = result.hasMore;
        _loading = false;
      });
      _warmupProductImages(result.items);
    } else {
      setState(() {
        _loading = false;
        _searchError =
            resultResponse.error?.getUserMessage() ?? 'Greška pri pretrazi.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final querySeq = _querySeq;
    setState(() => _loadingMore = true);

    final resultResponse = await ErrorHandlerService().executeWithResult(
      'Search products (load more)',
      () => _productsService!.getProductsPage(
        category: _category,
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        sort: _sort,
        limit: productsPageSize,
        offset: _offset,
      ),
    );

    if (!mounted) return;
    if (querySeq != _querySeq) {
      setState(() => _loadingMore = false);
      return;
    }

    if (resultResponse.isSuccess) {
      final result = resultResponse.data!;
      setState(() {
        _products = [..._products, ...result.items];
        _salesCounts = {..._salesCounts, ...result.salesCounts};
        _ratings = {..._ratings, ...result.ratings};
        _offset += result.items.length;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
      _warmupProductImages(result.items);
    } else {
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(resultResponse.error?.getUserMessage() ??
                'Greška pri učitavanju više proizvoda.')),
      );
    }
  }

  Timer? _debounceTimer;
  Timer? _filterDebounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);
  static const _filterDebounceDuration = Duration(milliseconds: 250);
  String _debouncedQuery = '';
  String _lastSearchText = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _filterDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final value = _searchController.text;
    if (value == _lastSearchText) return;
    _lastSearchText = value;
    setState(() {
      _historyFuture = _searchHistoryService.getSuggestions(value);
    });

    if (value.trim().toLowerCase() == _debouncedQuery) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        setState(() => _debouncedQuery = value.trim().toLowerCase());
        _loadFirstPage();
      }
    });
  }

  void _applySearchImmediate(String query) {
    _debounceTimer?.cancel();
    _debouncedQuery = query.trim().toLowerCase();
    if (mounted) {
      setState(() {});
      _loadFirstPage();
    }
  }

  Future<void> _onRefresh() async {
    await _loadFirstPage();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _onFilterChanged() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(_filterDebounceDuration, () {
      if (mounted) _loadFirstPage();
    });
  }

  Future<void> _loadCategoryCounts(List<dynamic> categories,
      {required String requestKey}) async {
    if (categories.isEmpty) {
      if (mounted && requestKey == _lastCategoryCountRequestKey) {
        setState(() => _categoryCounts = {});
      }
      return;
    }

    final resultResponse = await ErrorHandlerService().executeWithResult(
      'Load category counts',
      () => _productsService!.getCategoryCounts(
        categoryNames:
            categories.map<String>((cat) => cat.name as String).toList(),
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        excludeSellerId: _currentSellerIdToExclude,
      ),
    );

    if (!mounted || requestKey != _lastCategoryCountRequestKey) return;

    if (resultResponse.isSuccess) {
      setState(() => _categoryCounts = resultResponse.data!);
    } else {
      setState(() => _categoryCounts = {});
    }
  }

  void _scheduleCategoryCountReload(List<dynamic> categories) {
    final requestKey = [
      categories.map((cat) => cat.name).join('|'),
      _region ?? '',
      _availableNow == true ? '1' : '0',
      _currentSellerIdToExclude ?? '',
      _debouncedQuery,
    ].join('::');

    if (requestKey == _lastCategoryCountRequestKey) return;
    _lastCategoryCountRequestKey = requestKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadCategoryCounts(categories, requestKey: requestKey));
    });
  }

  void _resetSearchFilters() {
    _searchController.clear();
    setState(() {
      _category = null;
      _region = null;
      _availableNow = null;
      _debouncedQuery = '';
    });
    _loadFirstPage();
  }

  void _clearActiveFilters() {
    setState(() {
      _category = null;
      _region = null;
      _availableNow = null;
    });
    _onFilterChanged();
  }

  Future<void> _clearAllHistory() async {
    await _searchHistoryService.clearHistory();
    if (mounted) {
      setState(() => _historyFuture = _searchHistoryService.getHistory());
    }
  }

  Future<void> _removeHistoryItem(String item) async {
    await _searchHistoryService.removeFromHistory(item);
    if (mounted) {
      setState(() => _historyFuture = _searchHistoryService.getHistory());
    }
  }

  void _updateFilter(VoidCallback update) {
    setState(update);
    _onFilterChanged();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final topCategories = context.watch<CategoriesProvider>().topCategories;
    _scheduleCategoryCountReload(topCategories);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final hasActiveFilters =
        _category != null || _region != null || _availableNow == true;

    return SearchBodyContent(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      onClearSearch: () {
        _searchController.clear();
        _applySearchImmediate('');
      },
      onSubmittedSearch: (q) async {
        await _searchHistoryService.addToHistory(q);
        if (!mounted) return;
        setState(() => _historyFuture = _searchHistoryService.getHistory());
        _applySearchImmediate(q);
      },
      isTwoPaneLayout: isTwoPaneLayout,
      isDebounceActive: _debounceTimer?.isActive == true ||
          _filterDebounceTimer?.isActive == true,
      sort: _sort,
      onSortChanged: (s) => _updateFilter(() => _sort = s),
      region: _region,
      onRegionChanged: (r) => _updateFilter(() => _region = r),
      availableNow: _availableNow,
      onAvailableNowChanged: (a) => _updateFilter(() => _availableNow = a),
      topCategories: topCategories,
      selectedCategory: _category,
      categoryCounts: _categoryCounts,
      onCategorySelected: (cat) => _updateFilter(() => _category = cat),
      historyFuture: _historyFuture,
      isSearchEmpty: _searchController.text.isEmpty,
      onClearAllHistory: _clearAllHistory,
      onSelectHistory: (h) {
        _searchController.text = h;
        _applySearchImmediate(h);
      },
      onRemoveHistory: _removeHistoryItem,
      hasActiveFilters: hasActiveFilters,
      onClearActiveFilters: _clearActiveFilters,
      onResetSearchFilters: _resetSearchFilters,
      products: _products,
      salesCounts: _salesCounts,
      ratings: _ratings,
      user: user,
      loading: _loading,
      loadingMore: _loadingMore,
      searchError: _searchError,
      scrollController: _scrollController,
      onRefresh: _onRefresh,
      onRetry: _loadFirstPage,
    );
  }
}
