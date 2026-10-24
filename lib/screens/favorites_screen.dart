import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';
import '../utils/image_precache_utils.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_back_button.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/rustic_illustration.dart';
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
    warmupProductImages(
      context: context,
      products: products,
      preloadedUrls: _preloadedImages,
      isMounted: () => mounted,
    );
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
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isDesktop = Breakpoints.isDesktop(context);
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Omiljeni proizvodi'),
          actions: const [AppHomeButton()],
        ),
        body: AppEmptyState(
          motif: RusticMotif.basket,
          icon: Icons.favorite_outline,
          title: 'Prijavi se za listu želja',
          subtitle:
              'Sačuvaj omiljene proizvode i nađi ih kasnije na jednom mestu.',
          ctaLabel: 'Prijavi se',
          onCtaPressed: () => context.go('/login'),
        ),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Omiljeni proizvodi'),
        actions: const [AppHomeButton()],
      ),
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
          final rawList = snap.data ?? [];
          final list = rawList
              .where((p) => favoritesProvider.isFavorite(p.id))
              .toList();
          if (list.isNotEmpty) {
            _warmupProductImages(list);
          }
          if (list.isEmpty) {
            return AppEmptyState(
              motif: RusticMotif.basket,
              icon: Icons.favorite_border,
              title: 'Lista želja je još prazna',
              subtitle:
                  'Klikni srce na proizvodu koji ti se dopao i naći ćeš ga ovde.',
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availWidth = constraints.maxWidth;
                    final int columns;
                    final double extent;
                    final double spacing;
                    final EdgeInsets padding;

                    if (availWidth >= 1100) {
                      columns = 4;
                      extent = 280;
                      spacing = 10;
                      padding = const EdgeInsets.all(12);
                    } else if (availWidth >= 800) {
                      columns = 3;
                      extent = 280;
                      spacing = 10;
                      padding = const EdgeInsets.all(12);
                    } else if (availWidth >= 520) {
                      columns = 2;
                      extent = 275;
                      spacing = 8;
                      padding = const EdgeInsets.all(10);
                    } else {
                      columns = availWidth >= 340 ? 2 : 1;
                      extent = availWidth >= 340 ? 265 : 270;
                      spacing = 8;
                      padding = const EdgeInsets.all(8);
                    }

                    return GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: padding,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: extent,
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
