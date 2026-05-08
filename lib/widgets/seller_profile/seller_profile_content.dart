import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../providers/cart_provider.dart';

import 'seller_farm_gallery_section.dart';
import 'seller_order_draft_bar.dart';
import 'seller_product_grid.dart';
import 'seller_profile_header.dart';
import 'seller_reviews_section.dart';
import 'seller_safety_strip.dart';
import 'seller_story_section.dart';
import 'seller_tags_row.dart';

class SellerProfileContent extends StatelessWidget {
  final UserModel seller;

  const SellerProfileContent({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final draftCount = context.select<CartProvider, int>(
      (cart) => cart.getSellerDraft(seller.id).length,
    );
    final sellerName = seller.farmName ?? 'Prodavnica';
    final isDesktop = Breakpoints.isDesktop(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isWide = Breakpoints.useTwoPaneLayout(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
        actions: [
          if (draftCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TextButton(
                  onPressed: () =>
                      context.push('/checkout-seller/${seller.id}'),
                  child: Text('Porudžbina ($draftCount)'),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          SellerOrderDraftBar(sellerId: seller.id, seller: seller),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = constraints.maxHeight;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide
                        ? (isDesktop ? 1120.0 : 980.0)
                        : Breakpoints.maxContentWidth(context),
                    minHeight: minHeight > 0 ? minHeight : 400,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HEADER / PROFIL
                      SellerProfileHeader(seller: seller),
                      if (seller.sellerTags.isNotEmpty) ...[
                        SizedBox(height: isSmallTablet ? 10 : 8),
                        SellerTagsRow(tags: seller.sellerTags),
                      ],

                      // STATS (ugled / poverenje)
                      SizedBox(height: isSmallTablet ? 10 : 8),
                      SellerSafetyStrip(seller: seller),

                      if (isWide) ...[
                        SizedBox(height: isLargeTablet ? 14 : 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lijevo: galerija + priča + mini prodavnica
                            Expanded(
                              flex: isLargeTablet ? 5 : 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (seller.farmGalleryUrls.isNotEmpty) ...[
                                    SellerFarmGallerySection(
                                        urls: seller.farmGalleryUrls),
                                    SizedBox(height: isLargeTablet ? 12 : 16),
                                  ],
                                  if (seller.sellerStory != null &&
                                      seller.sellerStory!.isNotEmpty) ...[
                                    SellerStorySection(
                                        story: seller.sellerStory!),
                                    SizedBox(height: isLargeTablet ? 12 : 16),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'Mini prodavnica',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SellerProductGrid(
                                    sellerId: seller.id,
                                    forceColumns: isDesktop ? 3 : 2,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isLargeTablet ? 12 : 16),
                            // Desno: recenzije
                            Expanded(
                              flex: isLargeTablet ? 4 : 2,
                              child: SellerReviewsSection(sellerId: seller.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ] else ...[
                        // Mobilni / tablet – postojeći stacked layout
                        if (seller.farmGalleryUrls.isNotEmpty) ...[
                          SizedBox(height: isSmallTablet ? 14 : 16),
                          SellerFarmGallerySection(urls: seller.farmGalleryUrls),
                        ],
                        if (seller.sellerStory != null &&
                            seller.sellerStory!.isNotEmpty) ...[
                          SizedBox(height: isSmallTablet ? 14 : 16),
                          SellerStorySection(story: seller.sellerStory!),
                        ],
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        SellerReviewsSection(sellerId: seller.id),
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Mini prodavnica',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SellerProductGrid(
                          sellerId: seller.id,
                          forceColumns: isSmallTablet ? 2 : null,
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
