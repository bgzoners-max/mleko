import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../core/haptic.dart';
import '../core/profile_display_names.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/product_reviews_data.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';

import '../models/user_model.dart';
import '../supabase_config.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/bounce_tap_button.dart';
import '../widgets/skeleton.dart';
import '../widgets/app_network_image.dart';

void _shareProduct(BuildContext context, ProductModel product) {
  final base = SupabaseConfig.shareBaseUrl.isNotEmpty
      ? SupabaseConfig.shareBaseUrl
      : (kIsWeb ? Uri.base.origin : 'https://mleko.rs');
  final url = '$base/product/${product.id}';
  final text =
      'Pogledaj ${product.name} – ${product.priceFormatted} na Naše Selo:\n$url';
  SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: product.name,
    ),
  );
}

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool scrollToReviews;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.scrollToReviews = false,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductModel?> _productFuture =
      ProductsService().getProduct(widget.productId);
  late Future<ProductReviewsData> _reviewsFuture = _loadReviewsFuture();
  Future<UserModel?>? _sellerFuture;
  String? _sellerFutureSellerId;

  Future<UserModel?> _ensureSellerFuture(String sellerId) {
    if (_sellerFutureSellerId != sellerId || _sellerFuture == null) {
      _sellerFutureSellerId = sellerId;
      _sellerFuture = UsersService().getUser(sellerId);
    }
    return _sellerFuture!;
  }

  Widget _buildSellerBanner(String sellerId) {
    return FutureBuilder<UserModel?>(
      future: _ensureSellerFuture(sellerId),
      builder: (context, snap) {
        final seller = snap.data;
        final name = seller?.farmName ?? seller?.displayName ?? '';
        if (name.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: InkWell(
                onTap: () => context.push('/seller/$sellerId'),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Icon(Icons.store_outlined,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  final _scrollController = ScrollController();
  final _moreFromSellerKey = GlobalKey();
  final _reviewsSectionKey = GlobalKey();
  bool _didScrollToReviews = false;

  // Gallery state
  late PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<ProductReviewsData> _loadReviewsFuture() async {
    final avg =
        await ReviewsService().getAverageRatingForProduct(widget.productId);
    final reviews =
        await ReviewsService().getReviewsForProduct(widget.productId);
    final names = await fetchProfileDisplayNames(reviews.map((r) => r.buyerId));
    return ProductReviewsData(
      averageRating: avg,
      reviews: reviews,
      buyerDisplayNames: names,
    );
  }

  void _scrollToReviews() {
    final ctx = _reviewsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _maybeScrollToReviewsOnLoad() {
    if (widget.scrollToReviews && !_didScrollToReviews) {
      _didScrollToReviews = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 500), _scrollToReviews);
      });
    }
  }

  void _retry() => setState(() {
        _productFuture = ProductsService().getProduct(widget.productId);
        _reviewsFuture = _loadReviewsFuture();
      });

  /// Gradi gallery sa slika + dots indicator
  Widget _buildGallery(ProductModel product, {double height = 220}) {
    final hasMultipleImages = product.imageUrls.length > 1;
    final isTablet = Breakpoints.isTabletOrLarger(context);

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: height,
              child: product.imageUrls.isEmpty
                  ? ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported, size: 64),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemCount: product.imageUrls.length,
                      itemBuilder: (_, i) => AppNetworkImage(
                        imageUrl: product.imageUrls[i],
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                        memCacheHeight: 500,
                        fadeInDuration: Duration.zero,
                      ),
                    ),
            ),
            // Left/right arrows na tablet
            if (isTablet && hasMultipleImages) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        size: 32,
                        color: Theme.of(context).colorScheme.surface,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      onPressed: _pageIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      splashRadius: 24,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        size: 32,
                        color: Theme.of(context).colorScheme.surface,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      onPressed: _pageIndex < product.imageUrls.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      splashRadius: 24,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasMultipleImages) _buildGalleryDots(product),
      ],
    );
  }

  /// Dots indicator za više slika
  Widget _buildGalleryDots(ProductModel product) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          product.imageUrls.length,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: _pageIndex == i ? 8 : 6,
              height: _pageIndex == i ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pageIndex == i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                border: _pageIndex == i
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartBlock(ProductModel product, {bool desktopMode = false}) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final button = SizedBox(
      width: desktopMode ? (isLargeTablet ? 220.0 : 200.0) : double.infinity,
      height: isLargeTablet ? 50 : 52,
      child: BounceTapButton(
        onPressed: product.isAvailable ? () => _addToCart(product) : null,
        builder: (onPressed) => ElevatedButton(
          onPressed: product.isAvailable ? onPressed : null,
          child: Text(
              product.isAvailable ? 'Dodaj u korpu' : 'Trenutno nedostupno'),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, desktopMode ? 16 : 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          desktopMode
              ? Align(alignment: Alignment.centerRight, child: button)
              : button,
          const SizedBox(height: 16),
          _SellerInlineCartSection(sellerId: product.sellerId),
        ],
      ),
    );
  }

  /// Gradi info sekciju (naziv, cena, opis, dugmići, itd.)
  Widget _buildInfoSection(ProductModel product, {bool includeCart = true}) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final infoPadding = Breakpoints.cardPadding(context);
    final titleSize = Breakpoints.adaptiveDouble(
      context,
      phone: 24,
      smallTabletValue: 27,
      largeTabletValue: 30,
      desktop: 30,
    );
    final priceSize = Breakpoints.adaptiveDouble(
      context,
      phone: 22,
      smallTabletValue: 24,
      largeTabletValue: 26,
      desktop: 26,
    );
    return Padding(
      padding: EdgeInsets.all(infoPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Breakpoints.heroTitleStyle(
              context,
              Theme.of(context).textTheme.headlineSmall,
            )?.copyWith(
              fontSize: titleSize,
              height: isLargeTablet ? 1.15 : 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.priceFormatted,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: priceSize,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _RatingSummaryBadge(
            reviewsFuture: _reviewsFuture,
            onTap: _scrollToReviews,
          ),
          const SizedBox(height: 16),
          _InfoBlock(title: 'Opis', content: product.description),
          _InfoBlock(
              title: 'Minimalna porudžbina',
              content: product.minOrderFormatted),
          _InfoBlock(
              title: 'Dostupna količina',
              content: product.isAvailable
                  ? product.availableFormatted
                  : 'Nedostupno'),
          _InfoBlock(title: 'Lokacija', content: product.location),
          _InfoBlock(
              title: 'Način preuzimanja',
              content: product.pickupOptions.join(', ')),
          const SizedBox(height: 16),
          if (includeCart) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: BounceTapButton(
                onPressed:
                    product.isAvailable ? () => _addToCart(product) : null,
                builder: (onPressed) => ElevatedButton(
                  onPressed: product.isAvailable ? onPressed : null,
                  child: Text(product.isAvailable
                      ? 'Dodaj u korpu'
                      : 'Trenutno nedostupno'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SellerInlineCartSection(sellerId: product.sellerId),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
          ],
          _MoreFromSellerSection(key: _moreFromSellerKey, product: product),
          const SizedBox(height: 16),
          _ProductReviewsSection(
            key: _reviewsSectionKey,
            reviewsFuture: _reviewsFuture,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/seller/${product.sellerId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.store,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Pogledaj profil proizvođača',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!product.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ovaj proizvod je trenutno nedostupan.',
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            final ctx = _moreFromSellerKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            'Pogledaj druge proizvode ovog domaćinstva',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _addToCart(ProductModel product) async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registruj se ili se prijavi da bi poslao porudžbinu.'),
        ),
      );
      context.go('/login');
      return;
    }

    final cart = context.read<CartProvider>();
    await cart.addForSeller(
      sellerId: product.sellerId,
      productId: product.id,
      quantity: product.minOrderKg,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Proizvod je dodat u korpu.'),
        action: SnackBarAction(
          label: 'Pregled',
          onPressed: () => context.push('/checkout-seller/${product.sellerId}'),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: 16,
          right: 16,
          left: MediaQuery.of(context).size.width - 400 - 16,
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ProductModel product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Breakpoints.isDesktop(context);
        final galleryFraction = isDesktop ? 0.60 : 0.52;
        final galleryWidth = constraints.maxWidth * galleryFraction;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSellerBanner(product.sellerId),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: galleryWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGallery(product, height: 480),
                      _buildCartBlock(product, desktopMode: true),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildInfoSection(product, includeCart: false),
                ),
              ],
            ),
            const Divider(height: 1, thickness: 1),
            _buildDesktopFooter(),
          ],
        );
      },
    );
  }

  Widget _buildDesktopFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TextButton(
            onPressed: () => context.push('/terms'),
            child: const Text('Uslovi korišćenja'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push('/privacy'),
            child: const Text('Politika privatnosti'),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ProductModel product) {
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSellerBanner(product.sellerId),
        _buildGallery(product, height: isSmallTablet ? 280 : 220),
        _buildInfoSection(product),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideLayout =
        Breakpoints.isLargeTablet(context) || Breakpoints.isDesktop(context);
    final maxWidth = Breakpoints.isDesktop(context)
        ? 980.0
        : (Breakpoints.isLargeTablet(context)
            ? 920.0
            : Breakpoints.maxContentWidth(context));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proizvod'),
        actions: [
          FutureBuilder<ProductModel?>(
            future: _productFuture,
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final p = snap.data!;
              return IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Podeli proizvod',
                onPressed: () => withHaptic(() => _shareProduct(context, p)),
              );
            },
          ),
          Builder(
            builder: (ctx) {
              final user = context.watch<AppState>().user;
              if (user == null || user.isGuest) return const SizedBox.shrink();
              return FutureBuilder<ProductModel?>(
                future: _productFuture,
                builder: (_, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final p = snap.data!;
                  return Selector<FavoritesProvider, bool>(
                    selector: (_, fav) => fav.isFavorite(p.id),
                    builder: (_, isFavorite, __) {
                      final favorites = ctx.read<FavoritesProvider>();
                      return IconButton(
                        tooltip: isFavorite
                            ? 'Ukloni iz omiljenih'
                            : 'Dodaj u omiljene',
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () =>
                            withHaptic(() => favorites.toggle(user.id, p.id)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<ProductModel?>(
        future: _productFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju proizvoda.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            );
          }
          if (!snap.hasData) {
            return const ProductDetailSkeleton();
          }
          final product = snap.data;
          if (product == null) {
            return const AppEmptyState(
              icon: Icons.search_off_outlined,
              title: 'Proizvod nije pronađen.',
              subtitle:
                  'Moguće je da je proizvod obrisan ili trenutno nije dostupan.',
            );
          }
          _maybeScrollToReviewsOnLoad();
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: RefreshIndicator(
                onRefresh: () async => _retry(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: isWideLayout
                      ? _buildDesktopLayout(product)
                      : _buildMobileLayout(product),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RatingSummaryBadge extends StatelessWidget {
  final Future<ProductReviewsData> reviewsFuture;
  final VoidCallback onTap;

  const _RatingSummaryBadge({
    required this.reviewsFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final badgePadding = EdgeInsets.symmetric(
      horizontal: Breakpoints.adaptiveDouble(
        context,
        phone: 12,
        smallTabletValue: 13,
        largeTabletValue: 14,
        desktop: 14,
      ),
      vertical: Breakpoints.adaptiveDouble(
        context,
        phone: 8,
        smallTabletValue: 9,
        largeTabletValue: 10,
        desktop: 10,
      ),
    );
    return FutureBuilder<ProductReviewsData>(
      future: reviewsFuture,
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final avg = snap.data!.averageRating;
        final count = snap.data!.count;
        if (avg == null || count == 0) return const SizedBox.shrink();

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: badgePadding,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star,
                    color: Colors.amber.shade700,
                    size: isLargeTablet ? 22 : 20),
                const SizedBox(width: 6),
                Text(
                  avg.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                        fontSize: isLargeTablet ? 19 : null,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  _reviewsLabel(count),
                  style: Breakpoints.supportingTextStyle(
                    context,
                    Theme.of(context).textTheme.bodySmall,
                    phone: 13,
                    largeTabletValue: 14,
                    desktop: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: isLargeTablet ? 20 : 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  String _reviewsLabel(int count) {
    if (count == 1) return '1 recenzija';
    if (count >= 2 && count <= 4) return '$count recenzije';
    return '$count recenzija';
  }
}

class _ProductReviewsSection extends StatefulWidget {
  final Future<ProductReviewsData> reviewsFuture;

  const _ProductReviewsSection({super.key, required this.reviewsFuture});

  @override
  State<_ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<_ProductReviewsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProductReviewsData>(
      future: widget.reviewsFuture,
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        final avg = data.averageRating;
        final reviews = data.reviews;
        final buyerNames = data.buyerDisplayNames;
        final scheme = Theme.of(context).colorScheme;
        if (avg == null && reviews.isEmpty) return const SizedBox.shrink();
        final visible = _showAll ? reviews : reviews.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recenzije',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (avg != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                  Text(avg.toStringAsFixed(1)),
                  Text(' (${reviews.length})',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...visible.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.push('/buyer/${r.buyerId}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline,
                                    size: 16, color: scheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    buyerNames[r.buyerId] ?? 'Kupac',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: scheme.primary,
                                        ),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    size: 18, color: scheme.primary),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(
                                      i < r.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      size: 14,
                                      color: Colors.amber.shade700)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(
                                    r.comment.isEmpty
                                        ? '(bez komentara)'
                                        : r.comment,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurface))),
                          ],
                        ),
                      ],
                    ),
                  )),
              if (reviews.length > 3)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll
                      ? 'Prikaži manje'
                      : 'Prikaži sve (${reviews.length})'),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final String content;

  const _InfoBlock({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(content, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _MoreFromSellerSection extends StatefulWidget {
  final ProductModel product;

  const _MoreFromSellerSection({super.key, required this.product});

  @override
  State<_MoreFromSellerSection> createState() => _MoreFromSellerSectionState();
}

class _MoreFromSellerSectionState extends State<_MoreFromSellerSection> {
  bool _expanded = false;
  Stream<List<ProductModel>>? _productsStream;
  String? _lastSellerId;

  void _ensureStream(String sellerId) {
    if (_lastSellerId == sellerId) return;
    _lastSellerId = sellerId;
    _productsStream = ProductsService().getProductsBySeller(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    _ensureStream(p.sellerId);
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final all =
            (snap.data ?? []).where((other) => other.id != p.id).toList();
        if (all.isEmpty) return const SizedBox.shrink();

        final visible = _expanded ? all : all.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Još iz ovog domaćinstva',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${all.length})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                ),
                const Spacer(),
                if (all.length > 3)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Prikaži manje' : 'Prikaži sve'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: visible
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/product/${item.id}'),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrls.isEmpty
                                  ? Container(
                                      width: 56,
                                      height: 56,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 24,
                                      ),
                                    )
                                  : AppNetworkImage.icon(
                                      imageUrl: item.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.priceFormatted,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}

class _SellerInlineCartSection extends StatelessWidget {
  final String sellerId;

  const _SellerInlineCartSection({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest || user.id == sellerId) {
      return const SizedBox.shrink();
    }

    final cart = context.read<CartProvider>();
    return Selector<CartProvider, String>(
      selector: (_, c) {
        final draft = c.getSellerDraft(sellerId);
        if (draft.isEmpty) return '';
        final entries = draft.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        // Stabilan fingerprint: rebuild samo kad se stvarno promeni draft ovog prodavca.
        return entries.map((e) => '${e.key}:${e.value}').join('|');
      },
      builder: (context, draftKey, _) {
        if (draftKey.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<({ProductModel product, double quantity})>>(
          future: cart.getProductsBySeller(sellerId),
          builder: (context, snap) {
            final items = snap.data ?? [];
            if (items.isEmpty) return const SizedBox.shrink();

            final total = items.fold<double>(
              0,
              (sum, e) => sum + e.product.pricePerKg * e.quantity,
            );

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tvoja korpa kod ovog domaćinstva',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.take(3).map((e) {
                    final p = e.product;
                    final step = p.quantityStep;
                    final minQty = p.minOrderKg;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.formatQuantity(e.quantity),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Smanji količinu',
                            icon: const Icon(Icons.remove, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: e.quantity <= minQty
                                ? null
                                : () {
                                    final next = e.quantity - step;
                                    if (next < minQty) return;
                                    cart.setQuantityForSeller(
                                      sellerId: sellerId,
                                      productId: p.id,
                                      quantity: next,
                                    );
                                  },
                          ),
                          IconButton(
                            tooltip: 'Povećaj količinu',
                            icon: const Icon(Icons.add, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              final next = e.quantity + step;
                              cart.setQuantityForSeller(
                                sellerId: sellerId,
                                productId: p.id,
                                quantity: next,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Ukloni iz korpe',
                            icon: const Icon(Icons.close, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              cart.removeFromSeller(
                                sellerId: sellerId,
                                productId: p.id,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 3)
                    Text(
                      '+${items.length - 3} proizvoda',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Ukupno za proizvode: ${total.toStringAsFixed(0)} RSD + dostava',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.push('/checkout-seller/$sellerId'),
                    child: const Text('Pošalji porudžbinu prodavcu'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
