import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../services/catalog/products_service.dart';
import 'search_category_pill.dart';

/// Unapređeni Desktop Filter Sidebar za Pijacu Hrane (Food Marketplace).
///
/// Pruža prečišćavanje po sortiranju, regionima porekla, dostupnosti,
/// tipu dostave i stablu kategorija domaće hrane.
class SearchFilterSidebar extends StatelessWidget {
  final ProductSort sort;
  final ValueChanged<ProductSort> onSortChanged;
  final String? region;
  final ValueChanged<String?> onRegionChanged;
  final bool? availableNow;
  final ValueChanged<bool?> onAvailableNowChanged;
  final List<dynamic> categories;
  final String? selectedCategory;
  final Map<String, int> categoryCounts;
  final ValueChanged<String?> onCategorySelected;

  const SearchFilterSidebar({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.region,
    required this.onRegionChanged,
    required this.availableNow,
    required this.onAvailableNowChanged,
    required this.categories,
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFiltered = region != null ||
        availableNow == true ||
        selectedCategory != null ||
        sort != ProductSort.dateDesc;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 24),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        children: [
          // ── 1. HEADER & RESET ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filteri',
                    style: AppFonts.display(
                      isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (isFiltered)
                InkWell(
                  onTap: () {
                    onRegionChanged(null);
                    onAvailableNowChanged(null);
                    onCategorySelected(null);
                    onSortChanged(ProductSort.dateDesc);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'Poništi sve',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AmazonColors.dealRed : Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 2. SORTIRANJE ──
          _buildSectionTitle('SORTIRAJ', isDark),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AmazonColors.darkCanvas : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProductSort>(
                isExpanded: true,
                value: sort,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                items: ProductSort.values.map((s) {
                  return DropdownMenuItem<ProductSort>(
                    value: s,
                    child: Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: s == sort ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) onSortChanged(val);
                },
              ),
            ),
          ),

          const SizedBox(height: 14),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 3. REGION POREKLA ──
          _buildSectionTitle('REGION POREKLA', isDark),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: region != null
                  ? (isDark ? AmazonColors.amber.withValues(alpha: 0.15) : AmazonColors.amberLight.withValues(alpha: 0.3))
                  : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: region != null
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                width: region != null ? 1.2 : 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: region,
                hint: Text(
                  'Svi regioni Srbije',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                  ),
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Svi regioni Srbije',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                      ),
                    ),
                  ),
                  ...AppConstants.regions.map((r) {
                    return DropdownMenuItem<String?>(
                      value: r,
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: onRegionChanged,
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Brzi tagovi najtraženijih regiona
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Šumadija', 'Vojvodina', 'Zapadna Srbija', 'Južna Srbija'].map((reg) {
              final isRegSelected = region == reg;
              return InkWell(
                onTap: () {
                  if (isRegSelected) {
                    onRegionChanged(null);
                  } else {
                    onRegionChanged(reg);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRegSelected
                        ? (isDark ? AmazonColors.amber.withValues(alpha: 0.25) : AmazonColors.amberLight)
                        : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRegSelected
                          ? AmazonColors.amberDark
                          : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                      width: isRegSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Text(
                    reg,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isRegSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isRegSelected
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 4. DOSTUPNOST I ISPORUKA ──
          _buildSectionTitle('DOSTUPNOST & ISPORUKA', isDark),
          InkWell(
            onTap: () {
              onAvailableNowChanged(availableNow == true ? null : true);
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(
                    availableNow == true ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 16,
                    color: availableNow == true
                        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                        : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🌱 Dostupno odmah za poručivanje',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: availableNow == true ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 5. KATEGORIJE HRANE ──
          _buildSectionTitle('KATEGORIJE HRANE', isDark),
          if (selectedCategory != null) ...[
            InkWell(
              onTap: () => onCategorySelected(null),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 14,
                      color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sve kategorije hrane',
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
          ],

          ...categories.map(
            (cat) {
              final isSelected = selectedCategory == cat.name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SearchCategoryPill(
                  label: cat.name,
                  count: categoryCounts[cat.name],
                  icon: cat.icon,
                  selected: isSelected,
                  fullWidth: true,
                  onTap: () {
                    onCategorySelected(isSelected ? null : cat.name);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray.withValues(alpha: 0.6),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
        ),
      ),
    );
  }
}
