import 'package:flutter/material.dart';

import '../../models/home_products_data.dart';
import '../../utils/animations.dart';

import 'category_grid.dart';
import 'home_side_panel.dart';
import 'map_card.dart';
import 'sellers_near_you_section.dart';

class HomeNarrowTopSection extends StatelessWidget {
  final List topCategories;
  final bool isTabletLayout;
  final bool isLargeTablet;
  final double compactSpacing;
  final double sectionSpacing;
  final Stream<HomeProductsData> stream;
  final HomeProductsData? latestHomeData;
  final bool isSeller;
  final String? selectedRegion;
  final Widget categoryHeader;

  const HomeNarrowTopSection({
    super.key,
    required this.topCategories,
    required this.isTabletLayout,
    required this.isLargeTablet,
    required this.compactSpacing,
    required this.sectionSpacing,
    required this.stream,
    required this.latestHomeData,
    required this.isSeller,
    required this.selectedRegion,
    required this.categoryHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            categoryHeader,
            SizedBox(height: compactSpacing),
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: CategoryGrid(
                topCategories: topCategories,
                isWide: false,
              ),
            ),
          ],
        ),
        SizedBox(height: sectionSpacing),
        if (isTabletLayout) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isLargeTablet ? 6 : 5,
                child: RepaintBoundary(
                  child: HomeSidePanel(
                    homeProductsStream: stream,
                    initialData: latestHomeData,
                    isSeller: isSeller,
                  ),
                ),
              ),
              SizedBox(width: sectionSpacing),
              Expanded(
                flex: isLargeTablet ? 4 : 5,
                child: const RepaintBoundary(
                  child: MapCard(),
                ),
              ),
            ],
          ),
          if (selectedRegion != null) ...[
            SizedBox(height: sectionSpacing),
            RepaintBoundary(
              child: SellersNearYouSection(
                region: selectedRegion!,
              ),
            ),
          ],
        ] else ...[
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: RepaintBoundary(
              child: HomeSidePanel(
                homeProductsStream: stream,
                initialData: latestHomeData,
                isSeller: isSeller,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
