import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/amazon_theme.dart';
import '../core/responsive.dart';
import '../core/web_seo.dart';
import '../models/category.dart';
import '../models/product_model.dart';
import 'package:mleko/services/services.dart';
import '../utils/image_precache_utils.dart';
import '../widgets/category_icon.dart';
import '../widgets/product_card.dart';
import '../widgets/app_back_button.dart';
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
    warmupProductImages(
      context: context,
      products: products,
      preloadedUrls: _preloadedImages,
      isMounted: () => mounted,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productsService ??= context.read<ProductsService>();
  }

  @override
  void initState() {
    super.initState();
    setCategorySeo(
      name: widget.parentCategory.name,
      path: '/categories/${widget.parentCategory.id}',
      description:
          'Pregledajte ponudu domaćih proizvoda u kategoriji ${widget.parentCategory.name}. Prirodno, domaće i sveže od proizvođača iz Srbije.',
    );
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
        unawaited(_loadInitialProducts(list));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/categories'),
        backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
            width: 1.0,
          ),
        ),
        title: Text(
          widget.parentCategory.name,
          style: TextStyle(
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        ),
        actions: const [
          AppHomeButton(),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          : (Breakpoints.isLargeTablet(context)
                              ? 4
                              : (Breakpoints.isSmallTablet(context) ? 3 : 2)),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 46,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = _categories[index];
                        final catColor = getFoodCategoryColor(
                            cat.name.isNotEmpty ? cat.name : widget.parentCategory.name);
                        return Semantics(
                          button: true,
                          label: 'Potkategorija ${cat.name}',
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                                width: 1.0,
                              ),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.025),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => context.go(
                                    '/search?category=${Uri.encodeComponent(cat.name)}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: buildCategoryIcon(
                                          cat.icon,
                                          size: 17,
                                          color: catColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12.5,
                                            color: isDark
                                                ? AmazonColors.darkTextPrimary
                                                : AmazonColors.textPrimary,
                                            height: 1.15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 15,
                                        color: isDark
                                            ? AmazonColors.darkTextSecondary.withValues(alpha: 0.6)
                                            : AmazonColors.textSecondary.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
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
