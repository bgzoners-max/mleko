import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/category_icon.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchHistoryService = SearchHistoryService();
  final _productsService = ProductsService();
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
  int _querySeq = 0;
  String? _searchError;
  late Future<List<String>> _historyFuture;
  String? _currentSellerIdToExclude;
  String _lastCategoryCountRequestKey = '';

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _historyFuture = _searchHistoryService.getHistory();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
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
    context.read<CategoriesProvider>().load();
    final user = context.read<AppState>().user;
    final favorites = context.read<FavoritesProvider>();
    if (user != null && !user.isGuest && !favorites.isLoaded) {
      favorites.load(user.id);
    }
    _currentSellerIdToExclude =
        (user != null && user.isSeller) ? user.id : null;
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
    setState(() {
      _loading = true;
      _searchError = null;
      _products = [];
      _offset = 0;
      _hasMore = true;
      _loadingMore = false;
    });
    try {
      final result = await _productsService.getProductsPage(
        category: _category,
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        excludeSellerId: _currentSellerIdToExclude,
        sort: _sort,
        limit: productsPageSize,
        offset: 0,
      );
      if (!mounted || querySeq != _querySeq) return;
      setState(() {
        _products = result.items;
        _salesCounts = result.salesCounts;
        _ratings = result.ratings;
        _offset = result.items.length;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || querySeq != _querySeq) return;
      setState(() {
        _loading = false;
        _searchError = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final querySeq = _querySeq;
    setState(() => _loadingMore = true);
    try {
      final result = await _productsService.getProductsPage(
        category: _category,
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        sort: _sort,
        limit: productsPageSize,
        offset: _offset,
      );
      if (!mounted) return;
      if (querySeq != _querySeq) {
        // Nove pretrage su počele dok je loadMore bio u flight-u.
        // Ne sme se dodavati rezultat starog upita.
        setState(() => _loadingMore = false);
        return;
      }
      setState(() {
        _products = [..._products, ...result.items];
        _salesCounts = {..._salesCounts, ...result.salesCounts};
        _ratings = {..._ratings, ...result.ratings};
        _offset += result.items.length;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri učitavanju više proizvoda.')),
      );
    }
  }

  Timer? _debounceTimer;
  Timer? _filterDebounceTimer;
  static const _debounceDuration = Duration(milliseconds: 350);
  static const _filterDebounceDuration = Duration(milliseconds: 250);
  String _debouncedQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _filterDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
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

    try {
      final counts = await _productsService.getCategoryCounts(
        categoryNames:
            categories.map<String>((cat) => cat.name as String).toList(),
        region: _region,
        availableNow: _availableNow,
        searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
        excludeSellerId: _currentSellerIdToExclude,
      );
      if (!mounted || requestKey != _lastCategoryCountRequestKey) return;
      setState(() => _categoryCounts = counts);
    } catch (_) {
      if (!mounted || requestKey != _lastCategoryCountRequestKey) return;
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

  Widget _buildCategoryItem(BuildContext context, dynamic cat,
      {bool fullWidth = false}) {
    final selected = _category == cat.name;
    return _CategoryPill(
      label: cat.name,
      count: _categoryCounts[cat.name],
      icon: cat.icon,
      selected: selected,
      fullWidth: fullWidth,
      onTap: () {
        setState(() => _category = selected ? null : cat.name);
        _onFilterChanged();
      },
    );
  }

  Widget _buildMobileCategories(
      BuildContext context, List<dynamic> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            _buildCategoryItem(context, categories[index]),
            if (index != categories.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryChips() {
    return FutureBuilder<List<String>>(
      future: _historyFuture,
      builder: (context, snap) {
        final history = snap.data ?? [];
        if (history.isEmpty) return const SizedBox.shrink();
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Istorija:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 8),
              ...history.take(5).map((h) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(h, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _searchController.text = h;
                        _applySearchImmediate(h);
                      },
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Sortiraj',
            value: _sort.label,
            options: ProductSort.values.map((s) => s.label).toList(),
            onSelected: (v) {
              final idx = ProductSort.values.indexWhere((s) => s.label == v);
              if (idx >= 0) {
                setState(() {
                  _sort = ProductSort.values[idx];
                  _onFilterChanged();
                });
              }
            },
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Region',
            value: _region,
            options: AppConstants.regions,
            onSelected: (v) {
              setState(() => _region = v);
              _onFilterChanged();
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            label: const Text('Dostupno sada'),
            onPressed: () {
              setState(
                  () => _availableNow = _availableNow == true ? null : true);
              _onFilterChanged();
            },
            backgroundColor: _availableNow == true
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, int i, dynamic user) {
    final p = _products[i];
    final rating = _ratings[p.id];
    return user != null && !user.isGuest
        ? Selector<FavoritesProvider, bool>(
            selector: (_, fav) => fav.isFavorite(p.id),
            builder: (_, isFavorite, __) {
              final favorites = context.read<FavoritesProvider>();
              return ProductCard(
                product: p,
                isFavorite: isFavorite,
                onFavoriteToggle: () => favorites.toggle(user.id, p.id),
                isPopular: (_salesCounts[p.id] ?? 0) >=
                    AppConstants.popularProductMinSales,
                avgRating: rating?.avg,
                reviewCount: rating?.count,
              );
            },
          )
        : ProductCard(
            product: p,
            isFavorite: null,
            onFavoriteToggle: null,
            isPopular: (_salesCounts[p.id] ?? 0) >=
                AppConstants.popularProductMinSales,
            avgRating: rating?.avg,
            reviewCount: rating?.count,
          );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _category != null || _region != null || _availableNow == true;
    final subtitle = hasFilters
        ? 'Pokušajte da uklonite aktivne filtere ili promenite pojam pretrage.'
        : 'Probajte drugi naziv ili pogledajte sve proizvode.';
    return AppEmptyState(
      icon: Icons.search_off,
      title: 'Nema rezultata za ovu pretragu',
      subtitle: subtitle,
      ctaLabel: 'Pogledaj sve proizvode',
      ctaIcon: Icons.list,
      onCtaPressed: () {
        _searchController.clear();
        setState(() {
          _category = null;
          _region = null;
          _availableNow = null;
          _debouncedQuery = '';
        });
        _loadFirstPage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final categoriesProvider = context.watch<CategoriesProvider>();
    final topCategories = categoriesProvider.topCategories.take(8).toList();
    _scheduleCategoryCountReload(topCategories);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
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

    return Scaffold(
      backgroundColor: const Color(0xFFE9E9E9),
      appBar: AppBar(
        title: const Text('Pretraga'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Traži po nazivu proizvoda…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => _onSearchChanged(v),
              onSubmitted: (q) async {
                await _searchHistoryService.addToHistory(q);
                if (!mounted) return;
                setState(() {
                  _historyFuture = _searchHistoryService.getHistory();
                });
                _applySearchImmediate(q);
              },
            ),
          ),
        ),
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
                    // Leva kolona: kategorije (15%)
                    Expanded(
                      flex: 15,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            left: Divider.createBorderSide(context),
                          ),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('Kategorije',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            ...topCategories.map(
                              (cat) => Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                child: _buildCategoryItem(context, cat,
                                    fullWidth: true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: Color(0xFFD0D0D0)),
                    // Desna kolona: filteri + rezultati (85%)
                    Expanded(
                      flex: 85,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            right: Divider.createBorderSide(context),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildHistoryChips(),
                            _buildFilterChips(context),
                            Expanded(
                              child: _loading
                                  ? const ProductListSkeleton()
                                  : _products.isEmpty
                                      ? _buildEmptyState()
                                      : RefreshIndicator(
                                          onRefresh: _onRefresh,
                                          child: GridView.builder(
                                            controller: _scrollController,
                                            padding: EdgeInsets.all(
                                              contentPadding,
                                            ),
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: wideGridColumns,
                                              crossAxisSpacing:
                                                  stackedGridSpacing,
                                              mainAxisSpacing:
                                                  stackedGridSpacing,
                                              mainAxisExtent: wideGridExtent,
                                            ),
                                            itemCount: _products.length +
                                                (_loadingMore ? 4 : 0),
                                            itemBuilder: (_, i) {
                                              if (i >= _products.length) {
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2));
                                              }
                                              return _buildProductCard(
                                                  context, i, user);
                                            },
                                          ),
                                        ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // Kategorije grid (mobile)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: contentPadding,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kategorije',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildMobileCategories(context, topCategories),
                        ],
                      ),
                    ),
                    _buildHistoryChips(),
                    _buildFilterChips(context),
                    Expanded(
                      child: _loading
                          ? const ProductListSkeleton()
                          : _searchError != null
                              ? AppErrorRetry(
                                  message: 'Greška pri učitavanju proizvoda.',
                                  detail: _searchError,
                                  onRetry: _loadFirstPage,
                                )
                              : _products.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: _onRefresh,
                                      child: mobileResultsAsGrid
                                          ? GridView.builder(
                                              controller: _scrollController,
                                              padding: EdgeInsets.all(
                                                contentPadding,
                                              ),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    stackedResultColumns,
                                                crossAxisSpacing:
                                                    stackedGridSpacing,
                                                mainAxisSpacing:
                                                    stackedGridSpacing,
                                                mainAxisExtent:
                                                    stackedGridExtent,
                                              ),
                                              itemCount: _products.length +
                                                  (_loadingMore ? 2 : 0),
                                              itemBuilder: (_, i) {
                                                if (i >= _products.length) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                }
                                                return _buildProductCard(
                                                    context, i, user);
                                              },
                                            )
                                          : ListView.builder(
                                              controller: _scrollController,
                                              padding: EdgeInsets.all(
                                                contentPadding,
                                              ),
                                              itemCount: _products.length +
                                                  (_loadingMore ? 1 : 0),
                                              itemBuilder: (_, i) {
                                                if (i == _products.length) {
                                                  return const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 16),
                                                    child: Center(
                                                        child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    )),
                                                  );
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 16),
                                                  child: _buildProductCard(
                                                      context, i, user),
                                                );
                                              },
                                            ),
                                    ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatefulWidget {
  final String label;
  final int? count;
  final String? icon;
  final bool selected;
  final bool fullWidth;
  final VoidCallback onTap;

  const _CategoryPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.fullWidth,
    required this.onTap,
  });

  @override
  State<_CategoryPill> createState() => _CategoryPillState();
}

class _CategoryPillState extends State<_CategoryPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1F5A3B);
    final selected = widget.selected;
    final hasCount = widget.count != null;
    final foregroundColor = selected ? Colors.white : const Color(0xFF244030);
    final backgroundColor = selected
        ? activeColor
        : (_hovered ? const Color(0xFFE6F0E9) : Colors.white);
    final borderColor = selected
        ? activeColor
        : (_hovered ? const Color(0xFF7FA489) : const Color(0xFFD6E1D9));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.fullWidth ? 14 : 16,
              vertical: widget.fullWidth ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: _hovered || selected
                  ? [
                      BoxShadow(
                        color: selected
                            ? activeColor.withValues(alpha: 0.24)
                            : const Color(0x1A244030),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                buildCategoryIcon(
                  widget.icon,
                  size: 18,
                  color: foregroundColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: widget.fullWidth ? 1 : 0,
                  child: Text(
                    hasCount
                        ? '${widget.label} (${widget.count})'
                        : widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  const _FilterChip(
      {required this.label,
      required this.value,
      required this.options,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      tooltip: label,
      child: Chip(
        label: Text(value ?? label),
        avatar: value != null
            ? const Icon(Icons.close, size: 18, color: Colors.white)
            : null,
        onDeleted: value != null ? () => onSelected(null) : null,
      ),
      itemBuilder: (_) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
    );
  }
}
