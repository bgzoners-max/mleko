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
import '../providers/location_provider.dart';
import '../models/app_error.dart';
import 'package:mleko/services/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';
import '../widgets/cache_status_widget.dart';
import '../widgets/app_network_image.dart';
import '../widgets/product_card.dart';
import 'offline_indicator.dart';

typedef HomeProductsData = ({
  List<ProductModel> products,
  Map<String, int> salesCounts,
  Map<String, ({double avg, int count})> ratings,
});

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
    final urls = products
        .map((p) => p.imageUrls.isNotEmpty ? p.imageUrls.first : null)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .take(4)
        .toList();
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
    final isOffline = context.select<AppState, bool>((s) => s.isOffline);
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
      appBar: AppBar(
        title: const Text(AppConstants.appName,
            style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Obaveštenja',
              onPressed: () => context.push('/notifications'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.location_on),
              tooltip: selectedRegion ?? 'Izaberi lokaciju',
              onPressed: () => _showLocationPicker(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            OfflineIndicator(isOffline: isOffline),
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
                      cacheExtent: 400,
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
                                            _CategoryGrid(
                                                topCategories: topCategories,
                                                isWide: true),
                                            if (isSeller) ...[
                                              SizedBox(height: compactSpacing),
                                              RepaintBoundary(
                                                child: _SellerDashboardSliver(
                                                  statsFuture:
                                                      _sellerStatsFuture,
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
                                                  return const Padding(
                                                    padding: EdgeInsets.only(
                                                        bottom: 24),
                                                    child:
                                                        ProductCarouselSkeleton(),
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
                                                return Column(
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
                                                            .titleMedium
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
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
                                            RepaintBoundary(
                                              child: _HomeSidePanel(
                                                homeProductsStream: stream,
                                                initialData: _latestHomeData,
                                                isSeller: isSeller,
                                              ),
                                            ),
                                            if (selectedRegion != null) ...[
                                              SizedBox(height: sectionSpacing),
                                              RepaintBoundary(
                                                child: _SellersNearYouSection(
                                                    region: selectedRegion),
                                              ),
                                            ],
                                            SizedBox(height: sectionSpacing),
                                            RepaintBoundary(child: _MapCard()),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
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
                                      SizedBox(height: sectionSpacing),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildCategoryHeader(context),
                                          SizedBox(height: compactSpacing),
                                          _CategoryGrid(
                                              topCategories: topCategories,
                                              isWide: false),
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
                                                child: _HomeSidePanel(
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
                                                child: _MapCard(),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedRegion != null) ...[
                                          SizedBox(height: sectionSpacing),
                                          RepaintBoundary(
                                            child: _SellersNearYouSection(
                                              region: selectedRegion,
                                            ),
                                          ),
                                        ],
                                      ] else ...[
                                        RepaintBoundary(
                                          child: _HomeSidePanel(
                                            homeProductsStream: stream,
                                            initialData: _latestHomeData,
                                            isSeller: isSeller,
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
                              child: _SellerDashboardSliver(
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
                                return const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 24),
                                    child: ProductCarouselSkeleton(),
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
                              final user = context
                                  .select<AppState, UserModel?>((s) => s.user);
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
                                          return ProductCard(
                                            product: product,
                                            isPopular:
                                                (salesCounts[product.id] ??
                                                        0) >=
                                                    AppConstants
                                                        .popularProductMinSales,
                                            isFavorite: canFavorite
                                                ? context.select<
                                                        FavoritesProvider,
                                                        bool>(
                                                    (f) => f
                                                        .isFavorite(product.id))
                                                : null,
                                            onFavoriteToggle: canFavorite
                                                ? () => context
                                                    .read<FavoritesProvider>()
                                                    .toggle(user.id, product.id)
                                                : null,
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
                                            child: _SellersNearYouSection(
                                                region: selectedRegion),
                                          ),
                                        ],
                                        if (!isTabletLayout) ...[
                                          SizedBox(height: sectionSpacing),
                                          RepaintBoundary(child: _MapCard()),
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
      delegate: _StickySearchHeaderDelegate(
        isWide: false, // Prosleđujemo false jer je u !isWide bloku
        onTapSearch: () => _openSearch(context),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    context.go('/search');
  }
}

class _HomeSidePanel extends StatefulWidget {
  final Stream<HomeProductsData> homeProductsStream;
  final HomeProductsData? initialData;
  final bool isSeller;

  const _HomeSidePanel({
    required this.homeProductsStream,
    this.initialData,
    required this.isSeller,
  });

  @override
  State<_HomeSidePanel> createState() => _HomeSidePanelState();
}

class _HomeSidePanelState extends State<_HomeSidePanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.useTwoPaneLayout(context);

    if (isWide) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidePanelCard(
            title: 'Najprodavaniji proizvodi',
            icon: Icons.trending_up,
            height: 236,
            child: _TopProductsList(
              homeProductsStream: widget.homeProductsStream,
              initialData: widget.initialData,
            ),
          ),
          const SizedBox(height: 12),
          const _SidePanelCard(
            title: 'Omiljena gazdinstva',
            icon: Icons.favorite_border,
            height: 236,
            child: _FavoriteFarmsList(),
          ),
        ],
      );
    }

    // Mobilni/tablet — tabovi
    final children = [
      _TopProductsList(
        homeProductsStream: widget.homeProductsStream,
        initialData: widget.initialData,
      ),
      _FavoriteFarmsList(tabController: _tabController),
    ];
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            onTap: (_) => HapticFeedback.selectionClick(),
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Najprodavaniji proizvodi'),
              Tab(text: 'Omiljena gazdinstva'),
            ],
          ),
          // IndexedStack (ne AnimatedSwitcher): oba taba ostaju u stablu pa
          // StreamBuilder u „Najprodavaniji” ne gubi pretplatu na home stream.
          // Inače broadcast stream ne replay-uje poslednji event → večiti spinner.
          SizedBox(
            height: 236,
            child: IndexedStack(
              index: _tabController.index,
              sizing: StackFit.expand,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double height;
  final Widget child;

  const _SidePanelCard({
    required this.title,
    required this.icon,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon,
                    size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _TopProductsList extends StatelessWidget {
  final Stream<HomeProductsData> homeProductsStream;
  final HomeProductsData? initialData;

  const _TopProductsList({
    required this.homeProductsStream,
    this.initialData,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeProductsData>(
      initialData: initialData,
      stream: homeProductsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const ProductListSkeleton();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Greška pri učitavanju proizvoda.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red),
            ),
          );
        }
        final data = snapshot.data;
        final list = data?.products ?? [];
        final salesCounts = data?.salesCounts ?? {};
        if (list.isEmpty) {
          return AppEmptyState(
            icon: Icons.shopping_basket_outlined,
            title: 'Još nema proizvoda u katalogu',
            subtitle:
                'Proverite ponovo kasnije ili pretražite po kategorijama.',
            ctaLabel: 'Pretraži proizvode',
            ctaIcon: Icons.search,
            onCtaPressed: () => context.push('/search'),
          );
        }

        final sorted = [...list];
        sorted.sort((a, b) {
          final sa = salesCounts[a.id] ?? 0;
          final sb = salesCounts[b.id] ?? 0;
          return sb.compareTo(sa);
        });
        final top = sorted.take(5).toList();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: top.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = top[index];
            final count = salesCounts[p.id] ?? 0;
            return ListTile(
              onTap: () => context.push('/product/${p.id}'),
              leading: p.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrls.first,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        memCacheWidth: 80,
                        memCacheHeight: 80,
                        fadeInDuration: Duration.zero,
                      ),
                    )
                  : const Icon(Icons.shopping_basket),
              title: Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('$count prodaja'),
            );
          },
        );
      },
    );
  }
}

