import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  final _refreshController = StreamController<void>.broadcast();
  final _scrollController = ScrollController();

  /// Stream keširan da se na svakom rebuild-u ne kreira novi i ne ponovo učitavaju omiljeni.
  Stream<List<ProductModel>>? _favoritesStream;
  String? _streamUserId;

  static const _pageSize = 20;
  int _displayCount = _pageSize;
  final Set<String> _preloadedImages = <String>{};

  void _warmupProductImages(List<ProductModel> products) {
    final urls = products
        .map((p) => p.imageUrls.isNotEmpty ? p.imageUrls.first : null)
        .whereType<String>()
        .where((u) => u.isNotEmpty)
        .take(12)
        .toList();
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

  void _initStream(String userId) {
    if (_streamUserId == userId) return;
    _streamUserId = userId;
    _displayCount = _pageSize;
    _favoritesStream = _favoritesService.streamFavoriteProducts(
      userId,
      refreshTrigger: _refreshController.stream,
    );
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      setState(() => _displayCount += _pageSize);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    final favorites = context.read<FavoritesProvider>();
    if (user != null && !user.isGuest && !favorites.isLoaded) {
      favorites.load(user.id);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isDesktop = Breakpoints.isDesktop(context);
    final isWideDesktop = Breakpoints.isWideDesktop(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isGridLayout = isDesktop || isLargeTablet || isSmallTablet;
    final contentPadding = Breakpoints.horizontalPadding(context);
    final gridColumns = isWideDesktop
        ? 4
        : isDesktop
            ? 3
            : isLargeTablet
                ? 3
                : 2;
    final gridSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 12,
      smallTabletValue: 12,
      largeTabletValue: 14,
      desktop: 14,
    );
    final gridExtent = isWideDesktop
        ? 360.0
        : isDesktop
            ? 372.0
            : isLargeTablet
                ? 340.0
                : 320.0;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Omiljeni proizvodi')),
        body: AppEmptyState(
          icon: Icons.favorite_outline,
          title: 'Prijavite se za listu želja',
          subtitle: 'Sačuvajte proizvode koje volite i lako ih pronađite kasnije.',
          ctaLabel: 'Prijavi se',
          onCtaPressed: () => context.go('/login'),
        ),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Omiljeni proizvodi')),
      body: StreamBuilder<List<ProductModel>>(
        stream: _favoritesStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju omiljenih.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const ProductListSkeleton();
          }
          final list = snap.data ?? [];
          if (list.isNotEmpty) {
            _warmupProductImages(list);
          }
          if (list.isEmpty) {
            return AppEmptyState(
              icon: Icons.favorite_border,
              title: 'Nemate omiljenih proizvoda',
              subtitle:
                  'Dodajte srcem na karticama proizvoda da ih nađete brzo ovde.',
              ctaLabel: 'Pretraži proizvode',
              ctaIcon: Icons.search,
              onCtaPressed: () => context.go('/'),
            );
          }
          final visible = list.take(_displayCount).toList();
          final hasMore = list.length > _displayCount;
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop
                      ? Breakpoints.dataContentWidth(context)
                      : Breakpoints.maxContentWidth(context),
                ),
                child: isGridLayout
                    ? GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(contentPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns,
                          crossAxisSpacing: gridSpacing,
                          mainAxisSpacing: gridSpacing,
                          mainAxisExtent: gridExtent,
                        ),
                        itemCount: visible.length + (hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == visible.length) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final p = visible[i];
                          return Selector<FavoritesProvider, bool>(
                            selector: (_, fav) => fav.isFavorite(p.id),
                            builder: (_, isFavorite, __) {
                              final user = context.watch<AppState>().user;
                              final favorites =
                                  context.read<FavoritesProvider>();
                              return ProductCard(
                                product: p,
                                isFavorite: isFavorite,
                                onFavoriteToggle: user != null && !user.isGuest
                                    ? () => favorites.toggle(user.id, p.id)
                                    : null,
                              );
                            },
                          );
                        },
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(contentPadding),
                        itemCount: visible.length + (hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == visible.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final p = visible[i];
                          return Selector<FavoritesProvider, bool>(
                            selector: (_, fav) => fav.isFavorite(p.id),
                            builder: (_, isFavorite, __) {
                              final user = context.watch<AppState>().user;
                              final favorites =
                                  context.read<FavoritesProvider>();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ProductCard(
                                  product: p,
                                  isFavorite: isFavorite,
                                  onFavoriteToggle: user != null &&
                                          !user.isGuest
                                      ? () => favorites.toggle(user.id, p.id)
                                      : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
