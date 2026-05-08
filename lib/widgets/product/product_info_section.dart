import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';
import '../../models/product_model.dart';
import '../../models/product_reviews_data.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../utils/animations.dart';
import 'more_from_seller_section.dart';
import 'product_cart_block.dart';
import 'product_info_block.dart';
import 'product_reviews_section.dart';
import 'rating_summary_badge.dart';

class ProductInfoSection extends StatelessWidget {
  final ProductModel product;
  final Future<ProductReviewsData> reviewsFuture;
  final VoidCallback onScrollToReviews;
  final GlobalKey moreFromSellerKey;
  final GlobalKey reviewsSectionKey;
  final bool includeCart;

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.reviewsFuture,
    required this.onScrollToReviews,
    required this.moreFromSellerKey,
    required this.reviewsSectionKey,
    this.includeCart = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final infoPadding = Breakpoints.cardPadding(context);
    final titleSize = Breakpoints.adaptiveDouble(
      context,
      phone: 24,
      smallTabletValue: 27,
      largeTabletValue: 30,
      desktop: 30,
    );
    final priceSize = Breakpoints.adaptiveDouble(
      context,
      phone: 22,
      smallTabletValue: 24,
      largeTabletValue: 26,
      desktop: 26,
    );

    return Padding(
      padding: EdgeInsets.all(infoPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Breakpoints.heroTitleStyle(
              context,
              Theme.of(context).textTheme.headlineSmall,
            )?.copyWith(
              fontSize: titleSize,
              height: isLargeTablet ? 1.15 : 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.priceFormatted,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: priceSize,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          RatingSummaryBadge(
            reviewsFuture: reviewsFuture,
            onTap: onScrollToReviews,
          ),
          const SizedBox(height: 16),
          FadeInSlide(
            delay: const Duration(milliseconds: 100),
            child: ProductInfoBlock(title: 'Opis', content: product.description),
          ),
          FadeInSlide(
            delay: const Duration(milliseconds: 150),
            child: ProductInfoBlock(
                title: 'Minimalna porudžbina',
                content: product.minOrderFormatted),
          ),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: ProductInfoBlock(
                title: 'Dostupna količina',
                content: product.isAvailable
                    ? product.availableFormatted
                    : 'Nedostupno'),
          ),
          FadeInSlide(
            delay: const Duration(milliseconds: 250),
            child: ProductInfoBlock(title: 'Lokacija', content: product.location),
          ),
          FadeInSlide(
            delay: const Duration(milliseconds: 300),
            child: ProductInfoBlock(
                title: 'Način preuzimanja',
                content: product.pickupOptions.join(', ')),
          ),
          const SizedBox(height: 16),
          if (includeCart) ...[
            FadeInSlide(
              delay: const Duration(milliseconds: 300),
              child: ProductCartBlock(
                product: product,
                desktopMode: false,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 16),
          ],
          MoreFromSellerSection(key: moreFromSellerKey, product: product),
          const SizedBox(height: 16),
          ProductReviewsSection(
            key: reviewsSectionKey,
            reviewsFuture: reviewsFuture,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/seller/${product.sellerId}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.store,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Pogledaj prodajni profil',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Builder(builder: (context) {
            final user = context.watch<AppState>().user;
            if (user != null && !user.isGuest && user.id == product.sellerId) {
              return const SizedBox.shrink();
            }

            return Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      if (user == null || user.isGuest) {
                        context.push('/login');
                        return;
                      }
                      try {
                        final convId = await context
                            .read<ChatService>()
                            .getOrCreateConversation(user.id, product.sellerId);
                        if (context.mounted) context.push('/chat/$convId');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(friendlyError(e)),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.chat_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Pošalji poruku prodavcu',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          if (!product.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ovaj proizvod je trenutno nedostupan.',
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            final ctx = moreFromSellerKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Text(
                            'Pogledaj druge proizvode ovog domaćinstva',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
