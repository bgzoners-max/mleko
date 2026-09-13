import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/serbian_districts.dart';
import '../../core/responsive.dart';
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

  const ClassifiedsFeedScreen({
    super.key,
    this.headerWidget,
    this.isEmbedded = false,
  });

  @override
  State<ClassifiedsFeedScreen> createState() => _ClassifiedsFeedScreenState();
}

class _ClassifiedsFeedScreenState extends State<ClassifiedsFeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _categoryChipsScrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ClassifiedsProvider>();
      p.loadCategories();
      p.loadInitialAds();
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

  Widget _buildCityButton(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme,
  ) {
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

    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: () => showClassifiedCityPickerSheet(context),
        icon: Icon(
          hasSelectedDistrict ? Icons.map_outlined : Icons.location_on_outlined,
          size: 16,
          color: hasSelection ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasSelection ? FontWeight.bold : FontWeight.w500,
                  color: hasSelection ? colorScheme.primary : colorScheme.onSurface,
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
                  child: Icon(Icons.close, size: 14, color: colorScheme.primary),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: hasSelection
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          backgroundColor: hasSelection
              ? colorScheme.primaryContainer.withValues(alpha: 0.25)
              : colorScheme.surfaceContainerLowest,
        ),
      ),
    );
  }

  Widget _buildConditionChips(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme,
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
      final effectiveColor = activeColor ?? colorScheme.primary;

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: isDark ? 0.25 : 0.12)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? effectiveColor : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? effectiveColor : colorScheme.onSurface,
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
          // Tip transakcije za nekretnine (Prodaja / Izdavanje / Stan na dan)
          buildChipItem(
            isSelected: selectedTx == null,
            onTap: () => classifieds.removeAttributeFilter('transaction_type'),
            label: 'Sve',
          ),
          const SizedBox(width: 6),
          buildChipItem(
            isSelected: selectedTx == 'prodaja',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'prodaja'),
            label: 'Prodaja',
            icon: Icons.sell_outlined,
            activeColor: const Color(0xFF4338CA),
          ),
          const SizedBox(width: 6),
          buildChipItem(
            isSelected: selectedTx == 'izdavanje',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'izdavanje'),
            label: 'Izdavanje',
            icon: Icons.vpn_key_outlined,
            activeColor: const Color(0xFF0284C7),
          ),
          const SizedBox(width: 6),
          buildChipItem(
            isSelected: selectedTx == 'na_dan',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'na_dan'),
            label: 'Na dan',
            icon: Icons.hotel_outlined,
            activeColor: const Color(0xFF0F766E),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
        ] else if (hasCondition) ...[
          buildChipItem(
            isSelected: selected == null,
            onTap: () => classifieds.selectCondition(null),
            label: 'Sve',
          ),
          const SizedBox(width: 6),
          buildChipItem(
            isSelected: selected == 'new',
            onTap: () => classifieds.selectCondition('new'),
            label: 'Novo',
            icon: Icons.check_circle_outline,
            activeColor: const Color(0xFF059669),
          ),
          const SizedBox(width: 6),
          buildChipItem(
            isSelected: selected == 'used',
            onTap: () => classifieds.selectCondition('used'),
            label: 'Polovno',
            icon: Icons.inventory_2_outlined,
            activeColor: const Color(0xFF475569),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
        ],

        // Brzo dugme za filter cene i kvadrature
        buildChipItem(
          isSelected: hasPriceOrArea,
          onTap: () => showClassifiedPriceAndAreaFilterSheet(context, isRealEstate: isRealEstate),
          label: isRealEstate ? 'Cena i m²' : 'Cena',
          icon: Icons.tune_rounded,
          activeColor: colorScheme.primary,
        ),
        const SizedBox(width: 6),

        buildChipItem(
          isSelected: classifieds.onlyFeatured,
          onTap: () => classifieds.setOnlyFeatured(!classifieds.onlyFeatured),
          label: 'Istaknuto',
          icon: Icons.star_rounded,
          activeColor: const Color(0xFFD97706),
        ),
        const SizedBox(width: 6),
        buildChipItem(
          isSelected: classifieds.onlyUrgent,
          onTap: () => classifieds.setOnlyUrgent(!classifieds.onlyUrgent),
          label: 'Hitno',
          icon: Icons.bolt_rounded,
          activeColor: const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_outlined, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Filteri:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (classifieds.selectedCity != null)
            InputChip(
              avatar: const Icon(Icons.location_on, size: 14),
              label: Text(classifieds.selectedCity!, style: const TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.selectCity(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          if (classifieds.selectedDistrict != null) ...[
            () {
              final dist = SerbianDistricts.findDistrictById(classifieds.selectedDistrict!);
              final name = dist?.name ?? classifieds.selectedDistrict!;
              return InputChip(
                avatar: const Icon(Icons.map_outlined, size: 14),
                label: Text('Okrug: $name', style: const TextStyle(fontSize: 11)),
                onDeleted: () => classifieds.selectDistrict(null),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }(),
          ],
          if (classifieds.minPrice != null || classifieds.maxPrice != null)
            InputChip(
              avatar: const Icon(Icons.payments_outlined, size: 14),
              label: Text(
                'Cena: ${classifieds.minPrice != null ? '${classifieds.minPrice!.toInt()}€' : '0€'} - ${classifieds.maxPrice != null ? '${classifieds.maxPrice!.toInt()}€' : '∞'}',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.setPriceRange(minPrice: null, maxPrice: null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          if (classifieds.selectedCondition != null)
            InputChip(
              avatar: Icon(
                classifieds.selectedCondition == 'new'
                    ? Icons.check_circle_outline
                    : Icons.inventory_2_outlined,
                size: 14,
              ),
              label: Text(
                classifieds.selectedCondition == 'new' ? 'Novo' : 'Polovno',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.selectCondition(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          if (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty)
            InputChip(
              avatar: const Icon(Icons.search, size: 14),
              label: Text('„${classifieds.searchQuery}”', style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                _searchController.clear();
                classifieds.search(null);
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          if (classifieds.onlyFeatured)
            InputChip(
              avatar: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
              label: const Text('Istaknuto', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyFeatured(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          if (classifieds.onlyUrgent)
            InputChip(
              avatar: const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFDC2626)),
              label: const Text('Hitno', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyUrgent(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      attr?.icon != null ? Icon(attr!.icon, size: 14) : null,
                  label: Text('$label: $formatted',
                      style: const TextStyle(fontSize: 11)),
                  onDeleted: () => classifieds.removeAttributeFilter(entry.key),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
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
            icon: const Icon(Icons.close, size: 12),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            label: const Text('Poništi sve', style: TextStyle(fontSize: 11)),
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
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (isDesktop)
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Prethodne kategorije',
              onPressed: () {
                if (_categoryChipsScrollController.hasClients) {
                  final target = (_categoryChipsScrollController.offset - 260)
                      .clamp(0.0, _categoryChipsScrollController.position.maxScrollExtent);
                  _categoryChipsScrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 250),
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
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 4 : 12),
                  itemCount: classifieds.categories.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == 0) {
                      final isAll = classifieds.selectedCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isAll,
                          label: const Text('Sve', style: TextStyle(fontSize: 12)),
                          backgroundColor: colorScheme.surfaceContainerLow,
                          selectedColor: colorScheme.primary,
                          checkmarkColor: colorScheme.onPrimary,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) => classifieds.selectCategory(null),
                        ),
                      );
                    }
                    final cat = classifieds.categories[idx - 1];
                    final activeRoot = classifieds.activeRootCategory;
                    final isSelected = activeRoot?.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(cat.iconData,
                            size: 14,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant),
                        label: Text(cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            )),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        selectedColor: colorScheme.primary,
                        checkmarkColor: colorScheme.onPrimary,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant.withValues(alpha: 0.5),
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
              icon: const Icon(Icons.chevron_right, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Sledeće kategorije',
              onPressed: () {
                if (_categoryChipsScrollController.hasClients) {
                  final target = (_categoryChipsScrollController.offset + 260)
                      .clamp(0.0, _categoryChipsScrollController.position.maxScrollExtent);
                  _categoryChipsScrollController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 250),
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
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Postavi oglas', style: TextStyle(fontWeight: FontWeight.bold)),
          );

    final scrollBody = RefreshIndicator(
      onRefresh: classifieds.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
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
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      final q = val.trim().isEmpty ? null : val.trim();
                      classifieds.search(q);
                    },
                    decoration: InputDecoration(
                      hintText: 'Pretraži oglase, traktore, mehanizaciju, alate, tehniku...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary, size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLowest,
                    ),
                  ),

                  // Filteri grad + kategorije + sort (jedan red na desktopu, dva reda na mobilnom)
                  const SizedBox(height: 8),
                  if (isDesktop) ...[
                    // JEDAN RED NA DESKTOPU: [ SVI GRADOVI ] [ STANJE (ako važi) ] [ <- KATEGORIJE ... -> ] [ NAJNOVIJE v ]
                    Row(
                      children: [
                        _buildCityButton(context, classifieds, colorScheme),
                        const SizedBox(width: 8),
                        _buildConditionChips(context, classifieds, colorScheme),
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
                          child: _buildCityButton(context, classifieds, colorScheme),
                        ),
                        const SizedBox(width: 8),
                        ClassifiedSortDropdown(classifieds: classifieds),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Red 2: Stanje (ako važi) + Promocije (Istaknuto, Hitno)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildConditionChips(context, classifieds, colorScheme),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Grid kategorija organizovan kao na strani malih proizvođača
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
                    mainAxisExtent: 56,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!classifieds.loading && classifieds.ads.isNotEmpty)
                      Text(
                        '${classifieds.ads.length}+ oglasa',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Poništi filtere',
                          style: TextStyle(fontSize: 12)),
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
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Breakpoints.maxContentWidth(context),
        ),
        child: scrollBody,
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
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back_ios_new, size: 12, color: colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Nazad',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
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
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ],
                  for (int i = 0; i < crumbs.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right,
                            size: 14,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      ),
                    if (i == crumbs.length - 1)
                      Text(
                        crumbs[i].name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ChoiceChip(
                    selected: isAllInActiveParent,
                    avatar: Icon(activeParent.iconData, size: 15),
                    label: Text(
                      'Svi oglasi u „${activeParent.name}”',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isAllInActiveParent ? FontWeight.bold : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 14, 18, isDesktop ? 24 : 14, 8),
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
                              color: isGroupSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            group.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isGroupSelected ? colorScheme.primary : colorScheme.onSurface,
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
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        isGroupSelected ? 'Poništi filter' : 'Svi (${group.name})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isGroupSelected ? FontWeight.bold : FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 2. Mreža marki automobila za datu državu
        slivers.add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 2),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCrossAxisCount,
                mainAxisExtent: 56,
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
              padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 14, 22, isDesktop ? 24 : 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OSTALO / DODATNE KATEGORIJE',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: colorScheme.onSurface,
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
                mainAxisExtent: 56,
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
            mainAxisExtent: 56,
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
    // Prikazujemo atribute sa predefinisanim opcijama (select i boolean) za horizontalni brzi filter
    final filterable = attributes
        .where((a) =>
            a.type == AttributeType.select || a.type == AttributeType.boolean)
        .toList();

    if (filterable.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterable.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final attr = filterable[i];
          final isApplied = classifieds.selectedAttributes.containsKey(attr.key);
          final currentValue = classifieds.selectedAttributes[attr.key];

          if (attr.type == AttributeType.boolean) {
            final isTrue = currentValue == true;
            return FilterChip(
              selected: isTrue,
              label: Text(attr.label, style: const TextStyle(fontSize: 11.5)),
              avatar: attr.icon != null ? Icon(attr.icon, size: 14) : null,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
                        style: TextStyle(color: Colors.red)),
                  ),
                ...options.map(
                  (opt) => PopupMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isApplied
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isApplied
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isApplied ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (attr.icon != null) ...[
                      Icon(
                        attr.icon,
                        size: 14,
                        color: isApplied
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isApplied ? FontWeight.bold : FontWeight.w500,
                        color: isApplied
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: isApplied
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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

