import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';

import '../supabase_config.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/bounce_tap_button.dart';
import '../widgets/skeleton.dart';

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
  late Future<Map<String, dynamic>> _reviewsFuture = _loadReviewsFuture();
  final _scrollController = ScrollController();
  final _moreFromSellerKey = GlobalKey();
  final _reviewsSectionKey = GlobalKey();
  bool _didScrollToReviews = false;

  Future<Map<String, dynamic>> _loadReviewsFuture() => Future.wait([
        ReviewsService().getAverageRatingForProduct(widget.productId),
        ReviewsService().getReviewsForProduct(widget.productId),
      ]).then((r) => {
            'avg': r[0],
            'reviews': r[1],
            'count': (r[1] as List).length,
          });

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            return const Center(child: Text('Proizvod nije pronađen.'));
          }
          _maybeScrollToReviewsOnLoad();
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: Breakpoints.maxContentWidth(context)),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 220,
                      child: product.imageUrls.isEmpty
                          ? ColoredBox(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported,
                                  size: 64),
                            )
                          : PageView.builder(
                              itemCount: product.imageUrls.length,
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: product.imageUrls[i],
                                fit: BoxFit.cover,
                                memCacheWidth: 800,
                                memCacheHeight: 500,
                                fadeInDuration: Duration.zero,
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 64),
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.priceFormatted,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          _RatingSummaryBadge(
                            reviewsFuture: _reviewsFuture,
                            onTap: _scrollToReviews,
                          ),
                          const SizedBox(height: 16),
                          _InfoBlock(
                              title: 'Opis', content: product.description),
                          _InfoBlock(
                              title: 'Minimalna porudžbina',
                              content: product.minOrderFormatted),
                          _InfoBlock(
                              title: 'Dostupna količina',
                              content: product.isAvailable
                                  ? product.availableFormatted
                                  : 'Nedostupno'),
                          _InfoBlock(
                              title: 'Lokacija', content: product.location),
                          _InfoBlock(
                              title: 'Način preuzimanja',
                              content: product.pickupOptions.join(', ')),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: BounceTapButton(
                              onPressed: product.isAvailable
                                  ? () => _addToCart(product)
                                  : null,
                              builder: (onPressed) => ElevatedButton(
                                onPressed:
                                    product.isAvailable ? onPressed : null,
                                child: Text(product.isAvailable
                                    ? 'Dodaj u korpu'
                                    : 'Trenutno nedostupno'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SellerInlineCartSection(sellerId: product.sellerId),
                          const SizedBox(height: 16),
                          _MoreFromSellerSection(
                              key: _moreFromSellerKey, product: product),
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
                                  onTap: () => context
                                      .push('/seller/${product.sellerId}'),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.store,
                                            size: 20,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Pogledaj profil proizvođača',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            final ctx = _moreFromSellerKey
                                                .currentContext;
                                            if (ctx != null) {
                                              Scrollable.ensureVisible(
                                                ctx,
                                                duration: const Duration(
                                                    milliseconds: 350),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Text(
                                            'Pogledaj druge proizvode ovog domaćinstva',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 16),
                        ],
                      ),
                    ),
                  ],
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
  final Future<Map<String, dynamic>> reviewsFuture;
  final VoidCallback onTap;

  const _RatingSummaryBadge({
    required this.reviewsFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: reviewsFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final avg = snap.data!['avg'] as double?;
        final count = snap.data!['count'] as int? ?? 0;
        if (avg == null || count == 0) return const SizedBox.shrink();

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 6),
                Text(
                  avg.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade800,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  _reviewsLabel(count),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
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

class _ProductReviewsSection extends StatelessWidget {
  final Future<Map<String, dynamic>> reviewsFuture;

  const _ProductReviewsSection({super.key, required this.reviewsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: reviewsFuture,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final avg = snap.data!['avg'] as double?;
        final reviews = (snap.data!['reviews'] as List?)?.cast<ReviewModel>() ?? <ReviewModel>[];
        if (avg == null && reviews.isEmpty) return const SizedBox.shrink();
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
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
            if (reviews.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...reviews.take(3).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                  i < r.rating ? Icons.star : Icons.star_border,
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
                                    color: Colors.grey.shade700))),
                      ],
                    ),
                  )),
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
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey.shade600)),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          size: 24),
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: item.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                      memCacheWidth: 140,
                                      memCacheHeight: 140,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image,
                                            size: 24),
                                      ),
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

    final cart = context.watch<CartProvider>();
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
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 20, color: Theme.of(context).colorScheme.primary),
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
                                  color: Colors.grey.shade700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
  }
}