/// Lista gazdinstava koje kupac prati (isti podatak kao ekran „Pratim prodavce“).
class _FavoriteFarmsList extends StatefulWidget {
  final TabController? tabController;

  const _FavoriteFarmsList({this.tabController});

  @override
  State<_FavoriteFarmsList> createState() => _FavoriteFarmsListState();
}

class _FavoriteFarmsListState extends State<_FavoriteFarmsList> {
  final FavoriteSellersService _service = FavoriteSellersService();
  Future<List<UserModel>>? _future;
  String? _loadedForUserId;
  int _prevTabIndex = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    widget.tabController?.addListener(_onTabChanged);
    _subscribeToFavoriteSellersChanges();
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_onTabChanged);
    _channel?.unsubscribe();
    _channel = null;
    super.dispose();
  }

  void _subscribeToFavoriteSellersChanges() {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;

    _channel = Supabase.instance.client
        .channel('favorite_sellers:user_id=eq.${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorite_sellers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            // Kada se doda ili ukloni omiljeni prodavac, osvežavamo listu
            _refreshForCurrentUser();
          },
        )
        .subscribe();
  }

  void _onTabChanged() {
    if (widget.tabController?.indexIsChanging ?? true) return;
    final idx = widget.tabController?.index ?? 0;
    // Osveži listu kad korisnik ponovo otvori ovaj tab (npr. posle praćenja na profilu).
    if (idx == 1 && _prevTabIndex != 1) {
      _refreshForCurrentUser();
    }
    _prevTabIndex = idx;
  }

  void _refreshForCurrentUser() {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;
    setState(() {
      _future = _service.getFavoriteSellersWithProfiles(user.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      if (_loadedForUserId != null) {
        _channel?.unsubscribe();
        _channel = null;
        setState(() {
          _loadedForUserId = null;
          _future = null;
        });
      }
      return;
    }
    if (_loadedForUserId != user.id) {
      // Unsubscribe stare i subscribe nove
      _channel?.unsubscribe();
      _subscribeToFavoriteSellersChanges();
      setState(() {
        _loadedForUserId = user.id;
        _future = _service.getFavoriteSellersWithProfiles(user.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, UserModel?>((s) => s.user);
    if (user == null || user.isGuest) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                'Prijavite se da vidite gazdinstva koja pratite.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () => context.push('/login'),
                child: const Text('Prijavi se'),
              ),
            ],
          ),
        ),
      );
    }

    final future = _future;
    if (future == null) {
      return const SellerProductListSkeleton(itemCount: 3);
    }

    return FutureBuilder<List<UserModel>>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Greška pri učitavanju.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _refreshForCurrentUser,
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const SellerProductListSkeleton(itemCount: 3);
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Još ne pratite nijedno gazdinstvo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('Pretraži proizvode'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final seller = list[i];
                  final title =
                      seller.farmName ?? seller.displayName ?? 'Gazdinstvo';
                  final subtitle = seller.location ?? seller.city;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.push('/seller/${seller.id}'),
                    leading: seller.profileImageUrl != null
                        ? ClipOval(
                            child: AppNetworkImage.profileSmall(
                              imageUrl: seller.profileImageUrl!,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.store,
                                size: 20, color: Colors.grey.shade700),
                          ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: subtitle != null
                        ? Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () => context.push('/favorite-sellers'),
              child: const Text('Sva omiljena gazdinstva'),
            ),
          ],
        );
      },
    );
  }
}

