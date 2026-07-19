import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/home_products_data.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/location_provider.dart';
import '../services/services.dart';

import '../widgets/sticky_search_header_delegate.dart';
import '../widgets/home/home_wide_layout.dart';
import '../widgets/home/home_narrow_top_section.dart';
import '../widgets/home/home_narrow_products_sliver.dart';
import '../widgets/home/seller_dashboard_sliver.dart';

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
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Row(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                        if (!isWide) _buildStickySearch(context),
                        if (selectedRegion != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                outerHorizontalPadding,
                                8,
                                outerHorizontalPadding,
                                0,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Prikazujemo proizvode za region: $selectedRegion',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          _showLocationPicker(context),
                                      child: const Text('Promeni'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              outerHorizontalPadding,
                              12,
                              outerHorizontalPadding,
                              4,
                            ),
                            child: isWide
                                ? HomeWideLayout(
                                    topCategories: topCategories,
                                    isSeller: isSeller,
                                    sellerStatsFuture: _sellerStatsFuture,
                                    stream: stream,
                                    latestHomeData: _latestHomeData,
                                    selectedRegion: selectedRegion,
                                    refreshController: _refreshController,
                                    warmupCarouselImages: _warmupCarouselImages,
                                    productGridExtent: productGridExtent,
                                    compactSpacing: compactSpacing,
                                    sectionSpacing: sectionSpacing,
                                    sidePanelSpacing: sidePanelSpacing,
                                    categoryHeader:
                                        _buildCategoryHeader(context),
                                    onSearchTap: () => _openSearch(context),
                                  )
                                : HomeNarrowTopSection(
                                    topCategories: topCategories,
                                    isTabletLayout: isTabletLayout,
                                    isLargeTablet: isLargeTablet,
                                    compactSpacing: compactSpacing,
                                    sectionSpacing: sectionSpacing,
                                    stream: stream,
                                    latestHomeData: _latestHomeData,
                                    isSeller: isSeller,
                                    selectedRegion: selectedRegion,
                                    categoryHeader:
                                        _buildCategoryHeader(context),
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
                          HomeNarrowProductsSliver(
                            stream: stream,
                            latestHomeData: _latestHomeData,
                            refreshController: _refreshController,
                            warmupCarouselImages: _warmupCarouselImages,
                            isTabletLayout: isTabletLayout,
                            isLargeTablet: isLargeTablet,
                            sectionSpacing: sectionSpacing,
                            compactSpacing: compactSpacing,
                            selectedRegion: selectedRegion,
                            onSearchTap: () => _openSearch(context),
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
        isWide: false,
        onTapSearch: () => _openSearch(context),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    context.push('/search');
  }
}
