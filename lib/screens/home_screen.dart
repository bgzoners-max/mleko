import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/amazon_theme.dart';
import '../core/constants.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/home_products_data.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/classifieds_provider.dart';
import '../providers/location_provider.dart';
import '../services/services.dart';

import '../utils/image_precache_utils.dart';
import '../widgets/sticky_search_header_delegate.dart';
import '../widgets/home/home_wide_layout.dart';
import '../widgets/home/home_narrow_top_section.dart';
import '../widgets/home/home_narrow_products_sliver.dart';
import '../widgets/home/seller_dashboard_sliver.dart';
import '../widgets/home/market_mode_switcher.dart';
import '../widgets/beta_announcement_banner.dart';
import '../widgets/theme_toggle_switch.dart';
import 'classifieds/classifieds_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // MarketMode se vise ne cuva lokalno — citamo ga iz AppSettingsProvider
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
    warmupProductImages(
      context: context,
      products: products,
      preloadedUrls: _preloadedCarouselImages,
      isMounted: () => mounted,
      topCountWithSecondary: 4,
      maxTotalUrls: 8,
    );
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
    final isGuest = context.select<AppState, bool>((s) => s.user == null || s.user!.isGuest);
    final isSeller = context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    final unreadCount =
        context.select<AppState, int>((s) => s.unreadNotificationCount);

    final isWide = isTwoPaneLayout;
    final isTablet = Breakpoints.isTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isTabletLayout = isTablet && !isWide;

    final outerHorizontalPadding =
        isWide ? 14.0 : (isLargeTablet ? 12.0 : (isSmallTablet ? 10.0 : 8.0));
    final sectionSpacing = isWide ? 10.0 : 8.0;
    final compactSpacing = 6.0;
    final sidePanelSpacing = 10.0;
    final productGridExtent = isWide
        ? 285.0
        : (isLargeTablet ? 295.0 : (isSmallTablet ? 285.0 : 265.0));

    final stream = _homeProductsStream;
    if (stream == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text(AppConstants.appName,
                style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: false,
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
            width: 1.0,
          ),
        ),
        titleSpacing: 8,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
            context.read<ClassifiedsProvider>().clearFilters();
            context.go('/');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 22,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    AppConstants.appName,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const BetaBadge(showInfoIcon: false),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (!isGuest)
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                backgroundColor: AmazonColors.dealRed,
                child: const Icon(Icons.notifications_none_rounded, size: 22),
              ),
              onPressed: () => context.push('/notifications'),
            ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Badge(
              isLabelVisible: context.watch<CartProvider>().count > 0,
              label: Text('${context.watch<CartProvider>().count}'),
              backgroundColor: AmazonColors.amber,
              textColor: AmazonColors.darkNavy,
              child: const Icon(Icons.shopping_cart_outlined, size: 22),
            ),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.location_on_outlined, size: 22),
            onPressed: () => _showLocationPicker(context),
          ),
          const SizedBox(width: 2),
          const Center(child: ThemeToggleSwitch()),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const BetaAnnouncementBanner(),
            MarketModeSwitcher(
              currentMode: context.select<AppSettingsProvider, MarketMode>(
                  (s) => s.marketMode),
              onModeChanged: (m) =>
                  context.read<AppSettingsProvider>().setMarketMode(m),
            ),
            Expanded(
              child: context.select<AppSettingsProvider, MarketMode>(
                          (s) => s.marketMode) ==
                      MarketMode.classifieds
                  ? const ClassifiedsFeedScreen(isEmbedded: true)
                  : ColoredBox(
                      color: AmazonColors.getCanvas(context),
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
                              scrollCacheExtent:
                                  const ScrollCacheExtent.pixels(600.0),
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                if (!isWide) _buildStickySearch(context),
                                if (selectedRegion != null)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        outerHorizontalPadding,
                                        6,
                                        outerHorizontalPadding,
                                        0,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AmazonColors.darkCard
                                              : AmazonColors.cardWhite,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? AmazonColors.darkBorder
                                                : AmazonColors.borderGray,
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            if (!isDark)
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.02),
                                                blurRadius: 2,
                                                offset: const Offset(0, 1),
                                              ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: AmazonColors.link,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Prikaz za region: $selectedRegion',
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AmazonColors
                                                          .darkTextPrimary
                                                      : AmazonColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  _showLocationPicker(context),
                                              child: const Text(
                                                'Promeni',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AmazonColors.link,
                                                ),
                                              ),
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
        unawaited(loc.clearRegion());
      } else {
        await loc.setRegion(chosen);
      }
    }
  }

  Widget _buildCategoryHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Kategorije hrane',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () => context.push('/categories'),
          child: const Text(
            'Vidi sve',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AmazonColors.link,
            ),
          ),
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
