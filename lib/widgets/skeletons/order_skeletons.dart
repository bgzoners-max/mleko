import 'package:flutter/material.dart';
import '../app_shimmer.dart';
import '../../core/design_system.dart';

/// Skeleton za listu porudžbina
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppDesign.spaceL,
        right: AppDesign.spaceL,
        top: AppDesign.spaceM,
        bottom: AppDesign.spaceL + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppDesign.spaceM),
        child: AppShimmer(
          child: Card(
            child: Padding(
              padding: AppDesign.paddingM,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                      AppDesign.boxM,
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBlock(width: 120, height: 14),
                            AppDesign.boxXS,
                            ShimmerBlock(width: 80, height: 12),
                          ],
                        ),
                      ),
                      const ShimmerBlock(width: 70, height: 24, borderRadius: 12),
                    ],
                  ),
                  AppDesign.boxM,
                  const Divider(height: 1),
                  AppDesign.boxM,
                  const ShimmerBlock(width: 180, height: 14),
                  AppDesign.boxS,
                  const ShimmerBlock(width: 100, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
