import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/categories_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/orders_service.dart';
import '../services/products_service.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/category_icon.dart';
import '../widgets/skeleton.dart';
import '../widgets/cache_status_widget.dart';

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
  _CarouselFilter _carouselFilter = _CarouselFilter.najnovije;
  Future<SellerStats>? _sellerStatsFuture;
  Future<List<({ProductModel product, int salesCount})>>?
      _popularProductsFuture;
  String? _lastSellerId;

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
  }

  @override
  void dispose() {
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
    final categoriesProvider = context.watch<CategoriesProvider>();
    final topCategories = categoriesProvider.topCategories.take(8).toList();
    final isSeller = context.watch<AppState>().user?.isSeller ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
              icon: const Icon(Icons.location_on),
              onPressed: () => _showLocationPicker(context)),
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
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direktno sa gazdinstva do vašeg stola',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pronađi domaće proizvode iz svog kraja i naruči direktno od proizvođača.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        if (isSeller) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Kao prodavac, ovde vidiš i kratak pregled svojih porudžbina.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isSeller)
                  _SellerDashboardSliver(
                      statsFuture: _sellerStatsFuture,
                      popularFuture: _popularProductsFuture),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      readOnly: true,
                      onTap: () => _openSearch(context),
                      decoration: const InputDecoration(
                        hintText: 'Traži sir, kačkavalj…',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kategorije',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            TextButton(
                              onPressed: () => context.push('/categories'),
                              child: const Text('Vidi sve'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                          children: topCategories
                              .map((cat) => InkWell(
                                    onTap: () => context.push(
                                        '/categories/${cat.id}',
                                        extra: cat),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        buildCategoryIcon(cat.icon,
                                            size: 32,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        const SizedBox(height: 6),
                                        Text(cat.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: CacheStatusIndicator(
                    onRefresh: () => _refreshController.add(null),
                  ),
                ),
                StreamBuilder<
                    ({
                      List<ProductModel> products,
                      Map<String, int> salesCounts
                    })>(
                  stream: _productsService.getHomeProducts(
                      refreshTrigger: _refreshController.stream),
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
                    final displayList = _carouselFilter ==
                            _CarouselFilter.najnovije
                        ? (newProducts.isNotEmpty ? newProducts : list)
                        : (popularProducts.isNotEmpty ? popularProducts : list);

                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trenutno nema proizvoda u ponudi.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Probaj da osvežiš listu ili se vrati kasnije – novi proizvodi se često dodaju.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final user = context.watch<AppState>().user;
                    final favorites = context.watch<FavoritesProvider>();
                    final canFavorite = user != null && !user.isGuest;
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  onSelectionChanged: (s) =>
                                      setState(() => _carouselFilter = s.first),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CarouselSlider(
                            items: displayList
                                .map((product) => Builder(
                                      builder: (context) => Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: _PopularProductCard(
                                          product: product,
                                          isNew: DateTime.now()
                                                  .difference(product.createdAt)
                                                  .inDays <
                                              AppConstants.newProductDays,
                                          isPopular:
                                              (salesCounts[product.id] ?? 0) >=
                                                  AppConstants
                                                      .popularProductMinSales,
                                          isFavorite: canFavorite
                                              ? favorites.isFavorite(product.id)
                                              : null,
                                          onFavoriteToggle: canFavorite
                                              ? () => favorites.toggle(
                                                  user.id, product.id)
                                              : null,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            options: CarouselOptions(
                              height: 220,
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
                              enlargeFactor: 0.2,
                              scrollDirection: Axis.horizontal,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _MapCard(),
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

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ...AppConstants.regions.map((r) =>
                ListTile(title: Text(r), onTap: () => Navigator.pop(ctx, r))),
          ],
        ),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    context.go('/search');
  }
}

/// Dashboard za prodavca na Home ekranu
class _SellerDashboardSliver extends StatelessWidget {
  final Future<SellerStats>? statsFuture;
  final Future<List<({ProductModel product, int salesCount})>>? popularFuture;

  const _SellerDashboardSliver({this.statsFuture, this.popularFuture});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FutureBuilder<SellerStats>(
            future: statsFuture,
            builder: (context, statsSnap) {
              final stats = statsSnap.data;
              if (stats == null) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Popularni proizvodi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final item = list[i];
                          return _SellerPopularProductChip(
                              product: item.product,
                              salesCount: item.salesCount);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
            padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.map,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 16),
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

class _PopularProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isNew;
  final bool isPopular;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;

  const _PopularProductCard({
    required this.product,
    this.isNew = false,
    this.isPopular = false,
    this.isFavorite,
    this.onFavoriteToggle,
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
                  const SizedBox(height: 2),
                  Text(
                    product.priceFormatted,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
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
