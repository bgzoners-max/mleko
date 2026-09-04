import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/serbian_cities.dart';
import '../../core/responsive.dart';
import '../../models/classified_category_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/classifieds/classified_ad_card.dart';

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

  void _openCityPicker(BuildContext context) {
    final provider = context.read<ClassifiedsProvider>();
    String searchQuery = '';

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCities = searchQuery.trim().isEmpty
                ? SerbianCities.all
                : SerbianCities.suggestions(searchQuery);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtl) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Text(
                            'Izaberi grad ili lokaciju',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Pretraži grad...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: scrollCtl,
                        children: [
                          if (searchQuery.trim().isEmpty)
                            ListTile(
                              title: const Text('Svi gradovi', style: TextStyle(fontWeight: FontWeight.bold)),
                              trailing: provider.selectedCity == null
                                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                  : null,
                              onTap: () {
                                provider.selectCity(null);
                                Navigator.pop(ctx);
                              },
                            ),
                          ...filteredCities.map((city) {
                            final isSelected = provider.selectedCity == city;
                            return ListTile(
                              title: Text(city),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                  : null,
                              onTap: () {
                                provider.selectCity(city);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
        (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty);

    // FAB
    final fab = FloatingActionButton.extended(
      onPressed: () {
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Prijavite se da biste postavili oglas.'),
              action: SnackBarAction(
                label: 'Prijava',
                onPressed: () => context.push('/login'),
              ),
            ),
          );
          return;
        }
        context.push('/classifieds/new');
      },
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Pretraži oglase...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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

                  // Filteri grad + sort (samo kada je filter aktivan ili uvek vidljiv)
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openCityPicker(context),
                          icon: const Icon(Icons.location_on_outlined, size: 16),
                          label: Text(
                            classifieds.selectedCity ?? 'Svi gradovi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<ClassifiedSort>(
                          value: classifieds.sort,
                          borderRadius: BorderRadius.circular(12),
                          items: const [
                            DropdownMenuItem(
                              value: ClassifiedSort.newest,
                              child: Text('Najnovije', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: ClassifiedSort.priceAsc,
                              child: Text('Cena: najniža', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: ClassifiedSort.priceDesc,
                              child: Text('Cena: najviša', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: ClassifiedSort.popular,
                              child: Text('Najpopularnije', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          onChanged: (s) {
                            if (s != null) classifieds.changeSort(s);
                          },
                        ),
                      ),
                    ],
                  ),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Kategorije',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Grid kategorija
            if (classifieds.categories.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.73,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _CategoryGridTile(
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

          // ── FILTER MODE: Glavne kategorije + 2-kolonski raspored podkategorija ──
          if (isFiltered && classifieds.categories.isNotEmpty) ...[
            // 1. Red: Horizontalni pregled glavnih kategorija za brzi prelaz
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

            // Header podkategorija sa navigacijom (breadcrumbs) i dugmetom 'Sve u...'
            if (classifieds.activeRootCategory != null)
              SliverToBoxAdapter(
                child: _buildSubcategoryHeader(context, classifieds, theme, colorScheme),
              ),

            // 2. Podkategorije organizovane u 2 kolone (prema skici korisnika)
            if (classifieds.activeRootCategory != null)
              _buildSubcategoriesGrid(context, classifieds, theme, colorScheme),

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
                      : 'Budite prvi koji će postaviti oglas!',
                  ctaLabel: isFiltered ? 'Poništi filtere' : 'Postavi oglas',
                  ctaIcon: isFiltered ? Icons.refresh : Icons.add_circle_outline,
                  onCtaPressed: () {
                    if (isFiltered) {
                      _searchController.clear();
                      classifieds.selectCategory(null);
                      classifieds.selectCity(null);
                      classifieds.search(null);
                    } else {
                      context.push('/classifieds/new');
                    }
                  },
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

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          scrollBody,
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
      body: scrollBody,
    );
  }

  Widget _buildSubcategoryHeader(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final root = classifieds.activeRootCategory!;
    final sec = classifieds.activeSecondaryCategory;
    final isTertiaryMode = sec != null && sec.subcategories.isNotEmpty;

    if (isTertiaryMode) {
      final isAllInSec = classifieds.selectedCategoryId == sec.id;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => classifieds.selectCategory(root.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 13, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          root.name,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ),
                Expanded(
                  child: Text(
                    sec.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ChoiceChip(
                selected: isAllInSec,
                avatar: Icon(sec.iconData, size: 15),
                label: Text(
                  'Svi oglasi u „${sec.name}”',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAllInSec ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) => classifieds.selectCategory(sec.id),
              ),
            ),
          ],
        ),
      );
    }

    // Secondary mode: Root category is active
    if (root.subcategories.isNotEmpty) {
      final isAllInRoot = classifieds.selectedCategoryId == root.id;
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Podkategorije: ${root.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ChoiceChip(
                selected: isAllInRoot,
                avatar: Icon(root.iconData, size: 15),
                label: Text(
                  'Svi oglasi u „${root.name}”',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isAllInRoot ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) => classifieds.selectCategory(root.id),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSubcategoriesGrid(
    BuildContext context,
    ClassifiedsProvider classifieds,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final root = classifieds.activeRootCategory!;
    final sec = classifieds.activeSecondaryCategory;
    final isTertiaryMode = sec != null && sec.subcategories.isNotEmpty;

    final List<ClassifiedCategoryModel> items =
        isTertiaryMode ? sec.subcategories : root.subcategories;

    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 52,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final item = items[idx];
            final isSelected = isTertiaryMode
                ? classifieds.selectedCategoryId == item.id
                : (classifieds.activeSecondaryCategory?.id == item.id ||
                    classifieds.selectedCategoryId == item.id);

            return _SubcategoryTile(
              category: item,
              isSelected: isSelected,
              hasChildren: item.subcategories.isNotEmpty,
              onTap: () {
                if (isTertiaryMode) {
                  classifieds.selectCategory(isSelected ? sec.id : item.id);
                } else {
                  classifieds.selectCategory(item.id);
                }
              },
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

/// Pravougaona 2-kolonska kartica podkategorije sa ikonicom i imenom
class _SubcategoryTile extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final bool isSelected;
  final bool hasChildren;
  final VoidCallback onTap;

  const _SubcategoryTile({
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
                color: iconBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.4)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  width: 1,
                ),
              ),
              child: Icon(
                category.iconData,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 11.5,
                  height: 1.15,
                  color: textColor,
                ),
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

/// Grid tile za kategoriju na discovery ekranu
class _CategoryGridTile extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sivkasta boja pozadine kartice (bez zelene nijanse)
    final cardBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    // Crno-bela upečatljiva paleta za krug i ikonicu
    final circleBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1.0,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: circleBgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Icon(
                category.iconData,
                size: 34, // Povećana ikonica sa 28 na 34
                color: iconColor,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                category.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12, // Povećan font za 1 (sa 11 na 12)
                  height: 1.15,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
