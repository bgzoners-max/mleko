import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/classified_category_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../core/responsive.dart';
import 'classified_category_tiles.dart';

List<Widget> buildClassifiedSubcategoriesSlivers(
  BuildContext context,
  ClassifiedsProvider classifieds,
  ThemeData theme,
  ColorScheme colorScheme,
) {
  final isDark = theme.brightness == Brightness.dark;
  final crumbs = classifieds.categoryBreadcrumbs;
  if (crumbs.isEmpty) return const [];

  // Proveravamo da li je u putanji aktivna kategorija sa grupisanim sekcijama (npr. Automobili sa državama)
  ClassifiedCategoryModel? groupedParent;
  for (final node in crumbs.reversed) {
    if (!node.isRoot &&
        node.subcategories.where((s) => s.subcategories.isNotEmpty).length >= 2) {
      groupedParent = node;
      break;
    }
  }

  final isDesktop = Breakpoints.isDesktop(context);
  final gridCrossAxisCount = isDesktop
      ? 4
      : (Breakpoints.isLargeTablet(context) ? 3 : 2);

  if (groupedParent != null) {
    // ── GRUPISANI PRIKAZ PO DRŽAVAMA (prema crtežu korisnika: • NEMAČKA, • ITALIJA, • FRANCUSKA...) ──
    final slivers = <Widget>[];
    final groupsWithChildren = groupedParent.subcategories
        .where((sub) => sub.subcategories.isNotEmpty)
        .toList();
    final standaloneItems = groupedParent.subcategories
        .where((sub) => sub.subcategories.isEmpty)
        .toList();

    for (final group in groupsWithChildren) {
      final isGroupSelected = classifieds.selectedCategoryId == group.id;

      // 1. Naslov sekcije sa tačkom: • NEMAČKA, • ITALIJA, itd.
      slivers
        ..add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 14, 16, isDesktop ? 24 : 14, 6),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    if (isGroupSelected) {
                      classifieds.selectCategory(groupedParent!.id);
                    } else {
                      classifieds.selectCategory(group.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isGroupSelected ? AmazonColors.amber : AmazonColors.amber.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          group.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isGroupSelected
                                ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    if (isGroupSelected) {
                      classifieds.selectCategory(groupedParent!.id);
                    } else {
                      classifieds.selectCategory(group.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      isGroupSelected ? 'Poništi filter' : 'Svi (${group.name})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
        // 2. Mreža marki automobila za datu državu (Amazon compact 46px)
        ..add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 2),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              mainAxisExtent: 46,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                final brand = group.subcategories[idx];
                final isSelected = classifieds.selectedCategoryId == brand.id;

                return SubcategoryTile(
                  category: brand,
                  isSelected: isSelected,
                  hasChildren: false,
                  onTap: () {
                    if (isSelected) {
                      classifieds.selectCategory(groupedParent!.id);
                    } else {
                      classifieds.selectCategory(brand.id);
                    }
                  },
                );
              },
              childCount: group.subcategories.length,
            ),
          ),
        ),
      );
    }

    // 3. Dodatne kategorije (Džipovi, Oldtajmeri, Ostale marke)
    if (standaloneItems.isNotEmpty) {
      slivers
        ..add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 14, 18, isDesktop ? 24 : 14, 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AmazonColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'OSTALO / DODATNE KATEGORIJE',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
        ..add(
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 2),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCrossAxisCount,
              mainAxisExtent: 46,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                final item = standaloneItems[idx];
                final isSelected = classifieds.selectedCategoryId == item.id;

                return SubcategoryTile(
                  category: item,
                  isSelected: isSelected,
                  hasChildren: false,
                  onTap: () {
                    if (isSelected) {
                      classifieds.selectCategory(groupedParent!.id);
                    } else {
                      classifieds.selectCategory(item.id);
                    }
                  },
                );
              },
              childCount: standaloneItems.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }

  // ── STANDARDNI PRIKAZ (obična podkategorija sa jednom ravnom mrežom) ──
  final ClassifiedCategoryModel activeParent = crumbs.last.subcategories.isNotEmpty
      ? crumbs.last
      : (crumbs.length >= 2 ? crumbs[crumbs.length - 2] : crumbs.last);

  final items = activeParent.subcategories;
  if (items.isEmpty) return const [];

  return [
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxisCount,
          mainAxisExtent: 46,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final item = items[idx];
            final isSelected = classifieds.selectedCategoryId == item.id;

            return SubcategoryTile(
              category: item,
              isSelected: isSelected,
              hasChildren: item.subcategories.isNotEmpty,
              onTap: () {
                if (isSelected) {
                  classifieds.selectCategory(activeParent.id);
                } else {
                  classifieds.selectCategory(item.id);
                }
              },
            );
          },
          childCount: items.length,
        ),
      ),
    ),
  ];
}