/// Dashboard za prodavca na Home ekranu
class _SellerDashboardSliver extends StatelessWidget {
  final Future<SellerStats>? statsFuture;

  const _SellerDashboardSliver({this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<SellerStats>(
          future: statsFuture,
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            if (stats == null) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SellerStatItem(
                        label: 'Na čekanju',
                        value: '${stats.pendingCount}',
                        icon: Icons.pending),
                    _SellerStatItem(
                        label: 'Ukupno',
                        value: '${stats.totalCount}',
                        icon: Icons.receipt_long),
                    _SellerStatItem(
                        label: 'Prihod',
                        value: '${stats.revenue.toStringAsFixed(0)} RSD',
                        icon: Icons.monetization_on),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SellerStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SellerStatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}

/// Sekcija „Prodavci u tvom okruženju” – prikazuje prodavce u izabranom regionu.
class _SellersNearYouSection extends StatelessWidget {
  final String region;

  const _SellersNearYouSection({required this.region});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prodavci u tvom okruženju',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<UserModel>>(
            future: context.read<ProductsService>().getSellersInRegion(region),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SellerAvatarRowSkeleton();
              }
              final sellers = snap.data ?? <UserModel>[];
              if (sellers.isEmpty) {
                return Text(
                  'Nema prodavaca sa proizvodima u $region.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                );
              }
              return SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sellers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final seller = sellers[i];
                    final name =
                        seller.farmName ?? seller.displayName ?? 'Prodavac';
                    final subtitle = seller.location ?? seller.city ?? region;
                    return SizedBox(
                      width: 160,
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: seller.profileImageUrl != null
                                ? NetworkImage(seller.profileImageUrl!)
                                : null,
                            child: seller.profileImageUrl == null
                                ? Icon(Icons.store, color: Colors.grey.shade700)
                                : null,
                          ),
                          title: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                          onTap: () => context.push('/seller/${seller.id}'),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Kartica mape – kompaktno, tap otvara punu mapu
class _MapCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/sellers-map'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.map,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prodavci na mapi',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () => context.push('/about'),
              child: const Text('O platformi'),
            ),
            TextButton(
              onPressed: () => context.push('/support'),
              child: const Text('Podrška'),
            ),
            TextButton(
              onPressed: () => context.push('/uslovi-koriscenja'),
              child: const Text('Uslovi korišćenja'),
            ),
            TextButton(
              onPressed: () => context.push('/politika-privatnosti'),
              child: const Text('Politika privatnosti'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isWide;
  final VoidCallback onTapSearch;

  _StickySearchHeaderDelegate({
    required this.isWide,
    required this.onTapSearch,
  });

  @override
  double get minExtent => isWide ? 0 : 60;

  @override
  double get maxExtent => isWide ? 0 : 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (isWide) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              readOnly: true,
              onTap: onTapSearch,
              decoration: const InputDecoration(
                hintText: 'Traži proizvode, proizvođače…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchHeaderDelegate oldDelegate) {
    return isWide != oldDelegate.isWide;
  }
}

class _CategoryGrid extends StatelessWidget {
  final List topCategories;
  final bool isWide;

  const _CategoryGrid({
    required this.topCategories,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isWide ? 4 : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2)),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        mainAxisExtent: 52,
      ),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final cat = topCategories[index];
        return Semantics(
          button: true,
          label: 'Kategorija ${cat.name}',
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/categories/${cat.id}', extra: cat),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    buildCategoryIcon(
                      cat.icon,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
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
    );
  }
}
