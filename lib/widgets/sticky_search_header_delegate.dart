import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/amazon_theme.dart';
import '../core/responsive.dart';

class StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isWide;
  final VoidCallback onTapSearch;

  StickySearchHeaderDelegate({
    required this.isWide,
    required this.onTapSearch,
  });

  @override
  double get minExtent => isWide ? 0 : 54;

  @override
  double get maxExtent => isWide ? 0 : 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (isWide) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: AmazonColors.getCanvas(context).withValues(alpha: 0.85),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: GestureDetector(
                onTap: onTapSearch,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      width: 1.2,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Icon(
                        Icons.search,
                        size: 20,
                        color: isDark
                            ? AmazonColors.darkTextSecondary
                            : AmazonColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pretraži domaću hranu, sireve, med, meso, voće...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AmazonColors.darkTextSecondary
                                : AmazonColors.textSecondary,
                          ),
                        ),
                      ),
                      // Amazon Signature Search Button (Warm Amber)
                      Container(
                        width: 44,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AmazonColors.amberLight,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(7),
                            bottomRight: Radius.circular(7),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.search,
                            size: 20,
                            color: AmazonColors.darkNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
