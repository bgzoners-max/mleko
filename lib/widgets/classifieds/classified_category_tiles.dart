import 'package:flutter/material.dart';

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
  return const Color(0xFF1B5E20);
}

/// Pravougaona 2-kolonska kartica podkategorije sa ikonicom i imenom
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC));

    final borderColor = isSelected
        ? colorScheme.primary
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final iconBgColor = isSelected
        ? colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.18)
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    final iconColor = isSelected
        ? colorScheme.primary
        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155));

    final textColor = isSelected
        ? colorScheme.primary
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (!isDark && !isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: category.brandLogoAsset != null ? Colors.white : iconBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: 1,
                ),
              ),
              child: category.brandLogoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        category.brandLogoAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(
                          category.iconData,
                          size: 20,
                          color: iconColor,
                        ),
                      ),
                    )
                  : Icon(
                      category.iconData,
                      size: 20,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13.5,
                        height: 1.2,
                        color: category.adCount == 0 && !isSelected
                            ? (isDark ? Colors.white60 : Colors.black54)
                            : textColor,
                      ),
                    ),
                  ),
                  if (category.adCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${category.adCount}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? colorScheme.primary
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                  size: 16,
                  color: isSelected
                      ? colorScheme.primary
                      : (isDark ? Colors.white54 : Colors.black38),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grid tile za kategoriju na discovery ekranu - organizovan identično kao na strani malih proizvođača
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
    final catColor = getClassifiedCategoryColor(category.name);

    return Semantics(
      button: true,
      label: 'Kategorija ${category.name}',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: catColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        color: catColor.withValues(alpha: 0.05),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.iconData,
                    size: 22,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
