import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../models/home_products_data.dart';
import '../../models/product_model.dart';

import '../../providers/app_state.dart';

import '../app_empty_state.dart';
import '../app_error_retry.dart';
import '../guest_auth_prompt.dart';
import '../cache_status_widget.dart';
import '../app_shimmer.dart';
import '../organic_divider.dart';
import '../rustic_illustration.dart';
import '../staggered_reveal.dart';

import 'home_product_item.dart';
import 'map_card.dart';
import 'sellers_near_you_section.dart';

class HomeNarrowProductsSliver extends StatelessWidget {
  final Stream<HomeProductsData> stream;
  final HomeProductsData? latestHomeData;
  final StreamController<void> refreshController;
  final void Function(List<ProductModel>) warmupCarouselImages;
  final bool isTabletLayout;
  final bool isLargeTablet;
  final double sectionSpacing;
  final double compactSpacing;
  final String? selectedRegion;
  final VoidCallback onSearchTap;

  const HomeNarrowProductsSliver({
    super.key,
    required this.stream,
    required this.latestHomeData,
    required this.refreshController,
    required this.warmupCarouselImages,
    required this.isTabletLayout,
    required this.isLargeTablet,
    required this.sectionSpacing,
    required this.compactSpacing,
    required this.selectedRegion,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeProductsData>(
      initialData: latestHomeData,
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError && !snap.hasData) {
          final appError = AppError.from(snap.error);
          return SliverToBoxAdapter(
            child: AppErrorRetry(
              message: appError.getUserMessage(),
              detail: appError.code,
              onRetry: () => refreshController.add(null),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: Breakpoints.horizontalPadding(context)),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 265,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => const ProductCardSkeleton(),
                childCount: 4,
              ),
            ),
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
        final displayList = newProducts.isNotEmpty ? newProducts : list;
        warmupCarouselImages(displayList);
        final user = context.read<AppState>().user;
        final canFavorite = user != null && !user.isGuest;

        if (displayList.isEmpty) {
          final isSeller = user != null && user.isSeller;
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Breakpoints.horizontalPadding(context),
                vertical: sectionSpacing,
              ),
              child: AppEmptyState(
                motif: RusticMotif.field,
                icon: Icons.storefront_outlined,
                title: 'Još nema ponude u ovom kraju',
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

        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Prvi proizvod izlazi iz grida kao istaknuta "hero" kartica;
        // ostatak (max 5) ostaje u mreži — ukupan broj prikazanih je i dalje 6.
        final remaining = displayList.length - 1;
        final gridCount = remaining > 5 ? 5 : remaining;

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Breakpoints.horizontalPadding(context),
                  sectionSpacing,
                  Breakpoints.horizontalPadding(context),
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newProducts.isNotEmpty
                          ? 'Najnoviji proizvodi'
                          : 'Poslednje dodato',
                      style: AppFonts.display(
                        isDark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // "Prošivena" organska linija umesto strogog pravilnog razdelnika.
                    const SizedBox(width: 84, child: OrganicDivider()),
                  ],
                ),
              ),
            ),
            // ── Istaknuti (prvi) proizvod — puna širina, izvan uniformnog grida.
            // Uvodi asimetriju i vizuelni ritam; koristi postojeći "list" mod
            // ProductCard kartice (slika + sadržaj + dugme).
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: Breakpoints.horizontalPadding(context)),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: HomeProductItem(
                      product: displayList.first,
                      salesCount: salesCounts[displayList.first.id] ?? 0,
                      canFavorite: canFavorite,
                      userId: user?.id,
                      avgRating: ratings[displayList.first.id]?.avg,
                      reviewCount: ratings[displayList.first.id]?.count,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  Breakpoints.horizontalPadding(context),
                  12,
                  Breakpoints.horizontalPadding(context),
                  0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTabletLayout ? (isLargeTablet ? 3 : 2) : 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent:
                      isTabletLayout ? (isLargeTablet ? 300 : 310) : 265,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    // Indeks i+1 — prvi proizvod je prikazan kao istaknuta kartica.
                    final product = displayList[i + 1];
                    final rating = ratings[product.id];
                    // Kaskadni ulaz: mreža se "otvara" umesto da se pojavi odjednom.
                    return StaggeredReveal(
                      index: i,
                      child: HomeProductItem(
                        product: product,
                        salesCount: salesCounts[product.id] ?? 0,
                        canFavorite: canFavorite,
                        userId: user?.id,
                        avgRating: rating?.avg,
                        reviewCount: rating?.count,
                      ),
                    );
                  },
                  childCount: gridCount,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isTabletLayout && selectedRegion != null) ...[
                    SizedBox(height: sectionSpacing),
                    RepaintBoundary(
                      child: SellersNearYouSection(region: selectedRegion!),
                    ),
                  ],
                  if (!isTabletLayout) ...[
                    SizedBox(height: sectionSpacing),
                    const RepaintBoundary(child: MapCard()),
                  ],
                  SizedBox(height: compactSpacing),
                  CacheStatusIndicator(
                    onRefresh: () => refreshController.add(null),
                  ),
                  SizedBox(height: sectionSpacing),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
