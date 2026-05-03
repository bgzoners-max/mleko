import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../models/app_error.dart';
import 'package:mleko/services/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';
import '../widgets/cache_status_widget.dart';
import '../widgets/app_network_image.dart';
import '../widgets/product_card.dart';
import '../models/home_products_data.dart';
import '../models/category_grid.dart';
import '../models/favorite_farms_list.dart';
import '../models/home_product_item.dart';
import '../models/home_side_panel.dart';
import '../models/map_card.dart';
import '../models/seller_dashboard_sliver.dart';
import '../models/sellers_near_you_section.dart';
import '../widgets/sticky_search_header_delegate.dart';
import '../utils/animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _refreshController = StreamController<void>.broadcast();
  ProductsService? _productsService;
  OrdersService? _ordersService;
  Stream<HomeProductsData>? _homeProductsStream;
  StreamSubscription<HomeProductsData>? _homeProductsSubscription;
  HomeProductsData? _latestHomeData;
  Future<SellerStats>? _sellerStatsFuture;
  String? _lastSellerId;
  final Set<String> _preloadedCarouselImages = <String>{};

  void _warmupCarouselImages(List<ProductModel> products) {
    final List<String> urls = [];
    for (final p in products.take(4)) {
      if (p.imageUrls.isNotEmpty) {
        urls.add(p.imageUrls.first);
        // Preload-uj i drugu sliku ako postoji za još brži prelaz na detalje
        if (p.imageUrls.length > 1) {
          urls.add(p.imageUrls[1]);
        }
      }
    }
    if (urls.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final url in urls) {
        if (!mounted) return;
        if (_preloadedCarouselImages.add(url)) {
          await precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productsService ??= context.read<ProductsService>();
    _ordersService ??= context.read<OrdersService>();
    context.read<CategoriesProvider>().load();
    final user = context.read<AppState>().user;
    if (user != null && user.isSeller && user.id != _lastSellerId) {
      _lastSellerId = user.id;
      _sellerStatsFuture = _ordersService!.getSellerStats(user.id);
    }
    // Koristi listen: false unutar didChangeDependencies ako samo uzimaš vrednost
    final loc = Provider.of<LocationProvider>(context, listen: false);
    if (_homeProductsStream == null) {
      _homeProductsStream = _productsService!.getHomeProducts(
        regionNotifier: loc.regionNotifier,
        refreshTrigger: _refreshController.stream,
      );
      _homeProductsSubscription?.cancel();
      _homeProductsSubscription = _homeProductsStream!.listen((data) {
        if (!mounted) return;
        setState(() => _latestHomeData = data);
      });
    }
  }

  @override
  void dispose() {
    _homeProductsSubscription?.cancel();
    _refreshController.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final categories = context.read<CategoriesProvider>();
    _refreshController.add(null);
    await categories.refresh();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion =
        context.select<LocationProvider, String?>((p) => p.selectedRegion);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final topCategories = context.select<CategoriesProvider, List>((p) =>
        isTwoPaneLayout ? p.topCategories : p.topCategories.take(8).toList());
    final isSeller =
        context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    final unreadCount =
        context.select<AppState, int>((s) => s.unreadNotificationCount);
    final isWide = isTwoPaneLayout;
    final isTablet = Breakpoints.isTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isTabletLayout = isTablet && !isWide;
    final outerHorizontalPadding =
        isWide ? 12.0 : (isLargeTablet ? 14.0 : (isSmallTablet ? 12.0 : 10.0));
    final sectionSpacing =
        isWide ? 12.0 : (isLargeTablet ? 16.0 : (isSmallTablet ? 14.0 : 12.0));
    final compactSpacing = isWide ? 8.0 : 6.0;
    final sidePanelSpacing =
        isWide ? 12.0 : (isLargeTablet ? 14.0 : (isSmallTablet ? 12.0 : 10.0));
    final productGridExtent = isWide
        ? 364.0
        : (isLargeTablet ? 352.0 : (isSmallTablet ? 344.0 : 368.0));
    final stream = _homeProductsStream;
    if (stream == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text(AppConstants.appName,
                style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            const Icon(Icons.eco_outlined, size: 28),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: context.watch<CartProvider>().count > 0,
              label: Text('${context.watch<CartProvider>().count}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () => _showLocationPicker(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTwoPaneLayout
                        ? Breakpoints.dataContentWidth(context)
                        : Breakpoints.maxContentWidth(context),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: 600,
                      slivers: [
                        // Search header se prikazuje samo na mobilnim uređajima kada se skroluje
                        if (!isWide) _buildStickySearch(context),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              outerHorizontalPadding,
                              12,
                              outerHorizontalPadding,
                              4,
                            ),
                            child: isWide
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 70,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildCategoryHeader(context),
                                            SizedBox(height: compactSpacing),
                                            CategoryGrid(
                                                topCategories: topCategories,
                                                isWide: true),
                                            if (isSeller) ...[
                                              SizedBox(height: compactSpacing),
                                              FadeInSlide(
                                                delay: Duration(milliseconds: 200),
                                                child: RepaintBoundary(
                                                  child: SellerDashboardSliver(
                                                    statsFuture: _sellerStatsFuture,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            SizedBox(height: sectionSpacing),
                                            StreamBuilder<HomeProductsData>(
                                              initialData: _latestHomeData,
                                              stream: stream,
                                              builder: (context, snap) {
                                                if (snap.hasError) {
                                                  final appError =
                                                      AppError.from(snap.error);
                                                  return AppErrorRetry(
                                                    message: appError
                                                        .getUserMessage(),
                                                    detail: appError.code,
                                                    onRetry: () =>
                                                        _refreshController
                                                            .add(null),
                                                  );
                                                }
                                                if (snap.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return GridView.builder(
                                                    shrinkWrap: true,
                                                    physics: const NeverScrollableScrollPhysics(),
                                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: Breakpoints.isDesktop(context) ? 4 : 2,
                                                      mainAxisSpacing: 6,
                                                      crossAxisSpacing: 6,
                                                      mainAxisExtent: productGridExtent,
                                                    ),
                                                    itemCount: 4,
                                                    itemBuilder: (_, __) => const ProductCardSkeleton(),
                                                  );
                                                }
                                                final list =
                                                    snap.data?.products ?? [];
                                                final salesCounts =
                                                    snap.data?.salesCounts ??
                                                        {};
                                                final ratings =
                                                    snap.data?.ratings ?? {};
                                                final newProducts = list
                                                    .where((p) =>
                                                        DateTime.now()
                                                            .difference(
                                                                p.createdAt)
                                                            .inDays <
                                                        AppConstants
                                                            .newProductDays)
                                                    .toList();
                                                final displayList =
                                                    newProducts.isNotEmpty
                                                        ? newProducts
                                                        : list;
                                                _warmupCarouselImages(
                                                    displayList);
                                                final user = context.select<
                                                    AppState,
                                                    UserModel?>((s) => s.user);
                                                final canFavorite =
                                                    user != null &&
                                                        !user.isGuest;
                                                return FadeInSlide(
                                                  delay: const Duration(milliseconds: 300),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                                bottom: 12),
                                                        child: Text(
                                                          newProducts.isNotEmpty
                                                              ? 'Najnoviji proizvodi'
                                                              : 'Poslednje dodato',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .titleLarge
                                                              ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800),
                                                        ),
                                                      ),
                                                    GridView.builder(
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: Breakpoints
                                                                .isDesktop(
                                                                    context)
                                                            ? 4
                                                            : Breakpoints
                                                                .productGridColumns(
                                                                    context),
                                                        mainAxisSpacing: 6,
                                                        crossAxisSpacing: 6,
                                                        mainAxisExtent:
                                                            productGridExtent,
                                                      ),
                                                      itemCount: displayList
                                                          .take(8)
                                                          .length,
                                                      itemBuilder:
                                                          (context, i) {
                                                        final product =
                                                            displayList[i];
                                                        final rating =
                                                            ratings[product.id];
                                                        return Selector<
                                                            FavoritesProvider,
                                                            bool>(
                                                          selector: (_, fav) =>
                                                              fav.isFavorite(
                                                                  product.id),
                                                          builder: (_,
                                                                  isFavorite,
                                                                  __) =>
                                                              ProductCard(
                                                            product: product,
                                                            isPopular: (salesCounts[
                                                                        product
                                                                            .id] ??
                                                                    0) >=
                                                                AppConstants
                                                                    .popularProductMinSales,
                                                            isFavorite:
                                                                canFavorite
                                                                    ? isFavorite
                                                                    : null,
                                                            onFavoriteToggle: canFavorite
                                                                ? () => context
                                                                    .read<
                                                                        FavoritesProvider>()
                                                                    .toggle(
                                                                        user.id,
                                                                        product
                                                                            .id)
                                                                : null,
                                                            avgRating:
                                                                rating?.avg,
                                                            reviewCount:
                                                                rating?.count,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    SizedBox(
                                                        height: compactSpacing),
                                                    CacheStatusIndicator(
                                                      onRefresh: () =>
                                                          _refreshController
                                                              .add(null),
                                                    ),
                                                    SizedBox(
                                                        height: sectionSpacing),
                                                   ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: sectionSpacing),
                                      Expanded(
                                        flex: 30,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            TextField(
                                              readOnly: true,
                                              onTap: () => _openSearch(context),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Traži proizvode, proizvođače…',
                                                prefixIcon: Icon(Icons.search),
                                              ),
                                            ),
                                            SizedBox(height: sidePanelSpacing),
                                              FadeInSlide(
                                                delay: const Duration(milliseconds: 400),
                                                child: RepaintBoundary(
                                                  child: HomeSidePanel(
                                                    homeProductsStream: stream,
                                                    initialData: _latestHomeData,
                                                    isSeller: isSeller,
                                                  ),
                                                ),
                                              ),
                                              if (selectedRegion != null) ...[
                                                SizedBox(height: sectionSpacing),
                                                FadeInSlide(
                                                  delay: const Duration(milliseconds: 500),
                                                  child: RepaintBoundary(
                                                    child: SellersNearYouSection(
                                                        region: selectedRegion),
                                                  ),
                                                ),
                                              ],
                                              SizedBox(height: sectionSpacing),
                                              const FadeInSlide(
                                                delay: Duration(milliseconds: 600),
                                                child: RepaintBoundary(child: MapCard()),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildCategoryHeader(context),
                                          SizedBox(height: compactSpacing),
                                          FadeInSlide(
                                            delay: const Duration(milliseconds: 100),
                                            child: CategoryGrid(
                                                topCategories: topCategories,
                                                isWide: false),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: sectionSpacing),
                                      if (isTabletLayout) ...[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: isLargeTablet ? 6 : 5,
                                              child: RepaintBoundary(
                                                child: HomeSidePanel(
                                                  homeProductsStream: stream,
                                                  initialData: _latestHomeData,
                                                  isSeller: isSeller,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: sectionSpacing),
                                            Expanded(
                                              flex: isLargeTablet ? 4 : 5,
                                              child: RepaintBoundary(
                                                child: MapCard(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedRegion != null) ...[
                                          SizedBox(height: sectionSpacing),
                                          RepaintBoundary(
                                            child: SellersNearYouSection(
                                              region: selectedRegion,
                                            ),
                                          ),
                                        ],
                                      ] else ...[
                                        FadeInSlide(
                                          delay: const Duration(milliseconds: 200),
                                          child: RepaintBoundary(
                                            child: HomeSidePanel(
                                              homeProductsStream: stream,
                                              initialData: _latestHomeData,
                                              isSeller: isSeller,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                        if (!isWide && isSeller)
                          SliverToBoxAdapter(
                            child: RepaintBoundary(
                              child: SellerDashboardSliver(
                                  statsFuture: _sellerStatsFuture),
                            ),
                          ),
                        if (!isWide)
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        if (!isWide)
                          StreamBuilder<HomeProductsData>(
                            initialData: _latestHomeData,
                            stream: stream,
                            builder: (context, snap) {
                              if (snap.hasError) {
                                final appError = AppError.from(snap.error);
                                return SliverToBoxAdapter(
                                  child: AppErrorRetry(
                                    message: appError.getUserMessage(),
                                    detail: appError.code,
                                    onRetry: () => _refreshController.add(null),
                                  ),
                                );
                              }
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return SliverPadding(
                                  padding: EdgeInsets.symmetric(horizontal: Breakpoints.horizontalPadding(context)),
                                  sliver: SliverGrid(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 4,
                                      crossAxisSpacing: 4,
                                      mainAxisExtent: 255,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, i) => const ProductCardSkeleton(),
                                      childCount: 4,
                                    ),
                                  ),
                                );
                              }
                              final list = snap.data?.products ?? [];
                              final salesCounts = snap.data?.salesCounts ?? {};
                              final ratings = snap.data?.ratings ?? {};
                              final newProducts = list
                                  .where((p) =>
                                      DateTime.now()
                                          .difference(p.createdAt)
                                          .inDays <
                                      AppConstants.newProductDays)
                                  .toList();
                              final displayList =
                                  newProducts.isNotEmpty ? newProducts : list;
                              _warmupCarouselImages(displayList);
                              final user = context.read<AppState>().user;
                              final canFavorite = user != null && !user.isGuest;

                              return SliverMainAxisGroup(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        Breakpoints.horizontalPadding(context),
                                        sidePanelSpacing,
                                        Breakpoints.horizontalPadding(context),
                                        12,
                                      ),
                                      child: Text(
                                        newProducts.isNotEmpty
                                            ? 'Najnoviji proizvodi'
                                            : 'Poslednje dodato',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal:
                                            Breakpoints.horizontalPadding(
                                                context)),
                                    sliver: SliverGrid(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isTabletLayout
                                            ? (isLargeTablet ? 3 : 2)
                                            : 2,
                                        mainAxisSpacing: isTabletLayout ? 8 : 4,
                                        crossAxisSpacing:
                                            isTabletLayout ? 8 : 4,
                                        mainAxisExtent: isTabletLayout
                                            ? (isLargeTablet ? 348 : 356)
                                            : 255,
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, i) {
                                          final product = displayList[i];
                                          final rating = ratings[product.id];
                                          return HomeProductItem(
                                            product: product,
                                            salesCount:
                                                salesCounts[product.id] ?? 0,
                                            canFavorite: canFavorite,
                                            userId: user?.id,
                                            avgRating: rating?.avg,
                                            reviewCount: rating?.count,
                                          );
                                        },
                                        childCount: displayList.take(6).length,
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Column(
                                      children: [
                                        if (!isTabletLayout &&
                                            selectedRegion != null) ...[
                                          SizedBox(height: sectionSpacing),
                                          RepaintBoundary(
                                            child: SellersNearYouSection(
                                                region: selectedRegion),
                                          ),
                                        ],
                                        if (!isTabletLayout) ...[
                                          SizedBox(height: sectionSpacing),
                                          RepaintBoundary(child: MapCard()),
                                        ],
                                        SizedBox(height: compactSpacing),
                                        CacheStatusIndicator(
                                          onRefresh: () =>
                                              _refreshController.add(null),
                                        ),
                                        SizedBox(height: sectionSpacing),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationPicker(BuildContext context) async {
    final loc = context.read<LocationProvider>();
    if (!loc.gpsTried) {
      final detected = await loc.tryDetectFromGps();
      if (detected && context.mounted) {
        Navigator.of(context).pop();
        return;
      }
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Izaberi region',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.location_off,
                  color: Theme.of(ctx).colorScheme.outline),
              title: const Text('Prikaži sve regione'),
              subtitle: const Text('Bez filtera po lokaciji'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            const Divider(height: 1),
            ...AppConstants.regions.map((r) => ListTile(
                  title: Text(r),
                  trailing: loc.selectedRegion == r
                      ? Icon(Icons.check,
                          color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, r),
                )),
          ],
        ),
      ),
    );
    if (chosen != null && context.mounted) {
      if (chosen.isEmpty) {
        loc.clearRegion();
      } else {
        await loc.setRegion(chosen);
      }
    }
  }

  Widget _buildCategoryHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Kategorije',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        TextButton(
          onPressed: () => context.push('/categories'),
          child: const Text('Vidi sve'),
        ),
      ],
    );
  }

  Widget _buildStickySearch(BuildContext context) {
    return SliverPersistentHeader(
      pinned: false,
      delegate: StickySearchHeaderDelegate(
        isWide: false, // Prosleđujemo false jer je u !isWide bloku
        onTapSearch: () => _openSearch(context),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    context.push('/search');
  }
}
