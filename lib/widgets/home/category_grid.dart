import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/amazon_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaledFontSize = textScaler.scale(12.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1150) {
          crossAxisCount = 6;
        } else if (width >= 820) {
          crossAxisCount = 4;
        } else if (width >= 540) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        final double cardHeight;
        if (scaledFontSize >= 16.5) {
          cardHeight = 54.0;
        } else if (scaledFontSize >= 13.5) {
          cardHeight = 46.0;
        } else {
          cardHeight = 42.0;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
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
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AmazonColors.darkBorder
                        : AmazonColors.borderGray,
                    width: 1.0,
                  ),
                  boxShadow: AmazonColors.getCardShadow(context),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        context.push('/categories/${cat.id}', extra: cat),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: catColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: buildCategoryIcon(
                              cat.icon,
                              size: 15,
                              color: catColor,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: isDark
                                    ? AmazonColors.darkTextPrimary
                                    : AmazonColors.textPrimary,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
      },
    );
  }
}
