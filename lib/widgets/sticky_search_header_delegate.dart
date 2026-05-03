import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/design_system.dart';

class StickySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isWide;
  final VoidCallback onTapSearch;

  StickySearchHeaderDelegate({
    required this.isWide,
    required this.onTapSearch,
  });

  @override
  double get minExtent => isWide ? 0 : 64;

  @override
  double get maxExtent => isWide ? 0 : 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    if (isWide) return const SizedBox.shrink();
    final theme = Theme.of(context);
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: onTapSearch,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppDesign.radiusL),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, 
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Traži proizvode, proizvođače…',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchHeaderDelegate oldDelegate) =>
      isWide != oldDelegate.isWide;
}
