import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/amazon_theme.dart';
import '../core/haptic.dart';
import '../models/product_model.dart';
import 'app_network_image.dart';

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
    final hasRating = avgRating != null && (reviewCount ?? 0) > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrowCard = constraints.maxWidth < 170;
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
        final contentHeight =
            onAddToOrder != null ? (isNarrowCard ? 104.0 : 112.0) : 72.0;
        final ratingHeight = hasRating ? 24.0 : 0.0;
        final imageHeight = (availableHeight - contentHeight - ratingHeight)
            .clamp(120.0, 220.0);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
        final borderColor = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
        final addToOrderLabel = isNarrowCard ? 'Dodaj' : 'Dodaj u porudžbinu';

        return Card(
          clipBehavior: Clip.antiAlias,
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            onTap: () =>
                withHaptic(() => context.push('/product/${product.id}')),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      product.imageUrls.isEmpty
                          ? ColoredBox(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported),
                            )
                          : AppNetworkImage.thumbnail(
                              imageUrl: product.imageUrls.first,
                              fit: BoxFit.cover,
                            ),
                      if (!product.isAvailable)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Nedostupno',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (onFavoriteToggle != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: IconButton(
                            tooltip: isFavorite == true
                                ? 'Ukloni iz omiljenih'
                                : 'Dodaj u omiljene',
                            icon: Icon(
                              isFavorite == true
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite == true
                                  ? Colors.red
                                  : Colors.white,
                              size: 24,
                            ),
                            onPressed: onFavoriteToggle != null
                                ? () => withHaptic(onFavoriteToggle!)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasRating)
                  Container(
                    height: ratingHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFFFFA41C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          avgRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
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
                SizedBox(
                  height: contentHeight,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AmazonColors.darkTextPrimary
                                : AmazonColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.priceFormatted,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFFFF6B6B)
                                : AmazonColors.dealRed,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (onAddToOrder != null) ...[
                          const Spacer(),
                          ElevatedButton(
                            onPressed: onAddToOrder != null
                                ? () => withHaptic(onAddToOrder!)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AmazonColors.amberLight,
                              foregroundColor: AmazonColors.darkNavy,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: AmazonColors.amberDark,
                                  width: 0.8,
                                ),
                              ),
                              minimumSize: const Size.fromHeight(28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              addToOrderLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AmazonColors.darkNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
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
      },
    );
  }
}
