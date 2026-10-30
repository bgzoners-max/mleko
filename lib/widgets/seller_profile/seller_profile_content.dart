import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../app_back_button.dart';

import 'seller_classifieds_grid.dart';
import 'seller_farm_gallery_section.dart';
import 'seller_order_draft_bar.dart';
import 'seller_product_grid.dart';
import 'seller_profile_header.dart';
import 'seller_reviews_section.dart';
import 'seller_safety_strip.dart';
import 'seller_story_section.dart';
import 'seller_tags_row.dart';

class SellerProfileContent extends StatefulWidget {
  final UserModel seller;

  const SellerProfileContent({super.key, required this.seller});

  @override
  State<SellerProfileContent> createState() => _SellerProfileContentState();
}

class _SellerProfileContentState extends State<SellerProfileContent> {
  int _selectedTab = 0; // 0: Mini prodavnica, 1: Oglasi, 2: Recenzije

  @override
  Widget build(BuildContext context) {
    final seller = widget.seller;
    final draftCount = context.select<CartProvider, int>(
      (cart) => cart.getSellerDraft(seller.id).length,
    );
    final sellerName = seller.farmName ?? 'Prodavnica';
    final isOwnProfile =
        context.select<AppState, bool>((app) => app.user?.id == seller.id);
    final isDesktop = Breakpoints.isDesktop(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isWide = Breakpoints.useTwoPaneLayout(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: Text(sellerName),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Uredi profil',
              onPressed: () => context.push('/profile/edit'),
            ),
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
          const AppHomeButton(),
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

                      // STATS (ugled / poverenje - zajedničko za celu prodavnicu i oglase)
                      SizedBox(height: isSmallTablet ? 10 : 8),
                      SellerSafetyStrip(seller: seller),

                      // Galerija i Priča
                      if (seller.farmGalleryUrls.isNotEmpty) ...[
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        SellerFarmGallerySection(urls: seller.farmGalleryUrls),
                      ],
                      if (seller.sellerStory != null &&
                          seller.sellerStory!.isNotEmpty) ...[
                        SizedBox(height: isSmallTablet ? 14 : 16),
                        SellerStorySection(story: seller.sellerStory!),
                      ],

                      SizedBox(height: isSmallTablet ? 16 : 20),

                      // VIZUELNI PREKLOPNIK SEKCIJA (Segmented Bar)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildTabButton(
                                  context: context,
                                  index: 0,
                                  icon: Icons.storefront_rounded,
                                  label: 'Mini prodavnica',
                                  activeColor: isDark
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF2E7D32),
                                  isSelected: _selectedTab == 0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildTabButton(
                                  context: context,
                                  index: 1,
                                  icon: Icons.campaign_outlined,
                                  label: 'Mali oglasi',
                                  activeColor: isDark
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFFE65100),
                                  isSelected: _selectedTab == 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildTabButton(
                                  context: context,
                                  index: 2,
                                  icon: Icons.star_outline_rounded,
                                  label: 'Recenzije',
                                  activeColor: Colors.amber.shade800,
                                  isSelected: _selectedTab == 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // SADRŽAJ AKTIVNE SEKCIJE
                      if (isWide && _selectedTab != 2) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lijevo: Proizvodi (zelenkasta pozadina) ili Oglasi
                            Expanded(
                              flex: isLargeTablet ? 5 : 3,
                              child: _selectedTab == 0
                                  ? _buildGreenMiniProdavnicaContainer(
                                      context: context,
                                      isDark: isDark,
                                      child: SellerProductGrid(
                                        sellerId: seller.id,
                                        forceColumns: isDesktop ? 3 : 2,
                                      ),
                                    )
                                  : _buildOglasiContainer(
                                      context: context,
                                      isDark: isDark,
                                      child: SellerClassifiedsGrid(
                                        sellerId: seller.id,
                                        forceColumns: isDesktop ? 3 : 2,
                                      ),
                                    ),
                            ),
                            SizedBox(width: isLargeTablet ? 12 : 16),
                            // Desno: Brzi pregled recenzija na desktopu
                            Expanded(
                              flex: isLargeTablet ? 4 : 2,
                              child: SellerReviewsSection(sellerId: seller.id),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Prikaz po izabranom tabu
                        if (_selectedTab == 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildGreenMiniProdavnicaContainer(
                              context: context,
                              isDark: isDark,
                              child: SellerProductGrid(
                                sellerId: seller.id,
                                forceColumns: isSmallTablet ? 2 : null,
                              ),
                            ),
                          )
                        else if (_selectedTab == 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildOglasiContainer(
                              context: context,
                              isDark: isDark,
                              child: SellerClassifiedsGrid(
                                sellerId: seller.id,
                                forceColumns: isSmallTablet ? 2 : null,
                              ),
                            ),
                          )
                        else
                          SellerReviewsSection(sellerId: seller.id),
                      ],

                      const SizedBox(height: 100),
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

  /// Kontejner za Mini prodavnicu sa blago zelenkastom pozadinom!
  Widget _buildGreenMiniProdavnicaContainer({
    required BuildContext context,
    required bool isDark,
    required Widget child,
  }) {
    final bgColor = isDark ? const Color(0xFF132B1D) : const Color(0xFFEFF8F2);
    final borderColor =
        isDark ? const Color(0xFF1E462E) : const Color(0xFFC7E7D1);
    final headerColor =
        isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded, size: 22, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mini prodavnica domaće hrane',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: headerColor,
                        ),
                      ),
                      Text(
                        'Direktna ponuda gazdinstva i sveži domaći proizvodi',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Kontejner za Male oglase
  Widget _buildOglasiContainer({
    required BuildContext context,
    required bool isDark,
    required Widget child,
  }) {
    final headerColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, size: 22, color: headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mali oglasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: headerColor,
                        ),
                      ),
                      Text(
                        'Telefoni, tehnika, vozila, nameštaj, alati, nekretnine i sve ostalo',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (_selectedTab != index) {
          setState(() => _selectedTab = index);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
