import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_network_image.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/design_system.dart';
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
          child: Wrap(
            spacing: 4,
            children: [
              if (!widget.product.isAvailable)
                const _Badge(label: 'Nedostupno', color: Colors.grey),
              if (_isNew) const _Badge(label: 'Novo', color: Colors.green),
              if (widget.isPopular)
                const _Badge(label: 'Popularno', color: Colors.orange),
            ],
          ),
        ),
        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                tooltip: widget.isFavorite == true
                    ? 'Ukloni iz omiljenih'
                    : 'Dodaj u omiljene',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    widget.isFavorite == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    key: ValueKey(widget.isFavorite),
                    color:
                        widget.isFavorite == true ? Colors.red : Colors.white,
                    size: 26,
                  ),
                ),
                onPressed: widget.onFavoriteToggle != null
                    ? () => withHaptic(widget.onFavoriteToggle)
                    : null,
              ),
            ),
          ),
      ],
    );

    final textContent = Padding(
      padding: EdgeInsets.all(gridMode ? AppDesign.spaceS : AppDesign.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.product.category.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 9,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.product.sellerIsVerified) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified,
                    size: 14, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.product.priceFormatted,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
              if (widget.avgRating != null && (widget.reviewCount ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      widget.avgRating!.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.product.location,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InfoPill(
                icon: widget.product.isAvailable
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: widget.product.isAvailable ? 'Na stanju' : 'Nedostupno',
                color: widget.product.isAvailable
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              ),
              _InfoPill(
                icon: Icons.inventory_2_outlined,
                label: 'Min ${widget.product.minOrderFormatted}',
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          if (!gridMode) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.open_in_new,
                    size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Klikni za detalje proizvoda',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => withHaptic(
                    () => context.push('/product/${widget.product.id}')),
                child: const Text('Pogledaj detalje'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 13, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dodirni za detalje proizvoda',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesign.radiusL),
        border: Border.all(
          color: _isHovered
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: AnimatedScale(
        scale: _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: _isHovered ? 0 : 0.5,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            button: true,
            enabled: true,
            label:
                'Proizvod ${widget.product.name}. Cena ${widget.product.priceFormatted}.',
            child: InkWell(
              onTap: () => withHaptic(
                  () => context.push('/product/${widget.product.id}')),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (gridMode) Expanded(child: image) else image,
                  textContent,
                ],
              ),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
