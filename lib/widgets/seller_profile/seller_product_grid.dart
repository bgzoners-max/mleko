import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import 'package:mleko/services/services.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/product_grid_tile.dart';
import '../../widgets/skeleton.dart';
import '../../utils/quantity_engine.dart';
import '../../services/core/analytics_service.dart';
import 'dart:async';

class SellerProductGrid extends StatefulWidget {
  final String sellerId;
  final int? forceColumns;

  const SellerProductGrid({super.key, required this.sellerId, this.forceColumns});

  @override
  State<SellerProductGrid> createState() => _SellerProductGridState();
}

class _SellerProductGridState extends State<SellerProductGrid> {
  Stream<List<ProductModel>>? _productsStream;
  String? _lastSellerId;
  Future<Map<String, ({double avg, int count})>>? _ratingsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ratingsFuture ??= context.read<ProductsService>().getProductRatings();
  }

  void _ensureStream(String sellerId) {
    if (_lastSellerId == sellerId) return;
    _lastSellerId = sellerId;
    _productsStream = context.read<ProductsService>().getProductsBySeller(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    _ensureStream(widget.sellerId);
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SellerProductListSkeleton(itemCount: 3);
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Ovaj prodavac još nema proizvoda',
              subtitle: 'Pogledajte druge proizvođače ili se vratite kasnije.',
              ctaLabel: 'Pretraži proizvode',
              ctaIcon: Icons.search,
              onCtaPressed: () => context.go('/'),
            ),
          );
        }
        return FutureBuilder<Map<String, ({double avg, int count})>>(
          future: _ratingsFuture,
          builder: (context, ratingsSnap) {
            final ratings = ratingsSnap.data ?? {};
            return LayoutBuilder(
              builder: (context, constraints) {
                final isLargeTablet = Breakpoints.isLargeTablet(context);
                final isSmallTablet = Breakpoints.isSmallTablet(context);
                final crossAxisCount = widget.forceColumns ??
                    Breakpoints.productGridColumns(context);
                const gridSpacing = 6.0;
                final tileWidth = (constraints.maxWidth -
                        (crossAxisCount - 1) * gridSpacing) /
                    crossAxisCount;
                final imageHeight = (tileWidth * 0.78).clamp(
                  isLargeTablet ? 132.0 : 120.0,
                  isLargeTablet ? 200.0 : (isSmallTablet ? 194.0 : 190.0),
                );
                final tileHeight = imageHeight +
                    (isLargeTablet ? 178.0 : (isSmallTablet ? 184.0 : 190.0));
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: tileHeight,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final p = list[i];
                    final canAddToOrder = () {
                      final u = ctx.read<AppState>().user;
                      return u != null &&
                          !u.isGuest &&
                          u.id != widget.sellerId &&
                          p.isAvailable;
                    }();
                    final ratingStats = ratings[p.id];
                    return Selector<FavoritesProvider, bool>(
                      selector: (_, fav) => fav.isFavorite(p.id),
                      builder: (_, isFavorite, __) {
                        final user = ctx.read<AppState>().user;
                        final canFavorite = user != null && !user.isGuest;
                        final favorites = ctx.read<FavoritesProvider>();
                        return ProductGridTile(
                          product: p,
                          isFavorite: canFavorite ? isFavorite : null,
                          onFavoriteToggle: canFavorite
                              ? () => favorites.toggle(user.id, p.id)
                              : null,
                          onAddToOrder: canAddToOrder
                              ? () {
                                  showModalBottomSheet<void>(
                                    context: ctx,
                                    builder: (sheetContext) => SellerAddToOrderSheet(
                                      product: p,
                                      sellerId: widget.sellerId,
                                      cart: ctx.read<CartProvider>(),
                                      onAdded: () {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                'Proizvod je dodat u porudžbinu.'),
                                            action: SnackBarAction(
                                              label: 'Pregled',
                                              onPressed: () => ctx.push(
                                                  '/checkout-seller/${widget.sellerId}'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              : null,
                          avgRating: ratingStats?.avg,
                          reviewCount: ratingStats?.count,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class SellerAddToOrderSheet extends StatefulWidget {
  final ProductModel product;
  final String sellerId;
  final CartProvider cart;
  final VoidCallback onAdded;

  const SellerAddToOrderSheet({
    super.key,
    required this.product,
    required this.sellerId,
    required this.cart,
    required this.onAdded,
  });

  @override
  State<SellerAddToOrderSheet> createState() => _SellerAddToOrderSheetState();
}

class _SellerAddToOrderSheetState extends State<SellerAddToOrderSheet> {
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minOrderKg;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final step = p.quantityStep;
    final max = p.availableKg;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(p.priceFormatted, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: _quantity <= p.minOrderKg
                    ? null
                    : () => setState(() {
                          final next = _quantity - step;
                          final raw = next < p.minOrderKg
                              ? p.minOrderKg
                              : next.clamp(p.minOrderKg, max);
                          _quantity = QuantityEngine.normalizeQuantity(
                            quantity: raw,
                            minQuantity: p.minOrderKg,
                            step: step,
                          );
                        }),
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Text(
                p.formatQuantity(_quantity),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: _quantity >= max
                    ? null
                    : () => setState(() => _quantity =
                        QuantityEngine.normalizeQuantity(
                          quantity: (_quantity + step).clamp(p.minOrderKg, max),
                          minQuantity: p.minOrderKg,
                          step: step,
                        )),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => withHaptic(() {
              widget.cart.addForSeller(
                sellerId: widget.sellerId,
                productId: p.id,
                quantity: _quantity,
                product: p,
              );
              unawaited(AnalyticsService().logAddToCart(p, _quantity));
              Navigator.of(context).pop();
              widget.onAdded();
            }),
            child: const Text('Dodaj u porudžbinu'),
          ),
        ],
      ),
    );
  }
}
