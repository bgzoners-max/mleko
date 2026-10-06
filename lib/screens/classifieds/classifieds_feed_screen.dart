import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../core/web_seo.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/classifieds/classified_ad_card.dart';
import '../../widgets/classifieds/classified_category_tiles.dart';
import '../../widgets/classifieds/classified_sort_dropdown.dart';
import '../../widgets/classifieds/classified_city_button.dart';
import '../../widgets/classifieds/classified_condition_chips.dart';
import '../../widgets/classifieds/classified_active_filters.dart';
import '../../widgets/classifieds/classified_attribute_filter_bar.dart';
import '../../widgets/classifieds/classified_category_chips_row.dart';
import '../../widgets/classifieds/classified_subcategory_header.dart';
import '../../widgets/classifieds/classified_feed_header.dart';
import '../../widgets/classifieds/classified_search_bar.dart';
import '../../widgets/classifieds/classified_subcategories_slivers.dart';
import '../../widgets/classifieds/classifieds_desktop_feed_view.dart';
import '../../widgets/app_footer.dart';

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
          // Standalone Amazon Header ako nismo na početnoj (embedded) i nismo na desktopu
          if (!widget.isEmbedded &&
              MediaQuery.sizeOf(context).width < Breakpoints.largeTablet)
            const SliverToBoxAdapter(
              child: ClassifiedFeedHeader(),
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
                  ClassifiedSearchBar(
                    classifieds: classifieds,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),

                  // Filteri grad + kategorije + sort (jedan red na desktopu, dva reda na mobilnom)
                  const SizedBox(height: 8),
                  if (isDesktop) ...[
                    // JEDAN RED NA DESKTOPU: [ SVI GRADOVI ] [ STANJE (ako važi) ] [ <- KATEGORIJE ... -> ] [ NAJNOVIJE v ]
                    Row(
                      children: [
                        ClassifiedCityButton(classifieds: classifieds),
                        const SizedBox(width: 8),
                        ClassifiedConditionChips(classifieds: classifieds),
                        const SizedBox(width: 8),
                        if (classifieds.categories.isNotEmpty)
                          Expanded(
                            child: ClassifiedCategoryChipsRow(
                              classifieds: classifieds,
                              colorScheme: colorScheme,
                              isDesktop: true,
                              scrollController: _categoryChipsScrollController,
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
                          child: ClassifiedCityButton(classifieds: classifieds),
                        ),
                        const SizedBox(width: 8),
                        ClassifiedSortDropdown(classifieds: classifieds),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Red 2: Stanje (ako važi) + Promocije (Istaknuto, Hitno)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ClassifiedConditionChips(classifieds: classifieds),
                    ),
                  ],

                  if (isFiltered)
                    ClassifiedActiveFilters(
                      classifieds: classifieds,
                      colorScheme: colorScheme,
                      searchController: _searchController,
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
                  child: ClassifiedCategoryChipsRow(
                    classifieds: classifieds,
                    colorScheme: colorScheme,
                    isDesktop: false,
                    scrollController: _categoryChipsScrollController,
                  ),
                ),
              ),

            // Header podkategorija sa navigacijom (breadcrumbs) i dugmetom 'Sve u...'
            if (classifieds.activeRootCategory != null)
              SliverToBoxAdapter(
                child: ClassifiedSubcategoryHeader(
                  classifieds: classifieds,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),

            // 2. Podkategorije (grupisane sekcije po državama ili standardna mreža)
            if (classifieds.activeRootCategory != null)
              ...buildClassifiedSubcategoriesSlivers(context, classifieds, theme, colorScheme),

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
                    child: ClassifiedAttributeFilterBar(
                      classifieds: classifieds,
                      colorScheme: colorScheme,
                      attributes: catAttrs,
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
                      icon: Icon(
                        Icons.close,
                        size: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AmazonColors.lightGreen
                            : AmazonColors.link,
                      ),
                      label: Text(
                        'Poništi filtere',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AmazonColors.lightGreen
                              : AmazonColors.link,
                        ),
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

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: AppFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );

    final canvasColor = AmazonColors.getCanvas(context);

    final desktopContent = ClassifiedsDesktopFeedView(
      classifieds: classifieds,
      user: user,
      searchController: _searchController,
      scrollController: _scrollController,
      isRefreshing: isRefreshing,
      isFiltered: isFiltered,
      isGuest: isGuest,
      headerWidget: widget.headerWidget,
      onSearchChanged: _onSearchChanged,
    );

    final content = isDesktop
        ? desktopContent
        : Material(
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
      appBar: (widget.isEmbedded || isDesktop)
          ? null
          : AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Mali oglasi'),
              actions: const [AppHomeButton()],
            ),
      backgroundColor: canvasColor,
      floatingActionButton: fab,
      body: content,
    );
  }






}

