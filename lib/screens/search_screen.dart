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

  List<ProductModel> _products = [];
  int _offset = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _querySeq = 0;
  late Future<List<String>> _historyFuture;

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
      _products = [];
      _offset = 0;
      _hasMore = true;
      _loadingMore = false;
    });
    final result = await _productsService.getProductsPage(
      category: _category,
      region: _region,
      availableNow: _availableNow,
      searchQuery: _debouncedQuery.isEmpty ? null : _debouncedQuery,
      sort: _sort,
      limit: productsPageSize,
      offset: 0,
    );
    if (!mounted || querySeq != _querySeq) return;
    {
      setState(() {
        _products = result.items;
        _salesCounts = result.salesCounts;
        _ratings = result.ratings;
        _offset = result.items.length;
        _hasMore = result.hasMore;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    final querySeq = _querySeq;
    setState(() => _loadingMore = true);
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
      setState(() {
        _loadingMore = false;
      });
      return;
    }
    {
      setState(() {
        _products = [..._products, ...result.items];
        _salesCounts = {..._salesCounts, ...result.salesCounts};
        _ratings = {..._ratings, ...result.ratings};
        _offset += result.items.length;
        _hasMore = result.hasMore;
        _loadingMore = false;
      });
    }
  }

  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 350);
  String _debouncedQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final categoriesProvider = context.watch<CategoriesProvider>();
    final topCategories = categoriesProvider.topCategories.take(8).toList();
    final isWide = Breakpoints.isDesktop(context);

    return Scaffold(
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
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child: Column(
            children: [
              // Kategorije section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategorije',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 5 : 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: isWide ? 1.0 : 0.9,
                      children: topCategories
                          .map((cat) => InkWell(
                                onTap: () {
                                  setState(() => _category = cat.name);
                                  _onFilterChanged();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    buildCategoryIcon(
                                      cat.icon,
                                      size: isWide ? 40 : 36,
                                      color: _category == cat.name
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _category == cat.name
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: _category == cat.name
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              FutureBuilder<List<String>>(
                future: _historyFuture,
                builder: (context, snap) {
                  final history = snap.data ?? [];
                  if (history.isEmpty) return const SizedBox.shrink();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Text('Istorija:',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                        const SizedBox(width: 8),
                        ...history.take(5).map((h) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(h,
                                    style: const TextStyle(fontSize: 12)),
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
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Sortiraj',
                      value: _sort.label,
                      options: ProductSort.values.map((s) => s.label).toList(),
                      onSelected: (v) {
                        final idx =
                            ProductSort.values.indexWhere((s) => s.label == v);
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
                        setState(() => _availableNow =
                            _availableNow == true ? null : true);
                        _onFilterChanged();
                      },
                      backgroundColor: _availableNow == true
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const ProductListSkeleton()
                    : Builder(
                        builder: (context) {
                          if (_products.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.search_off,
                              title: 'Nema rezultata za ovu pretragu',
                              subtitle:
                                  'Probajte drugi naziv, filter kategorije ili pogledajte sve proizvode.',
                              ctaLabel: 'Pogledaj sve proizvode',
                              ctaIcon: Icons.list,
                              onCtaPressed: () {
                                _searchController.clear();
                                _category = null;
                                _region = null;
                                setState(() {});
                                _loadFirstPage();
                              },
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _products.length + (_loadingMore ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == _products.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )),
                                  );
                                }
                                final p = _products[i];
                                final rating = _ratings[p.id];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: user != null && !user.isGuest
                                      ? Selector<FavoritesProvider, bool>(
                                          selector: (_, fav) =>
                                              fav.isFavorite(p.id),
                                          builder: (_, isFavorite, __) {
                                            final favorites = context
                                                .read<FavoritesProvider>();
                                            return ProductCard(
                                              product: p,
                                              isFavorite: isFavorite,
                                              onFavoriteToggle: () => favorites
                                                  .toggle(user.id, p.id),
                                              isPopular: (_salesCounts[p.id] ??
                                                      0) >=
                                                  AppConstants
                                                      .popularProductMinSales,
                                              avgRating: rating?.avg,
                                              reviewCount: rating?.count,
                                            );
                                          },
                                        )
                                      : ProductCard(
                                          product: p,
                                          isFavorite: null,
                                          onFavoriteToggle: null,
                                          isPopular:
                                              (_salesCounts[p.id] ?? 0) >=
                                                  AppConstants
                                                      .popularProductMinSales,
                                          avgRating: rating?.avg,
                                          reviewCount: rating?.count,
                                        ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
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
