import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/amazon_theme.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../models/home_products_data.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/favorites_provider.dart';
import '../../services/services.dart';
import '../../utils/animations.dart';

import '../app_empty_state.dart';
import '../app_error_retry.dart';
import '../guest_auth_prompt.dart';
import '../cache_status_widget.dart';
import '../product_card.dart';
import '../app_shimmer.dart';

import 'category_grid.dart';
import 'home_side_panel.dart';
import 'map_card.dart';
import 'seller_dashboard_sliver.dart';
import 'sellers_near_you_section.dart';

class HomeWideLayout extends StatelessWidget {
  final List topCategories;
  final bool isSeller;
  final Future<SellerStats>? sellerStatsFuture;
  final Stream<HomeProductsData> stream;
  final HomeProductsData? latestHomeData;
  final String? selectedRegion;
  final StreamController<void> refreshController;
  final void Function(List<ProductModel>) warmupCarouselImages;
  final double productGridExtent;
  final double compactSpacing;
  final double sectionSpacing;
  final double sidePanelSpacing;
  final Widget categoryHeader;
  final VoidCallback onSearchTap;

  const HomeWideLayout({
    super.key,
    required this.topCategories,
    required this.isSeller,
    required this.sellerStatsFuture,
    required this.stream,
    required this.latestHomeData,
    required this.selectedRegion,
    required this.refreshController,
    required this.warmupCarouselImages,
    required this.productGridExtent,
    required this.compactSpacing,
    required this.sectionSpacing,
    required this.sidePanelSpacing,
    required this.categoryHeader,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              categoryHeader,
              SizedBox(height: compactSpacing),
              CategoryGrid(topCategories: topCategories, isWide: true),
              if (isSeller) ...[
                SizedBox(height: compactSpacing),
                FadeInSlide(
                  delay: const Duration(milliseconds: 200),
                  child: RepaintBoundary(
                    child: SellerDashboardSliver(
                      statsFuture: sellerStatsFuture,
                    ),
                  ),
                ),
              ],
              SizedBox(height: sectionSpacing),
              StreamBuilder<HomeProductsData>(
                initialData: latestHomeData,
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError && !snap.hasData) {
                    final appError = AppError.from(snap.error);
                    return AppErrorRetry(
                      message: appError.getUserMessage(),
                      detail: appError.code,
                      onRetry: () => refreshController.add(null),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Breakpoints.isDesktop(context) ? 4 : 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: productGridExtent,
                      ),
                      itemCount: 4,
                      itemBuilder: (_, __) => const ProductCardSkeleton(),
                    );
                  }
                  final list = snap.data?.products ?? [];
                  final salesCounts = snap.data?.salesCounts ?? {};
                  final ratings = snap.data?.ratings ?? {};
                  final newProducts = list
                      .where((p) =>
                          DateTime.now().difference(p.createdAt).inDays <
                          AppConstants.newProductDays)
                      .toList();
                  final displayList =
                      newProducts.isNotEmpty ? newProducts : list;
                  warmupCarouselImages(displayList);
                  final user =
                      context.select<AppState, UserModel?>((s) => s.user);
                  final canFavorite = user != null && !user.isGuest;
                  if (displayList.isEmpty) {
                    final isSeller = user != null && user.isSeller;
                    return FadeInSlide(
                      delay: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 24),
                        child: AppEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'Nema proizvoda za prikaz',
                          subtitle:
                              'Proizvodite domaći sir, med, meso ili zimnicu? Otvorite svoju online tezgu besplatno i privucite lokalne kupce.',
                          ctaLabel: isSeller ? 'Dodaj novi proizvod' : 'Otvorite besplatnu tezgu',
                          ctaIcon: Icons.add_business_outlined,
                          onCtaPressed: () {
                            if (user == null || user.isGuest) {
                              showGuestAuthPrompt(
                                context,
                                title: 'Otvaranje online tezge',
                                message:
                                    'Registrujte se ili prijavite da biste postavili svoje domaće proizvode i započeli prodaju direktno kupcima.',
                                icon: Icons.storefront_rounded,
                              );
                            } else if (isSeller) {
                              context.push('/add-product');
                            } else {
                              context.push('/becoming-seller');
                            }
                          },
                        ),
                      ),
                    );
                  }
                  return FadeInSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            newProducts.isNotEmpty
                                ? 'Najnoviji proizvodi'
                                : 'Poslednje dodato',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AmazonColors.darkTextPrimary
                                  : AmazonColors.textPrimary,
                            ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Breakpoints.isDesktop(context)
                                ? 4
                                : Breakpoints.productGridColumns(context),
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            mainAxisExtent: productGridExtent,
                          ),
                          itemCount: displayList.take(8).length,
                          itemBuilder: (context, i) {
                            final product = displayList[i];
                            final rating = ratings[product.id];
                            return Selector<FavoritesProvider, bool>(
                              selector: (_, fav) => fav.isFavorite(product.id),
                              builder: (_, isFavorite, __) => ProductCard(
                                product: product,
                                isPopular: (salesCounts[product.id] ?? 0) >=
                                    AppConstants.popularProductMinSales,
                                isFavorite: canFavorite ? isFavorite : null,
                                onFavoriteToggle: canFavorite
                                    ? () => context
                                        .read<FavoritesProvider>()
                                        .toggle(user.id, product.id)
                                    : null,
                                avgRating: rating?.avg,
                                reviewCount: rating?.count,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: compactSpacing),
                        CacheStatusIndicator(
                          onRefresh: () => refreshController.add(null),
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(width: sectionSpacing),
        Expanded(
          flex: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amazon search bar
              InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      width: 1.0,
                    ),
                    boxShadow: AmazonColors.getCardShadow(context),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search,
                        size: 20,
                        color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pretražite domaću hranu, proizvode...',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        height: 42,
                        width: 44,
                        decoration: BoxDecoration(
                          color: AmazonColors.amberLight,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                          border: Border(
                            left: BorderSide(
                              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.search,
                            size: 20,
                            color: AmazonColors.darkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sidePanelSpacing),
              FadeInSlide(
                delay: const Duration(milliseconds: 400),
                child: RepaintBoundary(
                  child: HomeSidePanel(
                    homeProductsStream: stream,
                    initialData: latestHomeData,
                    isSeller: isSeller,
                  ),
                ),
              ),
              if (selectedRegion != null) ...[
                SizedBox(height: sectionSpacing),
                FadeInSlide(
                  delay: const Duration(milliseconds: 500),
                  child: RepaintBoundary(
                    child: SellersNearYouSection(region: selectedRegion!),
                  ),
                ),
              ],
              SizedBox(height: sectionSpacing),
              const FadeInSlide(
                delay: Duration(milliseconds: 600),
                child: RepaintBoundary(child: MapCard()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
