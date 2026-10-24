import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../providers/classifieds_provider.dart';
import '../classified_filter_bottom_sheets.dart';

/// Sekcija izbora lokacije u sidebar-u (grad, region, popularni gradovi).
class ClassifiedsSidebarLocationSection extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final bool isDark;

  const ClassifiedsSidebarLocationSection({
    super.key,
    required this.classifieds,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasCity = classifieds.selectedCity != null;
    final hasDistrict = classifieds.selectedDistrict != null;
    final hasSelection = hasCity || hasDistrict;

    String currentLoc = 'Sve lokacije u Srbiji';
    if (hasCity) {
      currentLoc = classifieds.selectedCity!;
    } else if (hasDistrict) {
      currentLoc = classifieds.selectedDistrict!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'LOKACIJA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
        ),
        InkWell(
          onTap: () => showClassifiedCityPickerSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: hasSelection
                  ? (isDark ? AmazonColors.amber.withValues(alpha: 0.15) : AmazonColors.amberLight.withValues(alpha: 0.3))
                  : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasSelection
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                width: hasSelection ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: hasSelection
                      ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                      : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    currentLoc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                      color: hasSelection
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                    ),
                  ),
                ),
                if (hasSelection)
                  InkWell(
                    onTap: () {
                      classifieds
                        ..selectCity(null)
                        ..selectDistrict(null);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Quick popular cities
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['Beograd', 'Novi Sad', 'Niš', 'Kragujevac'].map((city) {
            final isCitySelected = classifieds.selectedCity == city;
            return InkWell(
              onTap: () {
                if (isCitySelected) {
                  classifieds.selectCity(null);
                } else {
                  classifieds.selectCity(city);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCitySelected
                      ? (isDark ? AmazonColors.amber.withValues(alpha: 0.25) : AmazonColors.amberLight)
                      : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCitySelected
                        ? AmazonColors.amberDark
                        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                    width: isCitySelected ? 1.2 : 0.8,
                  ),
                ),
                child: Text(
                  city,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isCitySelected ? FontWeight.w700 : FontWeight.w500,
                    color: isCitySelected
                        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                        : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
