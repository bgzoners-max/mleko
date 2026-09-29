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
  final GlobalKey? moreFromSellerKey;
  final GlobalKey? reviewsSectionKey;
  final bool includeCart;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.reviewsFuture,
    required this.onScrollToReviews,
    this.moreFromSellerKey,
    this.reviewsSectionKey,
    this.includeCart = true,
  });

  Widget _buildSpecTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
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
          // 1. Bedž / link do gazdinstva
          FutureBuilder<UserModel?>(
            future: context.read<UsersService>().getUser(product.sellerId),
            builder: (context, snap) {
              final seller = snap.data;
              final name =
                  seller?.farmName ?? seller?.displayName ?? 'Domaćinstvo';
              return InkWell(
                onTap: () => context.push('/seller/${product.sellerId}'),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 15, color: AmazonColors.link),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AmazonColors.link,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.sellerIsVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: Colors.blue),
                      ],
                      const Icon(Icons.chevron_right,
                          size: 15, color: AmazonColors.link),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // 2. Naziv proizvoda
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

          // 3. Cena i bedž dostupnosti (u istom redu)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                product.priceFormatted,
                style: TextStyle(
                  color:
                      isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
                  fontSize: isDesktop ? 24 : 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: product.isAvailable
                      ? (isDark
                          ? const Color(0xFF1E3A2F)
                          : const Color(0xFFE8F5E9))
                      : (isDark
                          ? const Color(0xFF3A2424)
                          : const Color(0xFFFFEBEE)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: product.isAvailable
                        ? (isDark
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFA5D6A7))
                        : (isDark
                            ? const Color(0xFFC62828)
                            : const Color(0xFFEF9A9A)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      product.isAvailable
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 13,
                      color: product.isAvailable
                          ? (isDark
                              ? const Color(0xFF81C784)
                              : const Color(0xFF2E7D32))
                          : (isDark
                              ? const Color(0xFFE57373)
                              : const Color(0xFFC62828)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.isAvailable
                          ? (product.availableKg > 0
                              ? 'Na stanju (${product.availableFormatted})'
                              : 'Dostupno')
                          : 'Rasprodato',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: product.isAvailable
                            ? (isDark
                                ? const Color(0xFF81C784)
                                : const Color(0xFF2E7D32))
                            : (isDark
                                ? const Color(0xFFE57373)
                                : const Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Ocene i utisci link
          RatingSummaryBadge(
            reviewsFuture: reviewsFuture,
            onTap: onScrollToReviews,
          ),
          const SizedBox(height: 14),

          // 5. Kompaktna 2x2 tabela karakteristika proizvoda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecTile(
                        context: context,
                        icon: Icons.shopping_basket_outlined,
                        label: 'Minimalno',
                        value: product.minOrderFormatted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecTile(
                        context: context,
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
                      child: _buildSpecTile(
                        context: context,
                        icon: Icons.location_on_outlined,
                        label: 'Lokacija',
                        value: product.location.isNotEmpty
                            ? product.location
                            : 'Srbija',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecTile(
                        context: context,
                        icon: Icons.local_shipping_outlined,
                        label: 'Preuzimanje',
                        value: product.pickupOptions.isNotEmpty
                            ? product.pickupOptions.join(', ')
                            : 'Dogovor',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Akcioni blok za kupovinu i kontakt
          ProductCartBlock(
            product: product,
            desktopMode: isDesktop,
          ),

          // 7. Opis proizvoda (samo ako postoji tekst)
          if (product.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
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
              product.description.trim(),
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
