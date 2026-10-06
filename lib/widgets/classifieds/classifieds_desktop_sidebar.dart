import 'package:flutter/material.dart';

import '../../core/design_system.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import 'sidebar/classifieds_sidebar_attributes_section.dart';
import 'sidebar/classifieds_sidebar_category_tree.dart';
import 'sidebar/classifieds_sidebar_location_section.dart';
import 'sidebar/classifieds_sidebar_price_section.dart';

/// Desktop Sidebar filter panel za male oglase.
///
/// Pruža stablo kategorija, raspon cena u EUR, multi-select / pretragu lokacije,
/// stanje predmeta, tip oglašivača, hitno/istaknuto promocije i dinamičke atribute kategorija.
class ClassifiedsDesktopSidebar extends StatefulWidget {
  final ClassifiedsProvider classifieds;
  final TextEditingController? searchController;

  const ClassifiedsDesktopSidebar({
    super.key,
    required this.classifieds,
    this.searchController,
  });

  @override
  State<ClassifiedsDesktopSidebar> createState() => _ClassifiedsDesktopSidebarState();
}

class _ClassifiedsDesktopSidebarState extends State<ClassifiedsDesktopSidebar> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: widget.classifieds.minPrice != null
          ? widget.classifieds.minPrice!.toInt().toString()
          : '',
    );
    _maxPriceController = TextEditingController(
      text: widget.classifieds.maxPrice != null
          ? widget.classifieds.maxPrice!.toInt().toString()
          : '',
    );
  }

  @override
  void didUpdateWidget(ClassifiedsDesktopSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final minStr = widget.classifieds.minPrice != null
        ? widget.classifieds.minPrice!.toInt().toString()
        : '';
    final maxStr = widget.classifieds.maxPrice != null
        ? widget.classifieds.maxPrice!.toInt().toString()
        : '';
    if (_minPriceController.text != minStr) {
      _minPriceController.text = minStr;
    }
    if (_maxPriceController.text != maxStr) {
      _maxPriceController.text = maxStr;
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyPrice() {
    final minVal = double.tryParse(_minPriceController.text.trim());
    final maxVal = double.tryParse(_maxPriceController.text.trim());
    widget.classifieds.setPriceRange(minPrice: minVal, maxPrice: maxVal);
  }

  void _setQuickPrice(double? min, double? max) {
    _minPriceController.text = min != null ? min.toInt().toString() : '';
    _maxPriceController.text = max != null ? max.toInt().toString() : '';
    widget.classifieds.setPriceRange(minPrice: min, maxPrice: max);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.classifieds,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final classifieds = widget.classifieds;

        final isFiltered = classifieds.selectedCategoryId != null ||
            classifieds.selectedCity != null ||
            classifieds.selectedDistrict != null ||
            classifieds.minPrice != null ||
            classifieds.maxPrice != null ||
            classifieds.selectedCondition != null ||
            classifieds.selectedSellerType != null ||
            classifieds.selectedAttributes.isNotEmpty ||
            classifieds.onlyFeatured ||
            classifieds.onlyUrgent ||
            (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty);

        final catAttrs = ClassifiedAttributesEngine.getAttributesForCategory(
          classifieds.selectedCategoryId,
          breadcrumbs: classifieds.categoryBreadcrumbs,
        );

        return Material(
          color: Colors.transparent,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. HEADER FILTERS & RESET ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Filteri',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.display(
                                isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFiltered)
                      InkWell(
                        onTap: () {
                          widget.searchController?.clear();
                          _minPriceController.clear();
                          _maxPriceController.clear();
                          classifieds.clearAllFilters();
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

                const SizedBox(height: 14),
                _buildDivider(isDark),
                const SizedBox(height: 12),

                // ── 2. STABLO KATEGORIJA (CATEGORY TREE) ──
                ClassifiedsSidebarCategoryTree(
                  classifieds: classifieds,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),
                _buildDivider(isDark),
                const SizedBox(height: 12),

                // ── 3. CENA (EUR) ──
                ClassifiedsSidebarPriceSection(
                  classifieds: classifieds,
                  minPriceController: _minPriceController,
                  maxPriceController: _maxPriceController,
                  onApplyPrice: _applyPrice,
                  onQuickPrice: _setQuickPrice,
                  isDark: isDark,
                ),

                const SizedBox(height: 14),
                _buildDivider(isDark),
                const SizedBox(height: 12),

                // ── 4. LOKACIJA & REGION ──
                ClassifiedsSidebarLocationSection(
                  classifieds: classifieds,
                  isDark: isDark,
                ),

                // ── 5. STANJE PREDMETA (samo ako je primenjivo) ──
                if (classifieds.isConditionApplicableForSelectedCategory) ...[
                  const SizedBox(height: 14),
                  _buildDivider(isDark),
                  const SizedBox(height: 12),
                  _buildConditionSection(classifieds, isDark),
                ],

                const SizedBox(height: 14),
                _buildDivider(isDark),
                const SizedBox(height: 12),

                // ── 6. TIP OGLAŠIVAČA ──
                _buildSellerTypeSection(classifieds, isDark),

                const SizedBox(height: 14),
                _buildDivider(isDark),
                const SizedBox(height: 12),

                // ── 7. SPECIJALNO / PROMOCIJE ──
                _buildPromotionsSection(classifieds, isDark),

                // ── 8. KARAKTERISTIKE KATEGORIJE (AKO POSTOJE) ──
                if (catAttrs.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildDivider(isDark),
                  const SizedBox(height: 12),
                  ClassifiedsSidebarAttributesSection(
                    classifieds: classifieds,
                    attributes: catAttrs,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

  // --- STANJE PREDMETA ---
  Widget _buildConditionSection(ClassifiedsProvider classifieds, bool isDark) {
    const conditions = [
      (null, 'Sve'),
      ('new', 'Novo nekorišćeno'),
      ('like_new', 'Kao novo'),
      ('used', 'Polovno ispravno'),
      ('damaged', 'Za delove / oštećeno'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('STANJE PREDMETA', isDark),
        Column(
          children: conditions.map((item) {
            final (val, label) = item;
            final isSelected = classifieds.selectedCondition == val;
            return InkWell(
              onTap: () => classifieds.selectCondition(val),
              borderRadius: BorderRadius.circular(6),
              hoverColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 15,
                      color: isSelected
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                              : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- TIP OGLAŠIVAČA ---
  Widget _buildSellerTypeSection(ClassifiedsProvider classifieds, bool isDark) {
    const types = [
      (null, 'Svi oglašivači'),
      ('individual', 'Fizičko lice'),
      ('business', 'Gazdinstvo / Pravno lice'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('OGLAŠIVAČ', isDark),
        Column(
          children: types.map((item) {
            final (val, label) = item;
            final isSelected = classifieds.selectedSellerType == val;
            return InkWell(
              onTap: () => classifieds.selectSellerType(val),
              borderRadius: BorderRadius.circular(6),
              hoverColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 15,
                      color: isSelected
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                              : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- PROMOCIJE / SPECIJALNO ---
  Widget _buildPromotionsSection(ClassifiedsProvider classifieds, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('SPECIJALNO', isDark),
        InkWell(
          onTap: () => classifieds.setOnlyUrgent(!classifieds.onlyUrgent),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  classifieds.onlyUrgent ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: classifieds.onlyUrgent
                      ? AmazonColors.dealRed
                      : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚡ Samo hitni oglasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: classifieds.onlyUrgent ? FontWeight.w700 : FontWeight.w500,
                      color: classifieds.onlyUrgent
                          ? AmazonColors.dealRed
                          : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        InkWell(
          onTap: () => classifieds.setOnlyFeatured(!classifieds.onlyFeatured),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  classifieds.onlyFeatured ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: classifieds.onlyFeatured
                      ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                      : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⭐ Samo istaknuti oglasi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: classifieds.onlyFeatured ? FontWeight.w700 : FontWeight.w500,
                      color: classifieds.onlyFeatured
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
