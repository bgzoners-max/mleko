import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';
import '../../models/classified_category_model.dart';

/// Određuje prepoznatljivu boju za kategoriju oglasa na osnovu naziva.
Color getClassifiedCategoryColor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('vozil') || lower.contains('auto') || lower.contains('motor')) {
    return const Color(0xFF0288D1); // Vozila - Plava
  }
  if (lower.contains('nekretnin') || lower.contains('stan') || lower.contains('kuć')) {
    return const Color(0xFF1B5E20); // Nekretnine - Šumska zelena
  }
  if (lower.contains('poljoprivred') || lower.contains('traktor')) {
    return const Color(0xFF2E7D32); // Poljoprivreda - Sveža poljoprivredna zelena
  }
  if (lower.contains('mašin') || lower.contains('alat') || lower.contains('zanat')) {
    return const Color(0xFFE65100); // Mašine i alati - Zlatno narandžasta
  }
  if (lower.contains('telefon') || lower.contains('mobiln')) {
    return const Color(0xFF00897B); // Telefoni - Teal
  }
  if (lower.contains('tehnik') ||
      lower.contains('računar') ||
      lower.contains('laptop') ||
      lower.contains('tv')) {
    return const Color(0xFF5C6BC0); // Tehnika - Indigo
  }
  if (lower.contains('ljubim') ||
      lower.contains('životinj') ||
      lower.contains('pas') ||
      lower.contains('mačk')) {
    return const Color(0xFF8D6E63); // Ljubimci - Topla braon
  }
  if (lower.contains('dom') || lower.contains('bašt') || lower.contains('nameštaj')) {
    return const Color(0xFF0097A7); // Dom i bašta - Cijan
  }
  if (lower.contains('odeć') || lower.contains('obuć') || lower.contains('garderob')) {
    return const Color(0xFFAD1457); // Odeća i obuća - Bordo / rubin
  }
  if (lower.contains('sport') || lower.contains('hobi')) {
    return const Color(0xFFD84315); // Sport i hobi - Terakota
  }
  if (lower.contains('građevinarstv') || lower.contains('materijal')) {
    return const Color(0xFF546E7A); // Građevinarstvo - Čelik siva
  }
  if (lower.contains('uslug')) {
    return const Color(0xFF6A1B9A); // Usluge - Ljubičasta
  }
  return AmazonColors.navNavy;
}

/// Pravougaona 2-kolonska kartica podkategorije sa ikonicom i imenom (Amazon Compact)
class SubcategoryTile extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final bool isSelected;
  final bool hasChildren;
  final VoidCallback onTap;

  const SubcategoryTile({
    super.key,
    required this.category,
    required this.isSelected,
    this.hasChildren = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? (isDark
            ? AmazonColors.navNavy.withValues(alpha: 0.35)
            : AmazonColors.navNavy.withValues(alpha: 0.08))
        : (isDark ? AmazonColors.darkCard : AmazonColors.cardWhite);

    final borderColor = isSelected
        ? AmazonColors.amberDark
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);

    final iconBgColor = isSelected
        ? AmazonColors.amber.withValues(alpha: isDark ? 0.25 : 0.15)
        : (isDark ? const Color(0xFF131921) : const Color(0xFFF7F8F8));

    final iconColor = isSelected
        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
        : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.navNavy);

    final textColor = isSelected
        ? (isDark ? AmazonColors.amberLight : AmazonColors.link)
        : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: category.brandLogoAsset != null ? Colors.white : iconBgColor,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isSelected
                      ? AmazonColors.amberDark.withValues(alpha: 0.4)
                      : (isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle),
                  width: 0.8,
                ),
              ),
              child: category.brandLogoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(3.5),
                      child: Image.asset(
                        category.brandLogoAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          category.iconData,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                    )
                  : Icon(
                      category.iconData,
                      size: 18,
                      color: iconColor,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12.5,
                        letterSpacing: -0.1,
                        color: category.adCount == 0 && !isSelected
                            ? (isDark ? Colors.white54 : AmazonColors.textSecondary)
                            : textColor,
                      ),
                    ),
                  ),
                  if (category.adCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AmazonColors.amber.withValues(alpha: 0.18)
                            : (isDark
                                ? const Color(0xFF2E3A4B)
                                : const Color(0xFFF0F2F2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${category.adCount}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                              : (isDark
                                  ? AmazonColors.darkTextSecondary
                                  : AmazonColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasChildren)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: isSelected
                      ? AmazonColors.amberDark
                      : (isDark ? Colors.white54 : AmazonColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile za kategoriju na discovery ekranu u Amazon Marketplace compact stilu
class CategoryGridTile extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final VoidCallback onTap;

  const CategoryGridTile({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = getClassifiedCategoryColor(category.name);

    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final textColor = isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;

    return Semantics(
      button: true,
      label: 'Kategorija ${category.name}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category.iconData,
                    size: 18,
                    color: isDark ? catColor.withValues(alpha: 0.9) : catColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: -0.1,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 15,
                  color: isDark ? Colors.white38 : AmazonColors.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

