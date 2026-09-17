import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../category_icon.dart';

class CategoryGrid extends StatelessWidget {
  final List topCategories;
  final bool isWide;

  const CategoryGrid({
    super.key,
    required this.topCategories,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaledFontSize = textScaler.scale(12.0);
    final double cardHeight;
    if (scaledFontSize >= 16.5) {
      cardHeight = 62.0;
    } else if (scaledFontSize >= 13.5) {
      cardHeight = 52.0;
    } else {
      cardHeight = 46.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isWide ? 4 : (isLargeTablet ? 4 : (isSmallTablet ? 3 : 2)),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: cardHeight,
      ),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final cat = topCategories[index];
        final catColor = getFoodCategoryColor(cat.name);

        return Semantics(
          button: true,
          label: 'Kategorija ${cat.name}',
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                width: 1.0,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push('/categories/${cat.id}', extra: cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: buildCategoryIcon(
                          cat.icon,
                          size: 16,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.0,
                            color: isDark
                                ? AmazonColors.darkTextPrimary
                                : AmazonColors.textPrimary,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (scaledFontSize < 16.0)
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: isDark
                              ? AmazonColors.darkTextSecondary.withValues(alpha: 0.6)
                              : AmazonColors.textSecondary.withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

