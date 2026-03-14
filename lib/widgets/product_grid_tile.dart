import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/haptic.dart';
import '../models/product_model.dart';

/// Kompaktna kartica za prikaz u gridu (npr. Mini prodavnica na profilu prodavca).
class ProductGridTile extends StatelessWidget {
  final ProductModel product;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAddToOrder;
  final double? avgRating;
  final int? reviewCount;

  const ProductGridTile({
    super.key,
    required this.product,
    this.isFavorite,
    this.onFavoriteToggle,
    this.onAddToOrder,
    this.avgRating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => withHaptic(() => context.push('/product/${product.id}')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrls.isEmpty
                  ? ColoredBox(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    )
                  : CachedNetworkImage(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      memCacheHeight: 250,
                      fadeInDuration: Duration.zero,
                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                    ),
                  if (!product.isAvailable)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Nedostupno', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton(
                        icon: Icon(
                          isFavorite == true ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite == true ? Colors.red : Colors.white,
                          size: 24,
                        ),
                        onPressed: onFavoriteToggle != null ? () => withHaptic(onFavoriteToggle!) : null,
                      ),
                    ),
                ],
              ),
            ),
            if (avgRating != null && (reviewCount ?? 0) > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      avgRating!.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($reviewCount)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.priceFormatted,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    if (onAddToOrder != null) ...[
                      const SizedBox(height: 6),
                      FilledButton.tonal(
                        onPressed: onAddToOrder != null ? () => withHaptic(onAddToOrder!) : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Dodaj u porudžbinu'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
