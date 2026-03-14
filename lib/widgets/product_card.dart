import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/haptic.dart';
import '../models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool isPopular;
  final double? avgRating;
  final int? reviewCount;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite,
    this.onFavoriteToggle,
    this.isPopular = false,
    this.avgRating,
    this.reviewCount,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  bool get _isNew {
    final diff = DateTime.now().difference(widget.product.createdAt).inDays;
    return diff < AppConstants.newProductDays;
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: kIsWeb && _isHovered ? 6 : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => withHaptic(() => context.push('/product/${widget.product.id}')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: widget.product.imageUrls.isEmpty
                  ? ColoredBox(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
                    )
                  : AppNetworkImage.thumbnail(
                      imageUrl: widget.product.imageUrls.first,
                      fit: BoxFit.cover,
                    ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.product.isAvailable) const _Badge(label: 'Nedostupno', color: Colors.grey),
                      if (!widget.product.isAvailable && (_isNew || widget.isPopular)) const SizedBox(width: 6),
                      if (_isNew) const _Badge(label: 'Novo', color: Colors.green),
                      if (_isNew && widget.isPopular) const SizedBox(width: 6),
                      if (widget.isPopular) const _Badge(label: 'Popularno', color: Colors.orange),
                    ],
                  ),
                ),
                if (widget.onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        widget.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                        color: widget.isFavorite == true ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: widget.onFavoriteToggle != null ? () => withHaptic(widget.onFavoriteToggle) : null,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.product.isDomestic)
                        const _Chip(label: 'Domaće', color: Colors.green),
                      if (widget.product.isDomestic) const SizedBox(width: 6),
                      _Chip(label: widget.product.category, color: Colors.brown.shade300),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.priceFormatted,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  if (widget.avgRating != null && (widget.reviewCount ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => withHaptic(() => context.push('/product/${widget.product.id}?reviews=1')),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              widget.avgRating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${widget.reviewCount})',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    widget.product.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => withHaptic(() => context.push('/product/${widget.product.id}')),
                      child: const Text('Pogledaj'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (kIsWeb) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: card,
      );
    }
    return card;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 1))),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Colors.white,
      fontSize: 11,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text(label, style: textStyle ?? const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}
