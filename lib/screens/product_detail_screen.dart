import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/amazon_theme.dart';
import '../core/haptic.dart';
import '../core/profile_display_names.dart';
import '../core/responsive.dart';
import '../core/web_seo.dart';
import '../models/product_model.dart';
import '../models/product_reviews_data.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../services/services.dart';
import '../supabase_config.dart';
import '../utils/image_precache_utils.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_share_sheet.dart';
import '../widgets/navigation/desktop_header.dart';
import '../widgets/skeleton.dart';

import '../widgets/product/product_image_gallery.dart';
import '../widgets/product/product_info_section.dart';
import '../widgets/product/more_from_seller_section.dart';
import '../widgets/app_footer.dart';
import '../widgets/product/product_reviews_section.dart';

Future<void> _shareProduct(BuildContext context, ProductModel product) async {
  final rawBase = SupabaseConfig.shareBaseUrl.isNotEmpty
      ? SupabaseConfig.shareBaseUrl
      : (kIsWeb
          ? (Uri.base.origin == 'https://domacimarket.rs'
              ? 'https://www.domacimarket.rs'
              : Uri.base.origin)
          : 'https://www.domacimarket.rs');
  final base = rawBase.replaceAll(RegExp(r'/+$'), '');
  final url = '$base/p/${product.id}';
  final text =
      'Pogledaj ${product.name} – ${product.priceFormatted} na Domaćem marketu:';

  await showAppShareSheet(
    context,
    title: product.name,
    url: url,
    shareText: text,
    subject: product.name,
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
  Future<ProductModel?>? _productFuture;
  Future<ProductReviewsData>? _reviewsFuture;

  final _scrollController = ScrollController();
  final _moreFromSellerKey = GlobalKey();
  final _reviewsSectionKey = GlobalKey();
  bool _didScrollToReviews = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _productFuture ??=
        context.read<ProductsService>().getProduct(widget.productId);
    _reviewsFuture ??= _loadReviewsFuture();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    AppImageCache.clearMemoryCache();
    super.dispose();
  }

  Future<ProductReviewsData> _loadReviewsFuture() async {
    final reviewsService = context.read<ReviewsService>();
    final reviews = await reviewsService.getReviewsForProduct(widget.productId);
    final avg = ReviewsService.computeAverage(reviews.map((r) => r.rating));
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
        _productFuture =
            context.read<ProductsService>().getProduct(widget.productId);
        _reviewsFuture = _loadReviewsFuture();
      });

  void _setProductMetadata(ProductModel? product) {
    if (product == null) {
      setPageMetadata(
        title: 'Proizvod | Domaći Market',
        description:
            'Pogledajte detalje proizvoda i ponudu poljoprivrednih gazdinstava na Domaćem marketu.',
        path: '/product/${widget.productId}',
        type: 'product',
      );
      return;
    }

    setProductSeo(product);
  }

  Widget _buildDesktopLayout(ProductModel product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final galleryWidth =
            (constraints.maxWidth * 0.46).clamp(340.0, 520.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: galleryWidth,
                    child: ProductImageGallery(
                      product: product,
                      height: 420,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ProductInfoSection(
                      product: product,
                      reviewsFuture: _reviewsFuture!,
                      onScrollToReviews: _scrollToReviews,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 20),
              MoreFromSellerSection(
                key: _moreFromSellerKey,
                product: product,
              ),
              ProductReviewsSection(
                key: _reviewsSectionKey,
                reviewsFuture: _reviewsFuture!,
              ),
              const SizedBox(height: 20),
              const AppFooter(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductImageGallery(
          product: product,
          height: 270,
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ProductInfoSection(
            product: product,
            reviewsFuture: _reviewsFuture!,
            onScrollToReviews: _scrollToReviews,
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: MoreFromSellerSection(
            key: _moreFromSellerKey,
            product: product,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ProductReviewsSection(
            key: _reviewsSectionKey,
            reviewsFuture: _reviewsFuture!,
          ),
        ),
        const SizedBox(height: 16),
        const AppFooter(),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final isWideLayout = Breakpoints.useTwoPaneLayout(context);
    final maxWidth = isWideLayout
        ? Breakpoints.dataContentWidth(context)
        : Breakpoints.maxContentWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: isDesktop
          ? null
          : AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        backgroundColor:
            isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        foregroundColor:
            isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
            width: 1.0,
          ),
        ),
        title: Text(
          'Proizvod',
          style: TextStyle(
            color: isDark
                ? AmazonColors.darkTextPrimary
                : AmazonColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color:
              isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        ),
        actions: [
          FutureBuilder<ProductModel?>(
            future: _productFuture,
            builder: (_, snapshot) {
              return IconButton(
                icon: Icon(Icons.adaptive.share),
                tooltip: 'Podeli proizvod',
                onPressed: snapshot.hasData
                    ? () =>
                        withHaptic(() => _shareProduct(context, snapshot.data!))
                    : null,
              );
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: context.watch<CartProvider>().count > 0,
              label: Text('${context.watch<CartProvider>().count}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            tooltip: 'Korpa',
            onPressed: () => context.push('/cart'),
          ),
          Builder(
            builder: (ctx) {
              final user = context.watch<AppState>().user;
              if (user == null || user.isGuest) return const SizedBox.shrink();
              return FutureBuilder<ProductModel?>(
                future: _productFuture,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final product = snapshot.data!;
                  return Selector<FavoritesProvider, bool>(
                    selector: (_, fav) => fav.isFavorite(product.id),
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
                        onPressed: () => withHaptic(
                          () => favorites.toggle(user.id, product.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          const AppHomeButton(),
        ],
      ),
      body: Column(
        children: [
          if (isDesktop) const DesktopHeader(isStandalone: true),
          Expanded(
            child: FutureBuilder<ProductModel?>(
              future: _productFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppErrorRetry(
                    message: 'Greška pri učitavanju proizvoda.',
                    detail: snapshot.error?.toString(),
                    onRetry: _retry,
                  );
                }
                if (!snapshot.hasData) {
                  return const ProductDetailSkeleton();
                }
                final product = snapshot.data;
                if (product == null) {
                  return const AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'Proizvod nije pronađen.',
                    subtitle:
                        'Moguće je da je proizvod obrisan ili trenutno nije dostupan.',
                  );
                }
                _setProductMetadata(product);
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
          ),
        ],
      ),
    );
  }
}
