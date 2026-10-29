import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
import '../rustic_illustration.dart';

import 'home_paginated_products_shelf.dart';
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
        // Uvek prikazujemo sve proizvode, poređane od najnovijeg ka starijem
        final displayList = [...list]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

        final productGridExtent = isTabletLayout
            ? (isLargeTablet ? 300.0 : 310.0)
            : 265.0;

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Breakpoints.horizontalPadding(context),
                sectionSpacing,
                Breakpoints.horizontalPadding(context),
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: HomePaginatedProductsShelf(
                  products: displayList,
                  salesCounts: salesCounts,
                  ratings: ratings,
                  canFavorite: canFavorite,
                  userId: user?.id,
                  productGridExtent: productGridExtent,
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
