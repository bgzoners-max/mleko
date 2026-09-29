import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'
    show kIsWeb, consolidateHttpClientResponseBytes;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/skeleton.dart';

import '../widgets/product/product_image_gallery.dart';
import '../widgets/product/product_info_section.dart';
import '../widgets/product/more_from_seller_section.dart';
import '../widgets/product/product_reviews_section.dart';

Future<void> _shareProduct(BuildContext context, ProductModel product) async {
  final rawBase = SupabaseConfig.shareBaseUrl.isNotEmpty
      ? SupabaseConfig.shareBaseUrl
      : (kIsWeb ? Uri.base.origin : 'https://domacimarket.rs');
  final base = rawBase.replaceAll(RegExp(r'/+$'), '');
  final url = '$base/p/${product.id}';
  final text =
      'Pogledaj ${product.name} – ${product.priceFormatted} na Domaćem marketu:\n$url';

  // Ako nema slike ili smo na Webu, deli samo tekst i link
  if (product.imageUrls.isEmpty || kIsWeb) {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: product.name),
    );
    return;
  }

  try {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Priprema slike za deljenje...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Preuzimanje prve slike u memoriju
    final request =
        await HttpClient().getUrl(Uri.parse(product.imageUrls.first));
    final response = await request.close();
    final bytes = await consolidateHttpClientResponseBytes(response);

    // Deljenje fajla generisanog direktno iz memorije
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: product.name,
        files: [
          XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'proizvod.jpg'),
        ],
      ),
    );
  } catch (e, st) {
    unawaited(ErrorHandlerService().handleError(e,
        stackTrace: st, context: 'Share product image fallback'));
    // Fallback ako preuzimanje slike ne uspe (npr. loš internet)
    await SharePlus.instance.share(
      ShareParams(text: text, subject: product.name),
    );
  }
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
            (constraints.maxWidth * 0.44).clamp(320.0, 440.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Kompaktni glavni red: Galerija (levo) + Glavni info blok sa korpom (desno)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: galleryWidth,
                    child: ProductImageGallery(
                      product: product,
                      height: 380,
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

              // 2. Široka sekcija "Još iz ovog domaćinstva"
              MoreFromSellerSection(
                key: _moreFromSellerKey,
                product: product,
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 20),

              // 3. Široka sekcija "Ocene i utisci"
              ProductReviewsSection(
                key: _reviewsSectionKey,
                reviewsFuture: _reviewsFuture!,
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 1),
              _buildDesktopFooter(),
            ],
          ),
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
            onPressed: () => context.push('/uslovi-koriscenja'),
            child: const Text('Uslovi korišćenja'),
          ),
          TextButton(
            onPressed: () => context.push('/politika-privatnosti'),
            child: const Text('Politika privatnosti'),
          ),
        ],
      ),
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
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ProductReviewsSection(
            key: _reviewsSectionKey,
            reviewsFuture: _reviewsFuture!,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideLayout = Breakpoints.useTwoPaneLayout(context);
    final maxWidth = isWideLayout
        ? 1040.0
        : Breakpoints.maxContentWidth(context);
    _setProductMetadata(null);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        foregroundColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
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
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
        ),
        actions: [
          FutureBuilder<ProductModel?>(
            future: _productFuture,
            builder: (_, snap) {
              return IconButton(
                icon: Icon(Icons.adaptive.share),
                tooltip: 'Podeli proizvod',
                onPressed: snap.hasData
                    ? () => withHaptic(() => _shareProduct(context, snap.data!))
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
    );
  }
}
