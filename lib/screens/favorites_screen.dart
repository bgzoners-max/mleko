import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/services/services.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';
import '../models/classified_ad_model.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/favorites_provider.dart';
import '../utils/image_precache_utils.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/auth/guest_auth_buttons.dart';
import '../widgets/classifieds/classified_ad_card.dart';
import '../widgets/product_card.dart';
import '../widgets/rustic_illustration.dart';
import '../widgets/skeleton.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, this.initialTab});

  /// Opcioni početni tab iz URL query parametra (`/favorites?tab=classifieds`).
  final String? initialTab;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _favoritesService = FavoritesService();
  final _classifiedFavoritesService = ClassifiedAdFavoritesService();
  final _refreshController = StreamController<void>.broadcast();
  final _scrollController = ScrollController();

  late final TabController _tabController;

  /// Stream keširan da se na svakom rebuild-u ne kreira novi i ne ponovo učitavaju omiljeni.
  Stream<List<ProductModel>>? _favoritesStream;
  String? _streamUserId;

  List<ClassifiedAdModel> _savedAds = const [];
  bool _loadingSavedAds = false;
  String? _savedAdsError;
  String? _savedAdsUserId;

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

  void _ensureSavedAdsLoaded(String userId) {
    if (_savedAdsUserId == userId) return;
    _savedAdsUserId = userId;
    unawaited(_loadSavedAds(userId));
  }

  Future<void> _loadSavedAds(String userId) async {
    if (mounted) {
      setState(() {
        _loadingSavedAds = true;
        _savedAdsError = null;
      });
    }
    try {
      final ads = await _classifiedFavoritesService.getFavoriteAds(userId);
      if (!mounted) return;
      setState(() {
        _savedAds = ads;
        _loadingSavedAds = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savedAdsError = e.toString();
        _loadingSavedAds = false;
      });
    }
  }

  Future<void> _removeSavedAd(String userId, ClassifiedAdModel ad) async {
    final previous = List<ClassifiedAdModel>.from(_savedAds);
    unawaited(AppHaptics.light());
    setState(() {
      _savedAds = _savedAds.where((a) => a.id != ad.id).toList();
    });
    try {
      await _classifiedFavoritesService.removeFavorite(userId, ad.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oglas je uklonjen iz sačuvanih.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savedAds = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška pri uklanjanju oglasa. Pokušajte ponovo.'),
        ),
      );
    }
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
    _tabController = TabController(
      length: 2,
      initialIndex: widget.initialTab == 'classifieds' ? 1 : 0,
      vsync: this,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final targetIndex = widget.initialTab == 'classifieds' ? 1 : 0;
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
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
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _refreshController.close();
    super.dispose();
  }

  Future<void> _onRefreshProducts() async {
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppState s) => s.user);
    final favoritesProvider = context.watch<FavoritesProvider>();
    final isDesktop = Breakpoints.isDesktop(context);

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Sačuvano'),
          actions: const [AppHomeButton()],
        ),
        body: const AppEmptyState(
          motif: RusticMotif.basket,
          icon: Icons.favorite_outline,
          title: 'Prijavi se za listu želja',
          subtitle:
              'Sačuvaj omiljene proizvode i male oglase i pronađi ih na jednom mestu.',
          cta: GuestAuthButtons(useGoNavigation: true),
        ),
      );
    }

    _initStream(user.id);
    _ensureSavedAdsLoaded(user.id);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Sačuvano'),
        actions: const [AppHomeButton()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Proizvodi'),
            Tab(
              text: _savedAds.isNotEmpty
                  ? 'Sačuvani oglasi (${_savedAds.length})'
                  : 'Sačuvani oglasi',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(context, favoritesProvider, isDesktop),
          _buildClassifiedAdsTab(context, user.id, isDesktop),
        ],
      ),
    );
  }

  Widget _buildProductsTab(
    BuildContext context,
    FavoritesProvider favoritesProvider,
    bool isDesktop,
  ) {
    return StreamBuilder<List<ProductModel>>(
      stream: _favoritesStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return AppErrorRetry(
            message: 'Greška pri učitavanju omiljenih.',
            detail: snap.error?.toString(),
            onRetry: () => _refreshController.add(null),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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
          onRefresh: _onRefreshProducts,
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
                          final user = context.select((AppState s) => s.user);
                          final favorites = context.read<FavoritesProvider>();
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
    );
  }

  Widget _buildClassifiedAdsTab(
    BuildContext context,
    String userId,
    bool isDesktop,
  ) {
    if (_loadingSavedAds && _savedAds.isEmpty) {
      return const ProductListSkeleton();
    }

    if (_savedAdsError != null && _savedAds.isEmpty) {
      return AppErrorRetry(
        message: 'Greška pri učitavanju sačuvanih oglasa.',
        detail: _savedAdsError,
        onRetry: () => _loadSavedAds(userId),
      );
    }

    if (_savedAds.isEmpty) {
      return AppEmptyState(
        motif: RusticMotif.basket,
        icon: Icons.bookmark_border_rounded,
        title: 'Nema sačuvanih oglasa',
        subtitle:
            'Klikni „Prati“ na malom oglasu koji te zanima i lako ga pronađi ovde.',
        ctaLabel: 'Pretraži male oglase',
        ctaIcon: Icons.campaign_outlined,
        onCtaPressed: () => context.go('/classifieds'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadSavedAds(userId),
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
                extent = 305;
                spacing = 10;
                padding = const EdgeInsets.all(12);
              } else if (availWidth >= 800) {
                columns = 3;
                extent = 300;
                spacing = 10;
                padding = const EdgeInsets.all(12);
              } else if (availWidth >= 520) {
                columns = 2;
                extent = 295;
                spacing = 8;
                padding = const EdgeInsets.all(10);
              } else {
                columns = availWidth >= 340 ? 2 : 1;
                extent = availWidth >= 340 ? 285 : 290;
                spacing = 8;
                padding = const EdgeInsets.all(8);
              }

              return GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: padding,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  mainAxisExtent: extent,
                ),
                itemCount: _savedAds.length,
                itemBuilder: (_, index) {
                  final ad = _savedAds[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClassifiedAdCard(ad: ad),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.58),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Ukloni iz sačuvanih',
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            iconSize: 17,
                            onPressed: () => _removeSavedAd(userId, ad),
                            icon: const Icon(
                              Icons.favorite_rounded,
                              color: AmazonColors.badgeRed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
