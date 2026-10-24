import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/design_system.dart';

/// Centralizovan Shimmer efekat koji se prilagođava temi aplikacije.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  static Color getBaseColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade800 : Colors.grey.shade300;
  }

  static Color getHighlightColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade100;
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: getBaseColor(context),
      highlightColor: getHighlightColor(context),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Jednostavan blok za skeleton loading.
class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius = AppDesign.radiusS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton za ProductCard grid stavku.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      clipBehavior: Clip.antiAlias,
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShimmerBlock(borderRadius: 0)),
            Padding(
              padding: AppDesign.paddingS,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 60, height: 10),
                  AppDesign.boxXS,
                  ShimmerBlock(width: 120, height: 14),
                  AppDesign.boxS,
                  ShimmerBlock(width: 80, height: 16),
                  AppDesign.boxS,
                  ShimmerBlock(width: 100, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton za listu stavki u korpi ili porudžbinama.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDesign.spaceL, vertical: AppDesign.spaceS),
      child: AppShimmer(
        child: Row(
          children: [
            ShimmerBlock(width: 50, height: 50, borderRadius: AppDesign.radiusS),
            AppDesign.boxM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 150, height: 14),
                  AppDesign.boxXS,
                  ShimmerBlock(width: 100, height: 12),
                ],
              ),
            ),
            ShimmerBlock(width: 60, height: 16),
          ],
        ),
      ),
    );
  }
}
