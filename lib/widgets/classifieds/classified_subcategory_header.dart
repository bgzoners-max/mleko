import 'package:flutter/material.dart';
import '../../models/classified_category_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../theme/amazon_colors.dart';
import 'classified_subscription_chip.dart';

class ClassifiedSubcategoryHeader extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const ClassifiedSubcategoryHeader({
    super.key,
    required this.classifieds,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final crumbs = classifieds.categoryBreadcrumbs;
    if (crumbs.isEmpty) return const SizedBox.shrink();

    // Proveravamo da li je u putanji aktivna kategorija sa grupisanim sekcijama (npr. Automobili sa državama)
    ClassifiedCategoryModel? groupedParent;
    for (final node in crumbs.reversed) {
      if (!node.isRoot &&
          node.subcategories.where((s) => s.subcategories.isNotEmpty).length >= 2) {
        groupedParent = node;
        break;
      }
    }

    final ClassifiedCategoryModel activeParent = groupedParent ??
        (crumbs.last.subcategories.isNotEmpty
            ? crumbs.last
            : (crumbs.length >= 2 ? crumbs[crumbs.length - 2] : crumbs.last));

    if (activeParent.subcategories.isEmpty) return const SizedBox.shrink();

    final isAllInActiveParent = classifieds.selectedCategoryId == activeParent.id;
    final parentCategory = crumbs.length >= 2 ? crumbs[crumbs.length - 2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (crumbs.length > 1) ...[
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (parentCategory != null) ...[
                      InkWell(
                        onTap: () => classifieds.selectCategory(parentCategory.id),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new, size: 11, color: isDark ? AmazonColors.lightGreen : AmazonColors.link),
                              const SizedBox(width: 4),
                              Text(
                                'Nazad',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 14,
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ],
                    for (int i = 0; i < crumbs.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                        ),
                      if (i == crumbs.length - 1)
                        Text(
                          crumbs[i].name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => classifieds.selectCategory(crumbs[i].id),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              crumbs[i].name,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ] else ...[
            Text(
              'Podkategorije: ${crumbs.first.name}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ChoiceChip(
                    selected: isAllInActiveParent,
                    avatar: Icon(
                      activeParent.iconData,
                      size: 15,
                      color: isAllInActiveParent
                          ? AmazonColors.amberLight
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.navNavy),
                    ),
                    label: Text(
                      'Svi oglasi u „${activeParent.name}”',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAllInActiveParent ? FontWeight.bold : FontWeight.w500,
                        color: isAllInActiveParent
                            ? Colors.white
                            : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    selectedColor: AmazonColors.navNavy,
                    backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isAllInActiveParent
                            ? AmazonColors.navNavy
                            : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                        width: isAllInActiveParent ? 1.4 : 1.0,
                      ),
                    ),
                    onSelected: (_) => classifieds.selectCategory(activeParent.id),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClassifiedCategorySubscriptionChip(category: crumbs.last),
            ],
          ),
        ],
      ),
    );
  }
}
