import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../models/classified_category_model.dart';
import '../../../providers/classifieds_provider.dart';

/// Sekcija stabla kategorija u sidebar-u (aktivna kategorija, breadcrumbs, podkategorije).
class ClassifiedsSidebarCategoryTree extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final bool isDark;

  const ClassifiedsSidebarCategoryTree({
    super.key,
    required this.classifieds,
    required this.isDark,
  });

  IconData _getCategoryIcon(ClassifiedCategoryModel cat) {
    if (cat.iconData != Icons.category) {
      return cat.iconData;
    }
    final lowerId = cat.id.toLowerCase();
    final lowerName = cat.name.toLowerCase();

    // 1. Poljoprivreda i mehanizacija
    if (lowerId.contains('poljoprivred') ||
        lowerName.contains('poljoprivred') ||
        lowerId.contains('mehaniz') ||
        lowerName.contains('mehaniz') ||
        lowerId.contains('traktor') ||
        lowerName.contains('traktor')) {
      return Icons.agriculture;
    }

    // 2. Vozila i auto-moto
    if (lowerId.contains('vozil') ||
        lowerName.contains('vozil') ||
        lowerId.contains('auto') ||
        lowerName.contains('auto') ||
        lowerId.contains('motor') ||
        lowerName.contains('motor')) {
      return Icons.directions_car;
    }

    // 3. Mašine, alati i zanatstvo
    if (lowerId.contains('masin') ||
        lowerName.contains('mašin') ||
        lowerName.contains('masin') ||
        lowerId.contains('alat') ||
        lowerName.contains('alat') ||
        lowerId.contains('zanat') ||
        lowerName.contains('zanat')) {
      return Icons.handyman;
    }

    // 4. Dom, nameštaj i bašta
    if (lowerId.contains('dom') ||
        lowerName.contains('dom') ||
        lowerId.contains('basta') ||
        lowerName.contains('bašt') ||
        lowerId.contains('namestaj') ||
        lowerName.contains('nameštaj')) {
      return Icons.chair;
    }

    // 5. Mobilni telefoni i oprema
    if (lowerId.contains('telefon') ||
        lowerName.contains('telefon') ||
        lowerId.contains('mobiln') ||
        lowerName.contains('mobiln')) {
      return Icons.smartphone;
    }

    // 6. Računari i elektronika
    if (lowerId.contains('tehnik') ||
        lowerName.contains('tehnik') ||
        lowerId.contains('racunar') ||
        lowerName.contains('računar') ||
        lowerId.contains('elektronik') ||
        lowerName.contains('elektronik') ||
        lowerId.contains('laptop') ||
        lowerName.contains('laptop') ||
        lowerId.contains('kompjuter')) {
      return Icons.laptop;
    }

    // 7. Nekretnine
    if (lowerId.contains('nekretnin') ||
        lowerName.contains('nekretnin') ||
        lowerId.contains('stan') ||
        lowerName.contains('stan') ||
        lowerId.contains('kuc') ||
        lowerName.contains('kuć')) {
      return Icons.home_work;
    }

    // 8. Građevinarstvo i materijali
    if (lowerId.contains('gradjevin') ||
        lowerName.contains('građevin') ||
        lowerId.contains('materijal') ||
        lowerName.contains('materijal')) {
      return Icons.foundation;
    }

    // 9. Odeća, obuća i aksesoari
    if (lowerId.contains('odeca') ||
        lowerName.contains('odeć') ||
        lowerId.contains('obuca') ||
        lowerName.contains('obuć') ||
        lowerId.contains('aksesoar') ||
        lowerName.contains('aksesoar')) {
      return Icons.checkroom;
    }

    // 10. Sve za decu i bebe
    if (lowerId.contains('deca') ||
        lowerName.contains('dec') ||
        lowerId.contains('bebe') ||
        lowerName.contains('beb')) {
      return Icons.child_friendly;
    }

    // 11. Sport, lov, ribolov i hobi
    if (lowerId.contains('sport') ||
        lowerName.contains('sport') ||
        lowerId.contains('lov') ||
        lowerName.contains('lov') ||
        lowerId.contains('ribolov') ||
        lowerName.contains('ribolov') ||
        lowerId.contains('hobi') ||
        lowerName.contains('hobi')) {
      return Icons.sports_soccer;
    }

    // 12. Kućni ljubimci i domaće životinje
    if (lowerId.contains('ljubim') ||
        lowerName.contains('ljubim') ||
        lowerId.contains('zivotinj') ||
        lowerName.contains('životinj') ||
        lowerId.contains('stoka') ||
        lowerName.contains('stoka')) {
      return Icons.pets;
    }

    // 13. Usluge i poslovi
    if (lowerId.contains('uslug') ||
        lowerName.contains('uslug') ||
        lowerId.contains('posao') ||
        lowerName.contains('poslov')) {
      return Icons.work;
    }

    // 14. Zdravlje i lepota
    if (lowerId.contains('zdravlj') ||
        lowerName.contains('zdravlj') ||
        lowerId.contains('lepot') ||
        lowerName.contains('lepot') ||
        lowerId.contains('kozmetik') ||
        lowerName.contains('kozmetik')) {
      return Icons.spa;
    }

    // 15. Knjige i edukacija
    if (lowerId.contains('knjig') ||
        lowerName.contains('knjig') ||
        lowerId.contains('edukacij') ||
        lowerName.contains('edukacij') ||
        lowerId.contains('udzbenik') ||
        lowerName.contains('udžbenik')) {
      return Icons.menu_book;
    }

    // 16. Umetnost i rukotvorine
    if (lowerId.contains('umetnost') ||
        lowerName.contains('umetnost') ||
        lowerId.contains('rukotvor') ||
        lowerName.contains('rukotvor')) {
      return Icons.palette;
    }

    return Icons.category;
  }

  Widget _buildCountBadge(int count, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AmazonColors.darkAmberCta : AmazonColors.amber)
            : (isDark ? AmazonColors.darkCanvas : AmazonColors.borderGray.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive
              ? AmazonColors.darkNavy
              : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCatId = classifieds.selectedCategoryId;
    final activeCat = selectedCatId != null ? classifieds.findCategory(selectedCatId) : null;
    final breadcrumbs = classifieds.categoryBreadcrumbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'KATEGORIJE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
        ),
        if (selectedCatId != null) ...[
          // Povratak na sve kategorije
          InkWell(
            onTap: () => classifieds.selectCategory(null),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 14,
                    color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sve kategorije',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Prikaz breadcrumbs-a ako smo 2+ nivoa duboko
          if (breadcrumbs.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                breadcrumbs.map((b) => b.name).join(' › '),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ),
          ],

          // Trenutna aktivna kategorija
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AmazonColors.amber.withValues(alpha: 0.15)
                  : AmazonColors.amberLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AmazonColors.darkAmberCta.withValues(alpha: 0.6) : AmazonColors.amber,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                if (activeCat != null) ...[
                  Icon(
                    _getCategoryIcon(activeCat),
                    size: 15,
                    color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    activeCat?.name ?? 'Izabrana kategorija',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
                  ),
                ),
                if (activeCat != null && activeCat.adCount > 0)
                  _buildCountBadge(activeCat.adCount, isActive: true),
              ],
            ),
          ),

          // Podkategorije aktivne kategorije (ako postoje)
          if (activeCat != null && activeCat.subcategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: activeCat.subcategories.map((sub) {
                  return InkWell(
                    onTap: () => classifieds.selectCategory(sub.id),
                    borderRadius: BorderRadius.circular(6),
                    hoverColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                      child: Row(
                        children: [
                          Icon(
                            sub.iconData != Icons.category
                                ? sub.iconData
                                : Icons.subdirectory_arrow_right_rounded,
                            size: 13,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sub.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                              ),
                            ),
                          ),
                          if (sub.adCount > 0)
                            _buildCountBadge(sub.adCount, isActive: false),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ] else ...[
          // Prikaz svih glavnih kategorija (Discovery mode)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classifieds.categories.length,
            itemBuilder: (context, i) {
              final cat = classifieds.categories[i];
              return InkWell(
                onTap: () => classifieds.selectCategory(cat.id),
                borderRadius: BorderRadius.circular(6),
                hoverColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(cat),
                        size: 15,
                        color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                          ),
                        ),
                      ),
                      if (cat.adCount > 0)
                        _buildCountBadge(cat.adCount, isActive: false),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
