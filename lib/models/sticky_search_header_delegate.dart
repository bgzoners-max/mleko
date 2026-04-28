import 'package:flutter/material.dart';
import '../core/responsive.dart';

class StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isWide;
  final VoidCallback onTapSearch;

  StickySearchHeaderDelegate({
    required this.isWide,
    required this.onTapSearch,
  });

  @override
  double get minExtent => isWide ? 0 : 60;

  @override
  double get maxExtent => isWide ? 0 : 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (isWide) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              readOnly: true,
              onTap: onTapSearch,
              decoration: const InputDecoration(
                  hintText: 'Traži proizvode, proizvođače…',
                  prefixIcon: Icon(Icons.search)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchHeaderDelegate oldDelegate) =>
      isWide != oldDelegate.isWide;
}
