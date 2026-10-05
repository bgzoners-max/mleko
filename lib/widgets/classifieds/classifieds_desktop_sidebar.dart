import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design_system.dart';
import '../../models/category_attribute_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import 'classified_filter_bottom_sheets.dart';

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
          _buildCategoryTreeSection(context, classifieds, isDark),

          const SizedBox(height: 14),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 3. CENA (EUR) ──
          _buildPriceSection(isDark),

          const SizedBox(height: 14),
          _buildDivider(isDark),
          const SizedBox(height: 12),

          // ── 4. LOKACIJA & REGION ──
          _buildLocationSection(context, classifieds, isDark),

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
            _buildAttributesSection(classifieds, catAttrs, isDark),
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

  // --- KATEGORIJE ---
  Widget _buildCategoryTreeSection(
    BuildContext context,
    ClassifiedsProvider classifieds,
    bool isDark,
  ) {
    final selectedCatId = classifieds.selectedCategoryId;
    final activeCat = selectedCatId != null ? classifieds.findCategory(selectedCatId) : null;
    final breadcrumbs = classifieds.categoryBreadcrumbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('KATEGORIJE', isDark),
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
                  _buildCountBadge(activeCat.adCount, isDark, isActive: true),
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
                            _buildCountBadge(sub.adCount, isDark, isActive: false),
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
                        _buildCountBadge(cat.adCount, isDark, isActive: false),
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

  Widget _buildCountBadge(int count, bool isDark, {required bool isActive}) {
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

  // --- CENA ---
  Widget _buildPriceSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CENA (€)', isDark),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _applyPrice(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Od',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _applyPrice(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Do',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: _applyPrice,
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? AmazonColors.amberDark : AmazonColors.amber,
                  foregroundColor: AmazonColors.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick price chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildQuickPricePill('< 50 €', null, 50, isDark),
            _buildQuickPricePill('50–200 €', 50, 200, isDark),
            _buildQuickPricePill('200–500 €', 200, 500, isDark),
            _buildQuickPricePill('500 € +', 500, null, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPricePill(String label, double? min, double? max, bool isDark) {
    final isSelected = widget.classifieds.minPrice == min && widget.classifieds.maxPrice == max;
    return InkWell(
      onTap: () => _setQuickPrice(min, max),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AmazonColors.amber.withValues(alpha: 0.25) : AmazonColors.amberLight)
              : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AmazonColors.amberDark
                : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
          ),
        ),
      ),
    );
  }

  // --- LOKACIJA ---
  Widget _buildLocationSection(
    BuildContext context,
    ClassifiedsProvider classifieds,
    bool isDark,
  ) {
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
        _buildSectionTitle('LOKACIJA', isDark),
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
                      classifieds.selectCity(null);
                      classifieds.selectDistrict(null);
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

  // --- KARAKTERISTIKE / ATRIBUTI ---
  Widget _buildAttributesSection(
    ClassifiedsProvider classifieds,
    List<CategoryAttribute> attributes,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('KARAKTERISTIKE', isDark),
        ...attributes.map((attr) {
          final isApplied = classifieds.selectedAttributes.containsKey(attr.key);
          final currentValue = classifieds.selectedAttributes[attr.key];

          if (attr.type == AttributeType.boolean) {
            final isTrue = currentValue == true;
            return InkWell(
              onTap: () {
                if (isTrue) {
                  classifieds.removeAttributeFilter(attr.key);
                } else {
                  classifieds.setAttributeFilter(attr.key, true);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isTrue ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 15,
                      color: isTrue
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attr.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isTrue ? FontWeight.w700 : FontWeight.w500,
                          color: isTrue
                              ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                              : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (attr.type == AttributeType.select && (attr.options?.isNotEmpty ?? false)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attr.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isApplied
                          ? (isDark ? AmazonColors.amber.withValues(alpha: 0.15) : AmazonColors.amberLight.withValues(alpha: 0.3))
                          : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isApplied
                            ? AmazonColors.amberDark
                            : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentValue?.toString(),
                        hint: Text(
                          'Sve opcije',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'Sve opcije',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                              ),
                            ),
                          ),
                          ...attr.options!.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt.value,
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            classifieds.removeAttributeFilter(attr.key);
                          } else {
                            classifieds.setAttributeFilter(attr.key, val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
