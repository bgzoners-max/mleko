import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool isPopular;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite,
    this.onFavoriteToggle,
    this.isPopular = false,
  });

  bool get _isNew {
    final diff = DateTime.now().difference(product.createdAt).inDays;
    return diff < AppConstants.newProductDays;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: product.imageUrls.isEmpty
                  ? ColoredBox(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey.shade400),
                    )
                  : AppNetworkImage.thumbnail(
                      imageUrl: product.imageUrls.first,
                      fit: BoxFit.cover,
                    ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!product.isAvailable) const _Badge(label: 'Nedostupno', color: Colors.grey),
                      if (!product.isAvailable && (_isNew || isPopular)) const SizedBox(width: 6),
                      if (_isNew) const _Badge(label: 'Novo', color: Colors.green),
                      if (_isNew && isPopular) const SizedBox(width: 6),
                      if (isPopular) const _Badge(label: 'Popularno', color: Colors.orange),
                    ],
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite == true ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite == true ? Colors.red : Colors.white,
                        size: 28,
                      ),
                      onPressed: onFavoriteToggle,
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
                      if (product.isDomestic)
                        const _Chip(label: 'Domaće', color: Colors.green),
                      if (product.isDomestic) const SizedBox(width: 6),
                      _Chip(label: product.category, color: Colors.brown.shade300),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceFormatted,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.location,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => context.push('/product/${product.id}'),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}
