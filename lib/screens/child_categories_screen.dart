import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/category.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';
import '../widgets/category_icon.dart';
import '../widgets/product_card.dart';
import '../widgets/skeleton.dart';

class ChildCategoriesScreen extends StatefulWidget {
  const ChildCategoriesScreen({
    super.key,
    required this.parentCategory,
  });

  final Category parentCategory;

  @override
  State<ChildCategoriesScreen> createState() => _ChildCategoriesScreenState();
}

class _ChildCategoriesScreenState extends State<ChildCategoriesScreen> {
  final _supabaseService = SupabaseService();
  ProductsService? _productsService;
  final _scrollController = ScrollController();

  List<Category> _categories = [];
  bool _loadingCategories = true;
  String? _error;

  List<ProductModel> _products = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingProducts = false;
  bool _loadingMore = false;
  final Set<String> _preloadedImages = <String>{};

  void _warmupProductImages(List<ProductModel> products) {
    final List<String> urls = [];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      if (p.imageUrls.isNotEmpty) {
        urls.add(p.imageUrls.first);
        // Za top 4 proizvoda preload-uj i drugu sliku (carousel detalji)
        if (i < 4 && p.imageUrls.length > 1) {
          urls.add(p.imageUrls[1]);
        }
      }
      if (urls.length >= 10) break;
    }
    if (urls.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final url in urls) {
        if (!mounted) return;
        if (_preloadedImages.add(url)) {
          await precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productsService ??= context.read<ProductsService>();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _error = null;
    });
    try {
      final list =
          await _supabaseService.getChildCategories(widget.parentCategory.id);
      if (mounted) {
        setState(() {
          _categories = list;
          _loadingCategories = false;
        });
        _loadInitialProducts(list);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadInitialProducts(List<Category> categories) async {
    if (categories.isEmpty) return;
    setState(() {
      _loadingProducts = true;
      _products = [];
      _offset = 0;
      _hasMore = true;
    });
    try {
      final categoryNames = categories.map((c) => c.name).toList();
      final result = await _productsService!.getProductsByCategories(
        categoryNames: categoryNames,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _products = result.items;
          _offset = result.items.length;
          _hasMore = result.hasMore;
          _loadingProducts = false;
        });
        _warmupProductImages(result.items);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri učitavanju proizvoda.')),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loadingMore || !_hasMore || _categories.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final categoryNames = _categories.map((c) => c.name).toList();
      final result = await _productsService!.getProductsByCategories(
        categoryNames: categoryNames,
        offset: _offset,
      );
      if (mounted) {
        setState(() {
          _products.addAll(result.items);
          _offset += result.items.length;
          _hasMore = result.hasMore;
          _loadingMore = false;
        });
        _warmupProductImages(result.items);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Greška pri učitavanju više proizvoda.')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    await _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parentCategory.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingCategories) {
      return const CategoryGridSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Greška pri učitavanju',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.isDesktop(context)
                ? Breakpoints.dataContentWidth(context)
                : Breakpoints.maxContentWidth(context),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Subcategories grid
              if (_categories.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    Breakpoints.horizontalPadding(context),
                    16,
                    Breakpoints.horizontalPadding(context),
                    8,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Breakpoints.isDesktop(context)
                          ? 4
                          : Breakpoints.isLargeTablet(context)
                              ? 3
                              : (Breakpoints.isSmallTablet(context) ? 3 : 2),
                      mainAxisSpacing: Breakpoints.adaptiveDouble(
                        context,
                        phone: 6,
                        smallTabletValue: 8,
                        largeTabletValue: 10,
                        desktop: 10,
                      ),
                      crossAxisSpacing: Breakpoints.adaptiveDouble(
                        context,
                        phone: 6,
                        smallTabletValue: 8,
                        largeTabletValue: 10,
                        desktop: 10,
                      ),
                      mainAxisExtent: Breakpoints.adaptiveDouble(
                        context,
                        phone: 50,
                        smallTabletValue: 52,
                        largeTabletValue: 54,
                        desktop: 54,
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = _categories[index];
                        final colorScheme = Theme.of(context).colorScheme;
                        return Semantics(
                          button: true,
                          label: 'Kategorija ${cat.name}',
                          child: Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                                width: 1,
                              ),
                            ),
                            color: colorScheme.surfaceContainerLow,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.go(
                                  '/search?category=${Uri.encodeComponent(cat.name)}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                child: Row(
                                  children: [
                                    buildCategoryIcon(
                                      cat.icon,
                                      size: 24,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cat.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _categories.length,
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.folder_off_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Nema podkategorija',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),

              // Divider + products header
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, thickness: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: Text(
                        'Najnoviji proizvodi',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Products list
              if (_loadingProducts)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_products.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nema dostupnih proizvoda.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Breakpoints.horizontalPadding(context)),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: Breakpoints.isDesktop(context)
                          ? 5
                          : Breakpoints.productGridColumns(context),
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      mainAxisExtent: Breakpoints.isDesktop(context)
                          ? 364.0
                          : Breakpoints.isLargeTablet(context)
                              ? 352.0
                              : (Breakpoints.isSmallTablet(context)
                                  ? 344.0
                                  : 368.0),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ProductCard(product: _products[index]),
                      childCount: _products.length,
                    ),
                  ),
                ),

              // Load more indicator
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
