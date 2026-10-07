import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../widgets/search/search_widgets.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/location_provider.dart';
import '../utils/image_precache_utils.dart';
import '../widgets/search/search_filter_bar.dart';
import '../widgets/search/search_filter_sidebar.dart';
import '../widgets/search/search_history_panel.dart';
import '../widgets/search/search_input_app_bar.dart';
import '../widgets/search/search_mobile_categories.dart';
import '../widgets/search/search_results_grid.dart';
import '../widgets/search/search_tips_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final categoriesProvider = context.watch<CategoriesProvider>();
    final topCategories = categoriesProvider.topCategories;
    _scheduleCategoryCountReload(topCategories);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final hasActiveFilters =
        _category != null || _region != null || _availableNow == true;
    final mobileResultsAsGrid = isSmallTablet || isLargeTablet;
    final stackedResultColumns = isLargeTablet ? 3 : 2;
    final stackedGridExtent = isLargeTablet ? 336.0 : 348.0;
    final stackedGridSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 12,
      smallTabletValue: 12,
      largeTabletValue: 14,
      desktop: 14,
    );
    final wideGridColumns = Breakpoints.isDesktop(context) ? 4 : 3;
    final wideGridExtent = Breakpoints.isDesktop(context) ? 380.0 : 356.0;
    final isDesktopOrWeb = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          _searchFocusNode.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.slash): () {
          if (!_searchFocusNode.hasFocus) {
            _searchFocusNode.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_searchController.text.isNotEmpty) {
            _searchController.clear();
            _applySearchImmediate('');
          } else {
            _searchFocusNode.unfocus();
          }
        },
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: SearchInputAppBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          isDesktopOrWeb: isDesktopOrWeb,
          onClear: () {
            _searchController.clear();
            _applySearchImmediate('');
          },
          onSubmitted: (q) async {
            await _searchHistoryService.addToHistory(q);
            if (!mounted) return;
            setState(() {
              _historyFuture = _searchHistoryService.getHistory();
            });
            _applySearchImmediate(q);
          },
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTwoPaneLayout
                  ? Breakpoints.dataContentWidth(context)
                  : Breakpoints.maxContentWidth(context),
            ),
            child: isTwoPaneLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 20,
                        child: SearchFilterSidebar(
                          sort: _sort,
                          onSortChanged: (s) {
                            setState(() => _sort = s);
                            _onFilterChanged();
                          },
                          region: _region,
                          onRegionChanged: (r) {
                            setState(() => _region = r);
                            _onFilterChanged();
                          },
                          availableNow: _availableNow,
                          onAvailableNowChanged: (a) {
                            setState(() => _availableNow = a);
                            _onFilterChanged();
                          },
                          categories: topCategories,
                          selectedCategory: _category,
                          categoryCounts: _categoryCounts,
                          onCategorySelected: (cat) {
                            setState(() => _category = cat);
                            _onFilterChanged();
                          },
                        ),
                      ),
                      Expanded(
                        flex: 80,
                        child: Column(
                          children: [
                            if (_debounceTimer?.isActive == true ||
                                _filterDebounceTimer?.isActive == true)
                              const LinearProgressIndicator(minHeight: 2),
                            SearchHistoryPanel(
                              historyFuture: _historyFuture,
                              isSearchEmpty: _searchController.text.isEmpty,
                              onClearAll: () async {
                                await _searchHistoryService.clearHistory();
                                if (mounted) {
                                  setState(() {
                                    _historyFuture =
                                        _searchHistoryService.getHistory();
                                  });
                                }
                              },
                              onSelectHistory: (h) {
                                _searchController.text = h;
                                _applySearchImmediate(h);
                              },
                              onRemoveHistory: (h) async {
                                await _searchHistoryService
                                    .removeFromHistory(h);
                                if (mounted) {
                                  setState(() {
                                    _historyFuture =
                                        _searchHistoryService.getHistory();
                                  });
                                }
                              },
                            ),
                            if (hasActiveFilters)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: contentPadding,
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _category = null;
                                        _region = null;
                                        _availableNow = null;
                                      });
                                      _onFilterChanged();
                                    },
                                    icon: const Icon(Icons.clear_all_rounded,
                                        size: 18),
                                    label: const Text('Očisti filtere'),
                                  ),
                                ),
                              ),
                            SearchTipsBanner(
                              margin: EdgeInsets.symmetric(
                                horizontal: contentPadding,
                                vertical: 4,
                              ),
                            ),
                            Expanded(
                              child: SearchResultsGrid(
                                products: _products,
                                loading: _loading,
                                loadingMore: _loadingMore,
                                searchError: _searchError,
                                scrollController: _scrollController,
                                onRefresh: _onRefresh,
                                onRetry: _loadFirstPage,
                                itemBuilder: (ctx, i) => SearchProductCard(
                                    screen: this, i: i, user: user),
                                emptyStateWidget:
                                    SearchEmptyState(screen: this),
                                crossAxisCount: wideGridColumns,
                                mainAxisExtent: wideGridExtent,
                                spacing: stackedGridSpacing,
                                contentPadding: contentPadding,
                                asGrid: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      if (_debounceTimer?.isActive == true ||
                          _filterDebounceTimer?.isActive == true)
                        const LinearProgressIndicator(minHeight: 2),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentPadding,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategorije',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SearchMobileCategories(
                              categories: topCategories,
                              selectedCategory: _category,
                              categoryCounts: _categoryCounts,
                              onCategorySelected: (cat) {
                                setState(() => _category = cat);
                                _onFilterChanged();
                              },
                            ),
                          ],
                        ),
                      ),
                      SearchHistoryPanel(
                        historyFuture: _historyFuture,
                        isSearchEmpty: _searchController.text.isEmpty,
                        onClearAll: () async {
                          await _searchHistoryService.clearHistory();
                          if (mounted) {
                            setState(() {
                              _historyFuture =
                                  _searchHistoryService.getHistory();
                            });
                          }
                        },
                        onSelectHistory: (h) {
                          _searchController.text = h;
                          _applySearchImmediate(h);
                        },
                        onRemoveHistory: (h) async {
                          await _searchHistoryService.removeFromHistory(h);
                          if (mounted) {
                            setState(() {
                              _historyFuture =
                                  _searchHistoryService.getHistory();
                            });
                          }
                        },
                      ),
                      SearchFilterBar(
                        sort: _sort,
                        onSortChanged: (s) {
                          setState(() => _sort = s);
                          _onFilterChanged();
                        },
                        region: _region,
                        onRegionChanged: (r) {
                          setState(() => _region = r);
                          _onFilterChanged();
                        },
                        availableNow: _availableNow,
                        onAvailableNowChanged: (a) {
                          setState(() => _availableNow = a);
                          _onFilterChanged();
                        },
                      ),
                      if (hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _category = null;
                                  _region = null;
                                  _availableNow = null;
                                });
                                _onFilterChanged();
                              },
                              icon:
                                  const Icon(Icons.clear_all_rounded, size: 18),
                              label: const Text('Očisti filtere'),
                            ),
                          ),
                        ),
                      SearchTipsBanner(
                        margin: EdgeInsets.symmetric(
                          horizontal: contentPadding,
                          vertical: 4,
                        ),
                      ),
                      Expanded(
                        child: SearchResultsGrid(
                          products: _products,
                          loading: _loading,
                          loadingMore: _loadingMore,
                          searchError: _searchError,
                          scrollController: _scrollController,
                          onRefresh: _onRefresh,
                          onRetry: _loadFirstPage,
                          itemBuilder: (ctx, i) =>
                              SearchProductCard(screen: this, i: i, user: user),
                          emptyStateWidget: SearchEmptyState(screen: this),
                          crossAxisCount:
                              mobileResultsAsGrid ? stackedResultColumns : 2,
                          mainAxisExtent:
                              mobileResultsAsGrid ? stackedGridExtent : 255,
                          spacing: stackedGridSpacing,
                          contentPadding: contentPadding,
                          asGrid: mobileResultsAsGrid,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
