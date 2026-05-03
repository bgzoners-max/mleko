import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'app_shimmer.dart';
import '../core/design_system.dart';

const _shimmerBaseColor = Color(0xFFE0E0E0);
const _shimmerHighlightColor = Color(0xFFF5F5F5);

/// Skeleton za listu proizvoda (ProductCard stil)
class ProductListSkeleton extends StatelessWidget {
  const ProductListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
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
    const highlightColor = _shimmerHighlightColor;
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShimmerBlock(width: 120, height: 14),
                            AppDesign.boxXS,
                            const ShimmerBlock(width: 80, height: 12),
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

/// Skeleton za grid kategorija (2 kolone, card stil)
class CategoryGridSkeleton extends StatelessWidget {
  const CategoryGridSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                      color: baseColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                      color: baseColor, borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton za listu obaveštenja
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration:
                const BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          title: Container(
            height: 14,
            width: 160,
            decoration: BoxDecoration(
                color: baseColor, borderRadius: BorderRadius.circular(4)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              height: 12,
              width: 220,
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          trailing: Container(
            width: 48,
            height: 12,
            decoration: BoxDecoration(
                color: baseColor, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }
}

/// Skeleton za listu konverzacija
class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration:
                const BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          title: Container(
            height: 14,
            width: 130,
            decoration: BoxDecoration(
                color: baseColor, borderRadius: BorderRadius.circular(4)),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              height: 12,
              width: 200,
              decoration: BoxDecoration(
                  color: baseColor, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          trailing: Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
                color: baseColor, borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }
}

/// Skeleton za horizontalni red prodavaca (avatar + ime)
class SellerAvatarRowSkeleton extends StatelessWidget {
  const SellerAvatarRowSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return SizedBox(
      height: 100,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 52,
                height: 10,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 9,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton za chat poruke (naizmenični levi/desni oblačići)
class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    final widths = [160.0, 200.0, 130.0, 180.0, 140.0, 210.0, 100.0, 170.0];
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (_, i) {
          final isRight = i.isEven;
          final w = widths[i % widths.length];
          return Align(
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: w,
                height: 40,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton za profil kupca (avatar + stats + kartice recenzija)
class BuyerProfileSkeleton extends StatelessWidget {
  const BuyerProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const baseColor = _shimmerBaseColor;
    const highlightColor = _shimmerHighlightColor;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 13,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (_) => Column(
                        children: [
                          Container(
                            width: 40,
                            height: 20,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reviews card 1
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    2,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 13,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 11,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
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
          ),
          const SizedBox(height: 16),
          // Reviews card 2 (collapsed placeholder)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 160,
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
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
