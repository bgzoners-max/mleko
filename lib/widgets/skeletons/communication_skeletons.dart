import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../app_shimmer.dart';

/// Skeleton za listu obaveštenja
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final baseColor = AppShimmer.getBaseColor(context);
    final highlightColor = AppShimmer.getHighlightColor(context);
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
                BoxDecoration(color: baseColor, shape: BoxShape.circle),
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
    final baseColor = AppShimmer.getBaseColor(context);
    final highlightColor = AppShimmer.getHighlightColor(context);
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
                BoxDecoration(color: baseColor, shape: BoxShape.circle),
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
    final baseColor = AppShimmer.getBaseColor(context);
    final highlightColor = AppShimmer.getHighlightColor(context);
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
                decoration: BoxDecoration(
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
    final baseColor = AppShimmer.getBaseColor(context);
    final highlightColor = AppShimmer.getHighlightColor(context);
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
