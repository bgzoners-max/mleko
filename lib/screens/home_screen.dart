import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
import 'package:mleko/services/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';
import '../widgets/cache_status_widget.dart';
import '../widgets/app_network_image.dart';
import '../widgets/product_card.dart';

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

enum _CarouselFilter { najnovije, popularno }

class _HomeScreenState extends State<HomeScreen> {
  final _refreshController = StreamController<void>.broadcast();
  final _productsService = ProductsService();
  final _ordersService = OrdersService();
  Stream<HomeProductsData>? _homeProductsStream;
  StreamSubscription<HomeProductsData>? _homeProductsSubscription;
  HomeProductsData? _latestHomeData;
  _CarouselFilter _carouselFilter = _CarouselFilter.najnovije;
  Future<SellerStats>? _sellerStatsFuture;
  Future<List<({ProductModel product, int salesCount})>>?
      _popularProductsFuture;
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
    context.read<CategoriesProvider>().load();
    final user = context.read<AppState>().user;
    if (user != null && user.isSeller && user.id != _lastSellerId) {
      _lastSellerId = user.id;
      _sellerStatsFuture = _ordersService.getSellerStats(user.id);
      _popularProductsFuture =
          _ordersService.getSellerPopularProducts(user.id, limit: 5);
    }
    final loc = context.read<LocationProvider>();
    if (_homeProductsStream == null) {
      _homeProductsStream = _productsService.getHomeProducts(
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
    final topCategories = context.select<CategoriesProvider, List>(
        (p) => p.topCategories.take(8).toList());
    final isSeller =
        context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    final unreadCount =
        context.select<AppState, int>((s) => s.unreadNotificationCount);
    final isWide = Breakpoints.isDesktop(context);
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
    final categoryTileExtent =
        isWide ? 52.0 : (isLargeTablet ? 54.0 : (isTablet ? 58.0 : 58.0));
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
      body: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 400,
              slivers: [
                if (!isWide)
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _StickySearchHeaderDelegate(
                      isWide: false,
                      onTapSearch: () => _openSearch(context),
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
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 65,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
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
                                              onTap: () => context.push(
                                                  '/categories/${cat.id}',
                                                  extra: cat),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                child: Row(
                                                  children: [
                                                    buildCategoryIcon(
                                                      cat.icon,
                                                      size: 22,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        cat.name,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isSeller) ...[
                                      SizedBox(height: compactSpacing),
                                      RepaintBoundary(
                                        child: _SellerDashboardSliver(
                                          statsFuture: _sellerStatsFuture,
                                          popularFuture: _popularProductsFuture,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: sectionSpacing),
                                    StreamBuilder<HomeProductsData>(
                                      initialData: _latestHomeData,
                                      stream: stream,
                                      builder: (context, snap) {
                                        if (snap.hasError) {
                                          return AppErrorRetry(
                                            message:
                                                'Greška pri učitavanju proizvoda.',
                                            detail: snap.error?.toString(),
                                            onRetry: () =>
                                                _refreshController.add(null),
                                          );
                                        }
                                        if (snap.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Padding(
                                            padding:
                                                EdgeInsets.only(bottom: 24),
                                            child: ProductCarouselSkeleton(),
                                          );
                                        }
                                        final list = snap.data?.products ?? [];
                                        final salesCounts =
                                            snap.data?.salesCounts ?? {};
                                        final ratings =
                                            snap.data?.ratings ?? {};
                                        final newProducts = list
                                            .where((p) =>
                                                DateTime.now()
                                                    .difference(p.createdAt)
                                                    .inDays <
                                                AppConstants.newProductDays)
                                            .toList();
                                        final popularProducts = list
                                            .where((p) =>
                                                (salesCounts[p.id] ?? 0) >=
                                                AppConstants
                                                    .popularProductMinSales)
                                            .toList();
                                        final displayList = _carouselFilter ==
                                                _CarouselFilter.najnovije
                                            ? (newProducts.isNotEmpty
                                                ? newProducts
                                                : list)
                                            : (popularProducts.isNotEmpty
                                                ? popularProducts
                                                : list);
                                        _warmupCarouselImages(displayList);
                                        final user = context.select<AppState,
                                            UserModel?>((s) => s.user);
                                        final canFavorite =
                                            user != null && !user.isGuest;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                SegmentedButton<
                                                    _CarouselFilter>(
                                                  segments: const [
                                                    ButtonSegment(
                                                        value: _CarouselFilter
                                                            .najnovije,
                                                        label:
                                                            Text('Najnovije')),
                                                    ButtonSegment(
                                                        value: _CarouselFilter
                                                            .popularno,
                                                        label:
                                                            Text('Popularno')),
                                                  ],
                                                  selected: {_carouselFilter},
                                                  onSelectionChanged: (s) =>
                                                      setState(() =>
                                                          _carouselFilter =
                                                              s.first),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: sidePanelSpacing),
                                            GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount:
                                                    Breakpoints.isDesktop(
                                                            context)
                                                        ? 3
                                                        : Breakpoints
                                                            .productGridColumns(
                                                                context),
                                                mainAxisSpacing: 6,
                                                crossAxisSpacing: 6,
                                                mainAxisExtent:
                                                    productGridExtent,
                                              ),
                                              itemCount:
                                                  displayList.take(6).length,
                                              itemBuilder: (context, i) {
                                                final product = displayList[i];
                                                final rating =
                                                    ratings[product.id];
                                                return Selector<
                                                    FavoritesProvider, bool>(
                                                  selector: (_, fav) => fav
                                                      .isFavorite(product.id),
                                                  builder:
                                                      (_, isFavorite, __) =>
                                                          ProductCard(
                                                    product: product,
                                                    isPopular: (salesCounts[
                                                                product.id] ??
                                                            0) >=
                                                        AppConstants
                                                            .popularProductMinSales,
                                                    isFavorite: canFavorite
                                                        ? isFavorite
                                                        : null,
                                                    onFavoriteToggle: canFavorite
                                                        ? () => context
                                                            .read<
                                                                FavoritesProvider>()
                                                            .toggle(user.id,
                                                                product.id)
                                                        : null,
                                                    avgRating: rating?.avg,
                                                    reviewCount: rating?.count,
                                                  ),
                                                );
                                              },
                                            ),
                                            SizedBox(height: compactSpacing),
                                            CacheStatusIndicator(
                                              onRefresh: () =>
                                                  _refreshController.add(null),
                                            ),
                                            SizedBox(height: sectionSpacing),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: sectionSpacing),
                              Expanded(
                                flex: 35,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      readOnly: true,
                                      onTap: () => _openSearch(context),
                                      decoration: const InputDecoration(
                                        hintText: 'Traži sir, kačkavalj…',
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
                                  hintText: 'Traži sir, kačkavalj…',
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                              SizedBox(height: sectionSpacing),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Kategorije',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.push('/categories'),
                                        child: const Text('Vidi sve'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compactSpacing),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: topCategories.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isLargeTablet
                                          ? 4
                                          : (isSmallTablet ? 3 : 2),
                                      mainAxisSpacing: 6,
                                      crossAxisSpacing: 6,
                                      mainAxisExtent: isTabletLayout
                                          ? categoryTileExtent
                                          : categoryTileExtent,
                                    ),
                                    itemBuilder: (context, index) {
                                      final cat = topCategories[index];
                                      return Semantics(
                                        button: true,
                                        label: 'Kategorija ${cat.name}',
                                        child: InkWell(
                                          onTap: () => context.push(
                                            '/categories/${cat.id}',
                                            extra: cat,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                buildCategoryIcon(
                                                  cat.icon,
                                                  size: isLargeTablet
                                                      ? 22
                                                      : (isSmallTablet
                                                          ? 24
                                                          : 26),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    cat.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionSpacing),
                              if (isTabletLayout) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          statsFuture: _sellerStatsFuture,
                          popularFuture: _popularProductsFuture),
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
                        return SliverToBoxAdapter(
                          child: AppErrorRetry(
                            message: 'Greška pri učitavanju proizvoda.',
                            detail: snap.error?.toString(),
                            onRetry: () => _refreshController.add(null),
                          ),
                        );
                      }
                      if (snap.connectionState == ConnectionState.waiting) {
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
                              DateTime.now().difference(p.createdAt).inDays <
                              AppConstants.newProductDays)
                          .toList();
                      final popularProducts = list
                          .where((p) =>
                              (salesCounts[p.id] ?? 0) >=
                              AppConstants.popularProductMinSales)
                          .toList();
                      final displayList =
                          _carouselFilter == _CarouselFilter.najnovije
                              ? (newProducts.isNotEmpty ? newProducts : list)
                              : (popularProducts.isNotEmpty
                                  ? popularProducts
                                  : list);
                      _warmupCarouselImages(displayList);
                      final user =
                          context.select<AppState, UserModel?>((s) => s.user);
                      final canFavorite = user != null && !user.isGuest;
                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      Breakpoints.horizontalPadding(context)),
                              child: Row(
                                children: [
                                  SegmentedButton<_CarouselFilter>(
                                    segments: const [
                                      ButtonSegment(
                                          value: _CarouselFilter.najnovije,
                                          label: Text('Najnovije')),
                                      ButtonSegment(
                                          value: _CarouselFilter.popularno,
                                          label: Text('Popularno')),
                                    ],
                                    selected: {_carouselFilter},
                                    onSelectionChanged: (s) => setState(
                                        () => _carouselFilter = s.first),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: sidePanelSpacing),
                            if (isWide || isTabletLayout)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal:
                                        Breakpoints.horizontalPadding(context)),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        isWide ? 3 : (isLargeTablet ? 3 : 2),
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    mainAxisExtent: isWide
                                        ? 364
                                        : (isLargeTablet ? 348 : 356),
                                  ),
                                  itemCount: displayList.take(6).length,
                                  itemBuilder: (context, i) {
                                    final product = displayList[i];
                                    final rating = ratings[product.id];
                                    return Selector<FavoritesProvider, bool>(
                                      selector: (_, fav) =>
                                          fav.isFavorite(product.id),
                                      builder: (_, isFavorite, __) =>
                                          ProductCard(
                                        product: product,
                                        isPopular: (salesCounts[product.id] ??
                                                0) >=
                                            AppConstants.popularProductMinSales,
                                        isFavorite:
                                            canFavorite ? isFavorite : null,
                                        onFavoriteToggle: canFavorite
                                            ? () => context
                                                .read<FavoritesProvider>()
                                                .toggle(user.id, product.id)
                                            : null,
                                        avgRating: rating?.avg,
                                        reviewCount: rating?.count,
                                      ),
                                    );
                                  },
                                ),
                              )
                            else
                              CarouselSlider(
                                items: displayList.map((product) {
                                  final rating = ratings[product.id];
                                  return Builder(
                                    builder: (context) {
                                      return Selector<FavoritesProvider, bool>(
                                        selector: (_, fav) =>
                                            fav.isFavorite(product.id),
                                        builder: (_, isFavorite, __) =>
                                            Container(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 5),
                                          child: _PopularProductCard(
                                            product: product,
                                            isNew: DateTime.now()
                                                    .difference(
                                                        product.createdAt)
                                                    .inDays <
                                                AppConstants.newProductDays,
                                            isPopular:
                                                (salesCounts[product.id] ??
                                                        0) >=
                                                    AppConstants
                                                        .popularProductMinSales,
                                            isFavorite:
                                                canFavorite ? isFavorite : null,
                                            onFavoriteToggle: canFavorite
                                                ? () => context
                                                    .read<FavoritesProvider>()
                                                    .toggle(user.id, product.id)
                                                : null,
                                            avgRating: rating?.avg,
                                            reviewCount: rating?.count,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                                options: CarouselOptions(
                                  height: 204,
                                  aspectRatio: 16 / 9,
                                  viewportFraction: 0.85,
                                  initialPage: 0,
                                  enableInfiniteScroll: list.length > 1,
                                  reverse: false,
                                  autoPlay: list.length > 1,
                                  autoPlayInterval: const Duration(seconds: 3),
                                  autoPlayAnimationDuration:
                                      const Duration(milliseconds: 800),
                                  autoPlayCurve: Curves.fastOutSlowIn,
                                  enlargeCenterPage: true,
                                  enlargeFactor: 0.14,
                                  scrollDirection: Axis.horizontal,
                                ),
                              ),
                            if (!isTabletLayout && selectedRegion != null) ...[
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
                              onRefresh: () => _refreshController.add(null),
                            ),
                            SizedBox(height: sectionSpacing),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
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
            tabs: const [
              Tab(text: 'Najprodavaniji proizvodi'),
              Tab(text: 'Omiljena gazdinstva'),
            ],
          ),
          // IndexedStack (ne AnimatedSwitcher): oba taba ostaju u stablu pa
          // StreamBuilder u „Najprodavaniji“ ne gubi pretplatu na home stream.
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
  final TabController tabController;

  const _FavoriteFarmsList({required this.tabController});

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
    widget.tabController.addListener(_onTabChanged);
    _subscribeToFavoriteSellersChanges();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
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
    if (widget.tabController.indexIsChanging) return;
    final idx = widget.tabController.index;
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
  final Future<List<({ProductModel product, int salesCount})>>? popularFuture;

  const _SellerDashboardSliver({this.statsFuture, this.popularFuture});

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
        FutureBuilder<List<({ProductModel product, int salesCount})>>(
          future: popularFuture,
          builder: (context, popSnap) {
            final list = popSnap.data ?? [];
            if (list.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popularni proizvodi',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final item = list[i];
                        return _SellerPopularProductChip(
                            product: item.product, salesCount: item.salesCount);
                      },
                    ),
                  ),
                ],
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

class _SellerPopularProductChip extends StatelessWidget {
  final ProductModel product;
  final int salesCount;

  const _SellerPopularProductChip(
      {required this.product, required this.salesCount});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (product.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrls.first,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    fadeInDuration: Duration.zero,
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image_not_supported, size: 24),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text('$salesCount prodaja',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
            future: ProductsService().getSellersInRegion(region),
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
    return Padding(
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
                      size: 28, color: Theme.of(context).colorScheme.primary),
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
                      const SizedBox(height: 2),
                      Text(
                        'Pogledaj lokacije prodavaca u Srbiji',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
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
  double get minExtent => isWide ? 60 : 0;

  @override
  double get maxExtent => isWide ? 72 : 0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (!isWide) return const SizedBox.shrink();
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
                hintText: 'Traži sir, kačkavalj…',
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

class _PopularProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isNew;
  final bool isPopular;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final double? avgRating;
  final int? reviewCount;

  const _PopularProductCard({
    required this.product,
    this.isNew = false,
    this.isPopular = false,
    this.isFavorite,
    this.onFavoriteToggle,
    this.avgRating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  product.imageUrls.isEmpty
                      ? ColoredBox(
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.image_not_supported, size: 32),
                        )
                      : CachedNetworkImage(
                          imageUrl: product.imageUrls.first,
                          fit: BoxFit.cover,
                          memCacheWidth: 400,
                          memCacheHeight: 250,
                          fadeInDuration: Duration.zero,
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 32),
                          ),
                        ),
                  if (isNew || isPopular)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Novo',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          if (isNew && isPopular) const SizedBox(width: 4),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Popularno',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                        ],
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: isFavorite == true
                            ? 'Ukloni iz omiljenih'
                            : 'Dodaj u omiljene',
                        icon: Icon(
                          isFavorite == true
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite == true ? Colors.red : Colors.white,
                          size: 28,
                        ),
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        product.priceFormatted,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                      if (avgRating != null && (reviewCount ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () =>
                              context.push('/product/${product.id}?reviews=1'),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                avgRating!.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(Icons.location_on,
                          size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          product.location,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
