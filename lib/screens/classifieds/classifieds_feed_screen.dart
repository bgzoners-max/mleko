import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../constants/serbian_districts.dart';
import '../../core/responsive.dart';
import '../../core/web_seo.dart';
import '../../models/category_attribute_model.dart';
import '../../models/classified_category_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/classifieds/classified_ad_card.dart';
import '../../widgets/classifieds/classified_category_tiles.dart';
import '../../widgets/classifieds/classified_filter_bottom_sheets.dart';
import '../../widgets/classifieds/classified_sort_dropdown.dart';
import '../../widgets/classifieds/classified_subscription_chip.dart';

class ClassifiedsFeedScreen extends StatefulWidget {
  final Widget? headerWidget;
  final bool isEmbedded;
  final String? initialCategoryId;

  const ClassifiedsFeedScreen({
    super.key,
    this.headerWidget,
    this.isEmbedded = false,
    this.initialCategoryId,
  });

  @override
  State<ClassifiedsFeedScreen> createState() => _ClassifiedsFeedScreenState();
}

class _ClassifiedsFeedScreenState extends State<ClassifiedsFeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _categoryChipsScrollController = ScrollController();
  Timer? _debounceTimer;
  String? _lastSeoCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<ClassifiedsProvider>();
      if (widget.initialCategoryId != null &&
          widget.initialCategoryId!.isNotEmpty) {
        await p.loadCategories();
        if (!mounted) return;
        p.selectCategory(widget.initialCategoryId);
        final cat = p.findCategory(widget.initialCategoryId!);
        if (cat != null) {
          setClassifiedCategorySeo(cat);
          _lastSeoCategoryId = cat.id;
        }
      } else {
        if (!widget.isEmbedded) {
          applyRouteSeo('/classifieds');
        }
        // Pokrećemo kategorije i oglase paralelno u istoj milisekundi
        unawaited(p.loadCategories());
        unawaited(p.loadInitialAds());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _categoryChipsScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ClassifiedsProvider>().loadMore();
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<ClassifiedsProvider>().search(val.trim().isEmpty ? null : val);
      }
    });
  }

  Widget _buildAmazonStandaloneHeader(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    return Container(
      color: AmazonColors.darkNavy,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 12,
        vertical: 8,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DOMAĆI MARKET',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'MALI OGLASI',
                    style: TextStyle(
                      color: AmazonColors.darkNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.storefront_outlined, size: 15, color: Color(0xFF86EFAC)),
            label: Text(
              isDesktop ? 'Pređi na Pijacu hrane' : 'Pijaca hrane',
              style: const TextStyle(
                color: Color(0xFF86EFAC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmazonSearchBar(
    BuildContext context,
    ClassifiedsProvider classifieds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search,
            size: 20,
            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                final q = val.trim().isEmpty ? null : val.trim();
                classifieds.search(q);
              },
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Pretraži male oglase (traktori, mehanizacija, alati, tehnika...)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
          InkWell(
            onTap: () {
              final q = _searchController.text.trim();
              classifieds.search(q.isEmpty ? null : q);
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: Container(
              width: 44,
              height: 42,
              decoration: const BoxDecoration(
                color: AmazonColors.amberLight,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: AmazonColors.darkNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityButton(
    BuildContext context,
    ClassifiedsProvider classifieds,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSelectedCity = classifieds.selectedCity != null;
    final hasSelectedDistrict = classifieds.selectedDistrict != null;
    final hasSelection = hasSelectedCity || hasSelectedDistrict;

    String labelText = 'Sve lokacije';
    if (hasSelectedCity) {
      labelText = classifieds.selectedCity!;
    } else if (hasSelectedDistrict) {
      final d = SerbianDistricts.findDistrictById(classifieds.selectedDistrict!);
      labelText = d?.name ?? classifieds.selectedDistrict!;
    }

    final btnBg = hasSelection
        ? (isDark ? AmazonColors.amber.withValues(alpha: 0.2) : AmazonColors.amberLight.withValues(alpha: 0.25))
        : (isDark ? AmazonColors.darkCard : AmazonColors.cardWhite);
    final btnBorder = hasSelection
        ? AmazonColors.amberDark
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);
    final btnTextColor = hasSelection
        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
        : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary);
    final btnIconColor = hasSelection
        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
        : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary);

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () => showClassifiedCityPickerSheet(context),
        icon: Icon(
          hasSelectedDistrict ? Icons.map_outlined : Icons.location_on_outlined,
          size: 15,
          color: btnIconColor,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                  color: btnTextColor,
                ),
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  classifieds.selectCity(null);
                  classifieds.selectDistrict(null);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 13, color: btnIconColor),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: btnBorder,
            width: hasSelection ? 1.4 : 1.0,
          ),
          backgroundColor: btnBg,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildConditionChips(
    BuildContext context,
    ClassifiedsProvider classifieds,
  ) {
    final selected = classifieds.selectedCondition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildChipItem({
      required bool isSelected,
      required VoidCallback onTap,
      required String label,
      IconData? icon,
      Color? activeColor,
    }) {
      final effectiveColor = activeColor ?? (isDark ? AmazonColors.amberLight : AmazonColors.navNavy);

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: isDark ? 0.28 : 0.12)
                : (isDark ? AmazonColors.darkCard : AmazonColors.cardWhite),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (!isDark && !isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? effectiveColor : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? effectiveColor : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeRootId = classifieds.activeRootCategory?.id;
    final selectedCatId = classifieds.selectedCategoryId;
    final isRealEstate = activeRootId == 'nekretnine' ||
        selectedCatId == 'nekretnine' ||
        (selectedCatId != null &&
            (selectedCatId.contains('stan') ||
                selectedCatId.contains('kuc') ||
                selectedCatId.contains('plac') ||
                selectedCatId.contains('zemlj') ||
                selectedCatId.contains('poslovn') ||
                selectedCatId.contains('vikendic') ||
                selectedCatId.contains('garaz')));

    final hasCondition = classifieds.isConditionApplicableForSelectedCategory;
    final selectedTx = classifieds.selectedAttributes['transaction_type']?.toString();
    final hasPriceOrArea = classifieds.minPrice != null ||
        classifieds.maxPrice != null ||
        classifieds.selectedAttributes.containsKey('min_area_m2') ||
        classifieds.selectedAttributes.containsKey('max_area_m2');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRealEstate) ...[
          // Tip transakcije za nekretnine
          buildChipItem(
            isSelected: selectedTx == null,
            onTap: () => classifieds.removeAttributeFilter('transaction_type'),
            label: 'Sve',
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'prodaja',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'prodaja'),
            label: 'Prodaja',
            icon: Icons.sell_outlined,
            activeColor: AmazonColors.navNavy,
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'izdavanje',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'izdavanje'),
            label: 'Izdavanje',
            icon: Icons.vpn_key_outlined,
            activeColor: const Color(0xFF0284C7),
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'na_dan',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'na_dan'),
            label: 'Na dan',
            icon: Icons.hotel_outlined,
            activeColor: const Color(0xFF0F766E),
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 18,
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          ),
          const SizedBox(width: 6),
        ] else if (hasCondition) ...[
          buildChipItem(
            isSelected: selected == null,
            onTap: () => classifieds.selectCondition(null),
            label: 'Sve',
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selected == 'new',
            onTap: () => classifieds.selectCondition('new'),
            label: 'Novo',
            icon: Icons.check_circle_outline,
            activeColor: AmazonColors.green,
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selected == 'used',
            onTap: () => classifieds.selectCondition('used'),
            label: 'Polovno',
            icon: Icons.inventory_2_outlined,
            activeColor: AmazonColors.navNavy,
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 18,
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          ),
          const SizedBox(width: 6),
        ],

        // Brzo dugme za filter cene i kvadrature
        buildChipItem(
          isSelected: hasPriceOrArea,
          onTap: () => showClassifiedPriceAndAreaFilterSheet(context, isRealEstate: isRealEstate),
          label: isRealEstate ? 'Cena i m²' : 'Cena',
          icon: Icons.tune_rounded,
          activeColor: AmazonColors.amberDark,
        ),
        const SizedBox(width: 5),

        buildChipItem(
          isSelected: classifieds.onlyFeatured,
          onTap: () => classifieds.setOnlyFeatured(!classifieds.onlyFeatured),
          label: 'Istaknuto',
          icon: Icons.star_rounded,
          activeColor: AmazonColors.amberDark,
        ),
        const SizedBox(width: 5),
        buildChipItem(
          isSelected: classifieds.onlyUrgent,
          onTap: () => classifieds.setOnlyUrgent(!classifieds.onlyUrgent),
          label: 'Hitno',
          icon: Icons.bolt_rounded,
          activeColor: AmazonColors.badgeRed,
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 13,
                color: isDark ? AmazonColors.amberLight : AmazonColors.darkNavy,
              ),
              const SizedBox(width: 3),
              Text(
                'Filteri:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
          if (classifieds.selectedCity != null)
            InputChip(
              avatar: const Icon(Icons.location_on, size: 13),
              label: Text(classifieds.selectedCity!, style: const TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.selectCity(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedDistrict != null) ...[
            () {
              final dist = SerbianDistricts.findDistrictById(classifieds.selectedDistrict!);
              final name = dist?.name ?? classifieds.selectedDistrict!;
              return InputChip(
                avatar: const Icon(Icons.map_outlined, size: 13),
                label: Text('Okrug: $name', style: const TextStyle(fontSize: 11)),
                onDeleted: () => classifieds.selectDistrict(null),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              );
            }(),
          ],
          if (classifieds.minPrice != null || classifieds.maxPrice != null)
            InputChip(
              avatar: const Icon(Icons.payments_outlined, size: 13),
              label: Text(
                'Cena: ${classifieds.minPrice != null ? '${classifieds.minPrice!.toInt()}€' : '0€'} - ${classifieds.maxPrice != null ? '${classifieds.maxPrice!.toInt()}€' : '∞'}',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.setPriceRange(minPrice: null, maxPrice: null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedCondition != null)
            InputChip(
              avatar: Icon(
                classifieds.selectedCondition == 'new'
                    ? Icons.check_circle_outline
                    : Icons.inventory_2_outlined,
                size: 13,
              ),
              label: Text(
                classifieds.selectedCondition == 'new' ? 'Novo' : 'Polovno',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.selectCondition(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty)
            InputChip(
              avatar: const Icon(Icons.search, size: 13),
              label: Text('„${classifieds.searchQuery}”', style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                _searchController.clear();
                classifieds.search(null);
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.onlyFeatured)
            InputChip(
              avatar: const Icon(Icons.star_rounded, size: 13, color: AmazonColors.amberDark),
              label: const Text('Istaknuto', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyFeatured(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.onlyUrgent)
            InputChip(
              avatar: const Icon(Icons.bolt_rounded, size: 13, color: AmazonColors.badgeRed),
              label: const Text('Hitno', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyUrgent(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedAttributes.isNotEmpty) ...[
            for (final entry in classifieds.selectedAttributes.entries) ...[
              () {
                final attr =
                    ClassifiedAttributesEngine.findAttributeByKey(entry.key);
                final label = attr?.label ?? entry.key;
                final formatted = attr != null
                    ? attr.formatValue(entry.value)
                    : entry.value.toString();
                return InputChip(
                  avatar:
                      attr?.icon != null ? Icon(attr!.icon, size: 13) : null,
                  label: Text('$label: $formatted',
                      style: const TextStyle(fontSize: 11)),
                  onDeleted: () => classifieds.removeAttributeFilter(entry.key),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                  side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                );
              }(),
            ],
          ],
          if (classifieds.selectedCategoryId != null ||
              (classifieds.searchQuery != null &&
                  classifieds.searchQuery!.isNotEmpty))
            ActionChip(
              avatar: Icon(
                (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? Icons.notifications_active_rounded
                    : Icons.notification_add_outlined,
                size: 13,
                color: (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
              ),
              label: Text(
                (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? 'Pratite'
                    : 'Sačuvaj pretragu',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              onPressed: () => handleClassifiedSubscribe(
                context,
                classifieds,
                categoryId: classifieds.selectedCategoryId,
                searchQuery: classifieds.searchQuery,
              ),
            ),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              classifieds.clearAllFilters();
            },
            icon: const Icon(Icons.close, size: 12, color: AmazonColors.link),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            label: const Text(
              'Poništi sve',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AmazonColors.link,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChipsRow(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme, {
    required bool isDesktop,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 18,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Prethodne kategorije',
              onPressed: () {
                if (_categoryChipsScrollController.hasClients) {
                  final target = (_categoryChipsScrollController.offset - 240)
                      .clamp(0.0, _categoryChipsScrollController.position.maxScrollExtent);
                  _categoryChipsScrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent &&
                      _categoryChipsScrollController.hasClients) {
                    final delta = pointerSignal.scrollDelta.dx != 0
                        ? pointerSignal.scrollDelta.dx
                        : pointerSignal.scrollDelta.dy;
                    final target = (_categoryChipsScrollController.offset + delta)
                        .clamp(0.0, _categoryChipsScrollController.position.maxScrollExtent);
                    _categoryChipsScrollController.jumpTo(target);
                  }
                },
                child: ListView.builder(
                  controller: _categoryChipsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 8),
                  itemCount: classifieds.categories.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      final isAll = classifieds.selectedCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          selected: isAll,
                          label: const Text('Sve', style: TextStyle(fontSize: 11.5)),
                          backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                          selectedColor: AmazonColors.navNavy,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isAll ? FontWeight.w700 : FontWeight.w500,
                            color: isAll
                                ? Colors.white
                                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isAll
                                  ? AmazonColors.navNavy
                                  : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                              width: isAll ? 1.4 : 1.0,
                            ),
                          ),
                          onSelected: (_) => classifieds.selectCategory(null),
                        ),
                      );
                    }
                    final cat = classifieds.categories[idx - 1];
                    final activeRoot = classifieds.activeRootCategory;
                    final isSelected = activeRoot?.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(
                          cat.iconData,
                          size: 13,
                          color: isSelected
                              ? AmazonColors.amberLight
                              : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.navNavy),
                        ),
                        label: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                          ),
                        ),
                        backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                        selectedColor: AmazonColors.navNavy,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? AmazonColors.navNavy
                                : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        onSelected: (sel) =>
                            classifieds.selectCategory(sel ? cat.id : null),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (isDesktop)
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              tooltip: 'Sledeće kategorije',
              onPressed: () {
                if (_categoryChipsScrollController.hasClients) {
                  final target = (_categoryChipsScrollController.offset + 240)
                      .clamp(0.0, _categoryChipsScrollController.position.maxScrollExtent);
                  _categoryChipsScrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final classifieds = context.watch<ClassifiedsProvider>();
    final user = context.watch<AppState>().user;

    if (!widget.isEmbedded) {
      final currentCatId = classifieds.selectedCategoryId;
      if (currentCatId != _lastSeoCategoryId) {
        _lastSeoCategoryId = currentCatId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (currentCatId != null) {
            final cat = classifieds.findCategory(currentCatId);
            if (cat != null) {
              setClassifiedCategorySeo(cat);
            }
          } else {
            applyRouteSeo('/classifieds');
          }
        });
      }
    }

    final crossAxisCount = Breakpoints.productGridColumns(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final isRefreshing = classifieds.refreshing;

    final isFiltered = classifieds.selectedCategoryId != null ||
        classifieds.selectedCity != null ||
        classifieds.selectedDistrict != null ||
        classifieds.minPrice != null ||
        classifieds.maxPrice != null ||
        classifieds.selectedCondition != null ||
        classifieds.selectedAttributes.isNotEmpty ||
        classifieds.onlyFeatured ||
        classifieds.onlyUrgent ||
        (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty);

    // FAB — samo za prijavljene korisnike (gost može samo da pregleda)
    final isGuest = user == null || user.isGuest;
    final fab = isGuest
        ? null
        : FloatingActionButton.extended(
            onPressed: () => context.push('/classifieds/new'),
            backgroundColor: AmazonColors.amber,
            foregroundColor: AmazonColors.darkNavy,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Postavi oglas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          );

    final scrollBody = RefreshIndicator(
      onRefresh: classifieds.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Standalone Amazon Header ako nismo na početnoj (embedded)
          if (!widget.isEmbedded)
            SliverToBoxAdapter(
              child: _buildAmazonStandaloneHeader(context),
            ),

          // Opcioni header (MarketModeSwitcher)
          if (widget.headerWidget != null)
            SliverToBoxAdapter(child: widget.headerWidget!),

          // Suptilni progress bar tokom refresh-a (kada podaci vec postoje)
          SliverToBoxAdapter(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: isRefreshing ? 3 : 0,
              child: isRefreshing
                  ? LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          // Search bar + filteri
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 12, 8, isDesktop ? 24 : 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user?.isAdmin == true) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/admin/classifieds'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 18, color: Colors.amber.shade900),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin panel: Moderacija prijavljenih oglasa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: Colors.amber.shade900),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Amazon Search bar
                  _buildAmazonSearchBar(context, classifieds),

                  // Filteri grad + kategorije + sort (jedan red na desktopu, dva reda na mobilnom)
                  const SizedBox(height: 8),
                  if (isDesktop) ...[
                    // JEDAN RED NA DESKTOPU: [ SVI GRADOVI ] [ STANJE (ako važi) ] [ <- KATEGORIJE ... -> ] [ NAJNOVIJE v ]
                    Row(
                      children: [
                        _buildCityButton(context, classifieds),
                        const SizedBox(width: 8),
                        _buildConditionChips(context, classifieds),
                        const SizedBox(width: 8),
                        if (classifieds.categories.isNotEmpty)
                          Expanded(
                            child: _buildCategoryChipsRow(
                              context,
                              classifieds,
                              colorScheme,
                              isDesktop: true,
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(width: 8),
                        ClassifiedSortDropdown(classifieds: classifieds),
                      ],
                    ),
                  ] else ...[
                    // DVA REDA NA MOBILNOM / TABLETU:
                    // Red 1: Grad + Sort
                    Row(
                      children: [
                        Expanded(
                          child: _buildCityButton(context, classifieds),
                        ),
                        const SizedBox(width: 8),
                        ClassifiedSortDropdown(classifieds: classifieds),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Red 2: Stanje (ako važi) + Promocije (Istaknuto, Hitno)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildConditionChips(context, classifieds),
                    ),
                  ],

                  if (isFiltered)
                    _buildActiveFilterChips(context, classifieds, colorScheme),
                ],
              ),
            ),
          ),

          // ── DISCOVERY MODE: kategorije + najnoviji ────────────────────────
          if (!isFiltered) ...[
            // Naslov sekcije kategorija
            if (classifieds.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 12, isDesktop ? 24 : 16, 8),
                  child: Text(
                    'Kategorije',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AmazonColors.darkTextPrimary
                          : AmazonColors.textPrimary,
                    ),
                  ),
                ),
              ),

            // Grid kategorija organizovan kao na strani malih proizvođača (Amazon compact 46px)
            if (classifieds.categories.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop
                        ? 4
                        : (Breakpoints.isLargeTablet(context)
                            ? 4
                            : (Breakpoints.isSmallTablet(context) ? 3 : 2)),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 46,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => CategoryGridTile(
                      category: classifieds.categories[i],
                      onTap: () => classifieds.selectCategory(classifieds.categories[i].id),
                    ),
                    childCount: classifieds.categories.length,
                  ),
                ),
              ),

            // Separator
            const SliverToBoxAdapter(child: SizedBox(height: 4)),

            // Naslov sekcije najnovijih oglasa
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Najnoviji oglasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                    if (!classifieds.loading && classifieds.ads.isNotEmpty)
                      Text(
                        '${classifieds.ads.length}+ oglasa',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AmazonColors.darkTextSecondary
                              : AmazonColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ── FILTER MODE: Glavne kategorije (mobilni/tablet) + 2-kolonski raspored podkategorija ──
          if (isFiltered && classifieds.categories.isNotEmpty) ...[
            // Na mobilnom / tabletu: horizontalne kategorije kao 2. red (na desktopu je već u 1. redu sa gradom i sortiranjem)
            if (!isDesktop)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildCategoryChipsRow(
                    context,
                    classifieds,
                    colorScheme,
                    isDesktop: false,
                  ),
                ),
              ),
            
            // Header podkategorija sa navigacijom (breadcrumbs) i dugmetom 'Sve u...'
            if (classifieds.activeRootCategory != null)
              SliverToBoxAdapter(
                child: _buildSubcategoryHeader(context, classifieds, theme, colorScheme),
              ),

            // 2. Podkategorije (grupisane sekcije po državama ili standardna mreža)
            if (classifieds.activeRootCategory != null)
              ..._buildSubcategoriesSlivers(context, classifieds, theme, colorScheme),

            // 3. Filteri parametara/karakteristika (gorivo, menjač, karoserija, sobe...)
            () {
              final catAttrs =
                  ClassifiedAttributesEngine.getAttributesForCategory(
                classifieds.selectedCategoryId,
                breadcrumbs: classifieds.categoryBreadcrumbs,
              );
              if (catAttrs.isNotEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _buildAttributeFilterBar(
                      context,
                      classifieds,
                      colorScheme,
                      catAttrs,
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }(),

            // Separator i naslov sekcije oglasa sa dugmetom za poništavanje
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Oglasi',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        classifieds.selectCategory(null);
                        classifieds.selectCity(null);
                        classifieds.selectCondition(null);
                        classifieds.clearAttributeFilters();
                        classifieds.search(null);
                      },
                      icon: const Icon(Icons.close, size: 14, color: AmazonColors.link),
                      label: const Text(
                        'Poništi filtere',
                        style: TextStyle(fontSize: 12, color: AmazonColors.link),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // ── SADRŽAJ: loading / prazan / mreža oglasa ──────────────────────
          if (classifieds.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (classifieds.error != null && classifieds.ads.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Greška pri učitavanju',
                  subtitle: classifieds.error,
                  ctaLabel: 'Pokušaj ponovo',
                  ctaIcon: Icons.refresh,
                  onCtaPressed: classifieds.refresh,
                ),
              ),
            )
          else if (classifieds.ads.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'Nema oglasa',
                  subtitle: isFiltered
                      ? 'Pokušajte sa promenom filtera ili pretrage.'
                      : (isGuest
                          ? 'Trenutno nema objavljenih oglasa.'
                          : 'Budite prvi koji će postaviti oglas!'),
                  ctaLabel: isFiltered
                      ? 'Poništi filtere'
                      : (isGuest ? null : 'Postavi oglas'),
                  ctaIcon: isFiltered
                      ? Icons.refresh
                      : (isGuest ? null : Icons.add_circle_outline),
                  onCtaPressed: isFiltered
                      ? () {
                          _searchController.clear();
                          classifieds.clearAllFilters();
                        }
                      : (isGuest
                          ? null
                          : () => context.push('/classifieds/new')),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 12,
                vertical: 8,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: isDesktop ? 0.74 : 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => ClassifiedAdCard(ad: classifieds.ads[i]),
                  childCount: classifieds.ads.length,
                ),
              ),
            ),

          // Indikator load more
          if (classifieds.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );

    final canvasColor = AmazonColors.getCanvas(context);

    final content = ColoredBox(
      color: canvasColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context),
          ),
          child: scrollBody,
        ),
      ),
    );

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (fab != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: SafeArea(child: fab),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: canvasColor,
      floatingActionButton: fab,
      body: content,
    );
  }

  Widget _buildSubcategoryHeader(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_ios_new, size: 11, color: AmazonColors.link),
                              SizedBox(width: 4),
                              Text(
                                'Nazad',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AmazonColors.link,
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
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AmazonColors.link,
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

  List<Widget> _buildSubcategoriesSlivers(
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
        slivers.add(
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
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AmazonColors.link,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 2. Mreža marki automobila za datu državu (Amazon compact 46px)
        slivers.add(
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
        slivers.add(
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
        );

        slivers.add(
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

  Widget _buildAttributeFilterBar(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme,
    List<CategoryAttribute> attributes,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prikazujemo atribute sa predefinisanim opcijama (select i boolean) za horizontalni brzi filter
    final filterable = attributes
        .where((a) =>
            a.type == AttributeType.select || a.type == AttributeType.boolean)
        .toList();

    if (filterable.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterable.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final attr = filterable[i];
          final isApplied = classifieds.selectedAttributes.containsKey(attr.key);
          final currentValue = classifieds.selectedAttributes[attr.key];

          if (attr.type == AttributeType.boolean) {
            final isTrue = currentValue == true;
            return FilterChip(
              selected: isTrue,
              label: Text(attr.label, style: const TextStyle(fontSize: 11.5)),
              avatar: attr.icon != null ? Icon(attr.icon, size: 13) : null,
              visualDensity: VisualDensity.compact,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              selectedColor: isDark
                  ? AmazonColors.amber.withValues(alpha: 0.25)
                  : AmazonColors.amberLight.withValues(alpha: 0.35),
              side: BorderSide(
                color: isTrue
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                width: isTrue ? 1.4 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (sel) {
                if (sel) {
                  classifieds.setAttributeFilter(attr.key, true);
                } else {
                  classifieds.removeAttributeFilter(attr.key);
                }
              },
            );
          }

          if (attr.type == AttributeType.select) {
            String labelText = attr.label;
            final options = attr.options ?? const [];
            if (isApplied) {
              final opt = options.firstWhere(
                (o) => o.value == currentValue.toString(),
                orElse: () => CategoryAttributeOption(
                  value: currentValue.toString(),
                  label: currentValue.toString(),
                ),
              );
              labelText = '${attr.label}: ${opt.label}';
            }

            final activeBg = isDark
                ? AmazonColors.amber.withValues(alpha: 0.22)
                : AmazonColors.amberLight.withValues(alpha: 0.35);
            final inactiveBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
            final activeBorder = AmazonColors.amberDark;
            final inactiveBorder = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

            return PopupMenuButton<String>(
              tooltip: attr.label,
              initialValue: currentValue?.toString(),
              onSelected: (val) {
                if (val == '__clear__') {
                  classifieds.removeAttributeFilter(attr.key);
                } else {
                  classifieds.setAttributeFilter(attr.key, val);
                }
              },
              itemBuilder: (context) => [
                if (isApplied)
                  const PopupMenuItem(
                    value: '__clear__',
                    child: Text('Poništi filter',
                        style: TextStyle(color: AmazonColors.badgeRed)),
                  ),
                ...options.map(
                  (opt) => PopupMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isApplied ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isApplied ? activeBorder : inactiveBorder,
                    width: isApplied ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (attr.icon != null) ...[
                      Icon(
                        attr.icon,
                        size: 13,
                        color: isApplied
                            ? AmazonColors.amberDark
                            : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isApplied ? FontWeight.w700 : FontWeight.w500,
                        color: isApplied
                            ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                            : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: isApplied
                          ? AmazonColors.amberDark
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

