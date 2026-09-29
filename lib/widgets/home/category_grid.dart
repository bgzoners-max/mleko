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
      cardHeight = 64.0;
    } else if (scaledFontSize >= 13.5) {
      cardHeight = 54.0;
    } else {
      cardHeight = 50.0;
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                width: 1.0,
              ),
              boxShadow: AmazonColors.getCardShadow(context),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/categories/${cat.id}', extra: cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: buildCategoryIcon(
                          cat.icon,
                          size: 17,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isDark
                              ? AmazonColors.darkTextSecondary.withValues(alpha: 0.5)
                              : AmazonColors.textSecondary.withValues(alpha: 0.5),
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

