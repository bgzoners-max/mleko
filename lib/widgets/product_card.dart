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

  Widget _buildCard(BuildContext context, bool gridMode) {
    final imageChild = widget.product.imageUrls.isEmpty
        ? ColoredBox(
            color: Colors.grey.shade200,
            child: Icon(Icons.image_not_supported,
                size: 48, color: Colors.grey.shade400),
          )
        : AppNetworkImage.thumbnail(
            imageUrl: widget.product.imageUrls.first,
            fit: BoxFit.cover,
          );

    final image = Stack(
      fit: gridMode ? StackFit.expand : StackFit.loose,
      children: [
        Hero(
          tag: 'product_image_${widget.product.id}_0',
          child: gridMode
              ? imageChild
              : AspectRatio(aspectRatio: 16 / 10, child: imageChild),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.product.isAvailable)
                const _Badge(label: 'Nedostupno', color: Colors.grey),
              if (!widget.product.isAvailable && (_isNew || widget.isPopular))
                const SizedBox(width: 6),
              if (_isNew) const _Badge(label: 'Novo', color: Colors.green),
              if (_isNew && widget.isPopular) const SizedBox(width: 6),
              if (widget.isPopular)
                const _Badge(label: 'Popularno', color: Colors.orange),
            ],
          ),
        ),
        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              tooltip: widget.isFavorite == true
                  ? 'Ukloni iz omiljenih'
                  : 'Dodaj u omiljene',
              icon: Icon(
                widget.isFavorite == true
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.isFavorite == true ? Colors.red : Colors.white,
                size: 28,
              ),
              onPressed: widget.onFavoriteToggle != null
                  ? () => withHaptic(widget.onFavoriteToggle)
                  : null,
            ),
          ),
      ],
    );

    final textContent = Padding(
      padding: EdgeInsets.all(gridMode ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Kategorija kao mali tekst (ne chip) u grid modu — štedi prostor
          Text(
            widget.product.category,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.product.sellerIsVerified) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Proveren prodavac',
                  child: Icon(Icons.verified,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.priceFormatted,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (widget.avgRating != null && (widget.reviewCount ?? 0) > 0) ...[
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                  '${widget.avgRating!.toStringAsFixed(1)} (${widget.reviewCount})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 3),
          Text(
            widget.product.location,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!gridMode) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => withHaptic(
                    () => context.push('/product/${widget.product.id}')),
                child: const Text('Pogledaj'),
              ),
            ),
          ],
        ],
      ),
    );

    final card = AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Card(
        elevation: _isHovered ? 8 : 1,
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          enabled: true,
          label: 'Proizvod ${widget.product.name}. Cena ${widget.product.priceFormatted}.',
          child: InkWell(
            onTap: () => withHaptic(() => context.push('/product/${widget.product.id}')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (gridMode) 
                  Expanded(child: image) 
                else 
                  image,
                textContent,
              ],
            ),
          ),
        ),
      ),
    );

    return card;
  }

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) {
        // Ako roditelj daje ograničenu visinu (grid) → grid mod sa Spacer-om
        // Ako je visina neograničena (lista) → normalni mod
        final gridMode = constraints.maxHeight.isFinite;
        return _buildCard(context, gridMode);
      },
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
