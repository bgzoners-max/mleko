import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
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

  IconData _getCategoryIcon(String catId) {
    final lower = catId.toLowerCase();
    if (lower.contains('zivotinj') || lower.contains('stoka')) return Icons.pets_outlined;
    if (lower.contains('mehaniz') || lower.contains('traktor')) return Icons.agriculture_outlined;
    if (lower.contains('oprema') || lower.contains('alat')) return Icons.handyman_outlined;
    if (lower.contains('hrana') || lower.contains('pice')) return Icons.restaurant_outlined;
    if (lower.contains('seoski') || lower.contains('nekretnin')) return Icons.cottage_outlined;
    if (lower.contains('vozil') || lower.contains('auto')) return Icons.directions_car_outlined;
    if (lower.contains('uslug')) return Icons.business_center_outlined;
    return Icons.grid_view_rounded;
  }

  Widget _buildCountBadge(int count, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AmazonColors.amberDark : AmazonColors.amber)
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
                color: isDark ? AmazonColors.amberDark : AmazonColors.amber,
                width: 1,
              ),
            ),
            child: Row(
              children: [
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
                            Icons.subdirectory_arrow_right_rounded,
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
                        _getCategoryIcon(cat.id),
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
