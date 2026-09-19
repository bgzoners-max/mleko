import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/amazon_theme.dart';
import '../core/constants.dart';
import '../core/haptic.dart';
import '../models/product_model.dart';
import 'app_network_image.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = _isHovered
        ? AmazonColors.amberDark
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);

    final hasValidImage = widget.product.imageUrls.isNotEmpty &&
        !widget.product.imageUrls.first.contains('placehold.co');

    final imageChild = !hasValidImage
        ? Container(
            color: isDark ? const Color(0xFF1E2632) : const Color(0xFFF3F3F3),
            child: Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: isDark ? Colors.white38 : AmazonColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          )
        : AppNetworkImage.thumbnail(
            imageUrl: widget.product.imageUrls.first,
            fit: BoxFit.cover,
            placeholder: Container(
              color: isDark ? const Color(0xFF1E2632) : const Color(0xFFF3F3F3),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: Container(
              color: isDark ? const Color(0xFF1E2632) : const Color(0xFFF3F3F3),
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 28,
                  color: isDark ? Colors.white38 : AmazonColors.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ),
          );

    final image = Stack(
      fit: gridMode ? StackFit.expand : StackFit.loose,
      children: [
        Hero(
          tag: 'product_image_${widget.product.id}_0',
          child: AnimatedScale(
            scale: _isHovered ? 1.03 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: gridMode
                ? SizedBox.expand(child: imageChild)
                : AspectRatio(aspectRatio: 1.25, child: imageChild),
          ),
        ),
        // Subtle top gradient overlay for badge legibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Badges top-left
        Positioned(
          top: 6,
          left: 6,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (!widget.product.isAvailable)
                const _AmazonBadge(
                  label: 'NEDOSTUPNO',
                  backgroundColor: AmazonColors.slate,
                ),
              if (_isNew)
                const _AmazonBadge(
                  label: 'NOVO',
                  backgroundColor: AmazonColors.green,
                ),
              if (widget.isPopular)
                const _AmazonBadge(
                  label: 'POPULARNO',
                  backgroundColor: AmazonColors.amber,
                  textColor: AmazonColors.darkNavy,
                ),
            ],
          ),
        ),
        // Favorite button top-right
        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 5,
            right: 5,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 17,
                  tooltip: widget.isFavorite == true
                      ? 'Ukloni iz omiljenih'
                      : 'Dodaj u omiljene',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      widget.isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(widget.isFavorite),
                      color: widget.isFavorite == true
                          ? const Color(0xFFFF4D4F)
                          : Colors.white,
                      size: 17,
                    ),
                  ),
                  onPressed: () => withHaptic(widget.onFavoriteToggle),
                ),
              ),
            ),
          ),
      ],
    );

    final textContent = Padding(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Kategorija (Amazon teal link style)
          Text(
            widget.product.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AmazonColors.link,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // 2. Naziv proizvoda + verifikovan nalog
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    height: 1.2,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.product.sellerIsVerified) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified,
                  size: 13,
                  color: AmazonColors.link,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // 3. Amazon Deal cena (B12704 bold crvena) + Ocena
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  widget.product.priceFormatted,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.avgRating != null && (widget.reviewCount ?? 0) > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 12,
                      color: Color(0xFFFFA41C), // Amazon star gold
                    ),
                    const SizedBox(width: 2.5),
                    Text(
                      '${widget.avgRating!.toStringAsFixed(1)} (${widget.reviewCount})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AmazonColors.darkTextSecondary
                            : AmazonColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),

          // 4. Lokacija i minimalna porudžbina
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 11.5,
                color: isDark
                    ? AmazonColors.darkTextSecondary
                    : AmazonColors.textSecondary,
              ),
              const SizedBox(width: 2.5),
              Expanded(
                child: Text(
                  widget.product.location,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AmazonColors.darkTextSecondary
                        : AmazonColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AmazonColors.darkBorder.withValues(alpha: 0.6)
                      : const Color(0xFFF0F2F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'min ${widget.product.minOrderFormatted}',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AmazonColors.darkTextSecondary
                        : AmazonColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // 5. Ako nije grid (npr. lista), prikaži Amazon dugme
          if (!gridMode) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AmazonColors.amberLight,
                  foregroundColor: AmazonColors.darkNavy,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: AmazonColors.amberDark, width: 0.8),
                  ),
                ),
                onPressed: () => withHaptic(
                    () => context.push('/product/${widget.product.id}')),
                child: const Text(
                  'Pogledaj detalje',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _isHovered ? -2.5 : 0, 0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: _isHovered ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.12)
                : Colors.black.withValues(alpha: _isHovered ? 0.08 : 0.025),
            blurRadius: _isHovered ? 8 : 3,
            offset: Offset(0, _isHovered ? 3 : 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        enabled: true,
        label:
            'Proizvod ${widget.product.name}. Cena ${widget.product.priceFormatted}.',
        child: InkWell(
          onTap: () =>
              withHaptic(() => context.push('/product/${widget.product.id}')),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (gridMode) Expanded(child: image) else image,
              textContent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = LayoutBuilder(
      builder: (context, constraints) {
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

class _AmazonBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _AmazonBadge({
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

