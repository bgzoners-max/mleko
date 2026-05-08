import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/app_error.dart';
import '../../models/home_products_data.dart';
import '../../models/product_model.dart';

import '../../providers/app_state.dart';

import '../app_error_retry.dart';
import '../cache_status_widget.dart';
import '../app_shimmer.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeProductsData>(
      initialData: latestHomeData,
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          final appError = AppError.from(snap.error);
          return SliverToBoxAdapter(
            child: AppErrorRetry(
              message: appError.getUserMessage(),
              detail: appError.code,
              onRetry: () => refreshController.add(null),
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: Breakpoints.horizontalPadding(context)),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                mainAxisExtent: 255,
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

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Breakpoints.horizontalPadding(context),
                  sectionSpacing,
                  Breakpoints.horizontalPadding(context),
                  12,
                ),
                child: Text(
                  newProducts.isNotEmpty
                      ? 'Najnoviji proizvodi'
                      : 'Poslednje dodato',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                  horizontal: Breakpoints.horizontalPadding(context)),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      isTabletLayout ? (isLargeTablet ? 3 : 2) : 2,
                  mainAxisSpacing: isTabletLayout ? 8 : 4,
                  crossAxisSpacing: isTabletLayout ? 8 : 4,
                  mainAxisExtent:
                      isTabletLayout ? (isLargeTablet ? 348 : 356) : 255,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = displayList[i];
                    final rating = ratings[product.id];
                    return HomeProductItem(
                      product: product,
                      salesCount: salesCounts[product.id] ?? 0,
                      canFavorite: canFavorite,
                      userId: user?.id,
                      avgRating: rating?.avg,
                      reviewCount: rating?.count,
                    );
                  },
                  childCount: displayList.take(6).length,
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
