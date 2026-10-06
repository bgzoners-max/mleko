import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../app_shimmer.dart';
import '../../core/design_system.dart';

const _shimmerBaseColor = Color(0xFFE0E0E0);
const _shimmerHighlightColor = Color(0xFFF5F5F5);

/// Skeleton za listu proizvoda (ProductCard stil)
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    return ListView.builder(
      padding: AppDesign.paddingL,
      itemCount: itemCount,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppDesign.spaceL),
        child: AppShimmer(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ColoredBox(color: baseColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 8),
                          Container(
                              width: 50,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                          width: double.infinity,
                          height: 18,
                          decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 12),
                      Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton za listu proizvoda prodavca (ListTile stil)
class SellerProductListSkeleton extends StatelessWidget {
  const SellerProductListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    return ListView.separated(
      padding: AppDesign.paddingL,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => AppDesign.boxM,
      itemBuilder: (_, __) => AppShimmer(
        child: Card(
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
            title: Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
            subtitle: Container(
              height: 12,
              width: 80,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
            trailing: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton za carousel proizvoda na Home ekranu
class ProductCarouselSkeleton extends StatelessWidget {
  const ProductCarouselSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 8),
                Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                width: MediaQuery.of(context).size.width * 0.7,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: baseColor,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: highlightColor,
                                  borderRadius: BorderRadius.circular(4))),
                          const SizedBox(height: 4),
                          Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                  color: highlightColor,
                                  borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton za detalj proizvoda
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 220,
                  child: ColoredBox(color: _shimmerBaseColor),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 22,
                        width: 120,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 14,
                        width: MediaQuery.of(context).size.width * 0.5,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 18,
                        width: 180,
                        decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 14,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: baseColor,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      height: 12,
                                      width: MediaQuery.of(context).size.width *
                                          0.3,
                                      decoration: BoxDecoration(
                                          color: baseColor,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
