import 'package:flutter/material.dart';
import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/product_reviews_data.dart';

class RatingSummaryBadge extends StatelessWidget {
  final Future<ProductReviewsData> reviewsFuture;
  final VoidCallback onTap;

  const RatingSummaryBadge({
    super.key,
    required this.reviewsFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final badgePadding = EdgeInsets.symmetric(
      horizontal: Breakpoints.adaptiveDouble(
        context,
        phone: 12,
        smallTabletValue: 13,
        largeTabletValue: 14,
        desktop: 14,
      ),
      vertical: Breakpoints.adaptiveDouble(
        context,
        phone: 8,
        smallTabletValue: 9,
        largeTabletValue: 10,
        desktop: 10,
      ),
    );
    return FutureBuilder<ProductReviewsData>(
      future: reviewsFuture,
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
        final avg = snap.data!.averageRating;
        final count = snap.data!.count;
        if (avg == null || count == 0) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: badgePadding,
            decoration: BoxDecoration(
              color: isDark ? AmazonColors.darkCard : const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : const Color(0xFFFBD88B),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star,
                    color: const Color(0xFFFFA41C), // Amazon gold star
                    size: isLargeTablet ? 22 : 20),
                const SizedBox(width: 6),
                Text(
                  avg.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    fontSize: isLargeTablet ? 18 : 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _reviewsLabel(count),
                  style: Breakpoints.supportingTextStyle(
                    context,
                    Theme.of(context).textTheme.bodySmall,
                    phone: 13,
                    largeTabletValue: 14,
                    desktop: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: isLargeTablet ? 20 : 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }

  String _reviewsLabel(int count) {
    if (count == 1) return '1 recenzija';
    if (count >= 2 && count <= 4) return '$count recenzije';
    return '$count recenzija';
  }
}
