import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../../models/product_reviews_data.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import 'product_cart_block.dart';
import 'rating_summary_badge.dart';

class ProductInfoSection extends StatelessWidget {
  final ProductModel product;
  final Future<ProductReviewsData> reviewsFuture;
  final VoidCallback onScrollToReviews;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.reviewsFuture,
    required this.onScrollToReviews,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Breakpoints.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SellerBadgeHeader(
            sellerId: product.sellerId,
            isVerified: product.sellerIsVerified,
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark
                  ? AmazonColors.darkTextPrimary
                  : AmazonColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _PriceAndAvailability(product: product, isDesktop: isDesktop),
          const SizedBox(height: 10),
          RatingSummaryBadge(
            reviewsFuture: reviewsFuture,
            onTap: onScrollToReviews,
          ),
          const SizedBox(height: 14),
          _ProductSpecsCard(product: product),
          const SizedBox(height: 16),
          ProductCartBlock(
            product: product,
            desktopMode: isDesktop,
          ),
          if (product.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _ProductDescription(description: product.description.trim()),
          ],
        ],
      ),
    );
  }
}

class _SellerBadgeHeader extends StatelessWidget {
  final String sellerId;
  final bool isVerified;

  const _SellerBadgeHeader({
    required this.sellerId,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: context.read<UsersService>().getUser(sellerId),
      builder: (context, snapshot) {
        final seller = snapshot.data;
        final farmDisplayName =
            seller?.farmName ?? seller?.displayName ?? 'Domaćinstvo';

        return InkWell(
          onTap: () => context.push('/seller/$sellerId'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 15,
                  color: AmazonColors.link,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    farmDisplayName,
                    style: const TextStyle(
                      color: AmazonColors.link,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, size: 14, color: Colors.blue),
                ],
                const Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: AmazonColors.link,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceAndAvailability extends StatelessWidget {
  final ProductModel product;
  final bool isDesktop;

  const _PriceAndAvailability({
    required this.product,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final badgeBackground = product.isAvailable
        ? (isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3A2424) : const Color(0xFFFFEBEE));

    final badgeBorderColor = product.isAvailable
        ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFFA5D6A7))
        : (isDark ? const Color(0xFFC62828) : const Color(0xFFEF9A9A));

    final badgeTextColor = product.isAvailable
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFFE57373) : const Color(0xFFC62828));

    final availabilityLabel = product.isAvailable
        ? (product.availableKg > 0
            ? 'Na stanju (${product.availableFormatted})'
            : 'Dostupno')
        : 'Rasprodato';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        Text(
          product.priceFormatted,
          style: TextStyle(
            color: isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
            fontSize: isDesktop ? 24 : 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: badgeBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                product.isAvailable
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 13,
                color: badgeTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                availabilityLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: badgeTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductSpecsCard extends StatelessWidget {
  final ProductModel product;

  const _ProductSpecsCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedLocation =
        product.location.isNotEmpty ? product.location : 'Srbija';
    final resolvedPickup = product.pickupOptions.isNotEmpty
        ? product.pickupOptions.join(', ')
        : 'Dogovor';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  icon: Icons.shopping_basket_outlined,
                  label: 'Minimalno',
                  value: product.minOrderFormatted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SpecTile(
                  icon: Icons.tune,
                  label: 'Korak',
                  value: product.formatQuantity(product.quantityStep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            thickness: 1,
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.05),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  icon: Icons.location_on_outlined,
                  label: 'Lokacija',
                  value: resolvedLocation,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SpecTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Preuzimanje',
                  value: resolvedPickup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black)
                .withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isDark
                ? AmazonColors.darkTextPrimary
                : AmazonColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductDescription extends StatelessWidget {
  final String description;

  const _ProductDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: (isDark ? Colors.white : Colors.black)
              .withValues(alpha: 0.07),
        ),
        const SizedBox(height: 12),
        Text(
          'Opis proizvoda',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AmazonColors.darkTextPrimary
                : AmazonColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
