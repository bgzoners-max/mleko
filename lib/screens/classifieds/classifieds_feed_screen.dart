import 'dart:async';

import 'package:flutter/gestures.dart';
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
            // 1. Red: Horizontalni pregled glavnih kategorija za brzi prelaz (bez ružnog skrolbara, sa glatkim skrolovanjem na točkić i strelice)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
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
          SizedBox(
            width: double.infinity,
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
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (_) => classifieds.selectCategory(activeParent.id),
            ),
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
                mainAxisExtent: 52,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) {
                  final brand = group.subcategories[idx];
                  final isSelected = classifieds.selectedCategoryId == brand.id;

                  return _SubcategoryTile(
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
                mainAxisExtent: 52,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) {
                  final item = standaloneItems[idx];
                  final isSelected = classifieds.selectedCategoryId == item.id;

                  return _SubcategoryTile(
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
            mainAxisExtent: 52,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (ctx, idx) {
              final item = items[idx];
              final isSelected = classifieds.selectedCategoryId == item.id;

              return _SubcategoryTile(
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

Color _getClassifiedCategoryColor(String name) {
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

/// Grid tile za kategoriju na discovery ekranu - organizovan identično kao na strani malih proizvođača
class _CategoryGridTile extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final VoidCallback onTap;

  const _CategoryGridTile({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _getClassifiedCategoryColor(category.name);

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
