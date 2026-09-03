import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/classifieds/classified_ad_card.dart';
import '../../widgets/classifieds/classified_category_chip.dart';

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

  static const _serbianCities = [
    'Svi gradovi',
    'Beograd',
    'Novi Sad',
    'Niš',
    'Kragujevac',
    'Subotica',
    'Zrenjanin',
    'Pančevo',
    'Čačak',
    'Kruševac',
    'Kraljevo',
    'Smederevo',
    'Leskovac',
    'Užice',
    'Valjevo',
    'Vranje',
    'Šabac',
    'Sombor',
    'Požarevac',
    'Pirot',
    'Zaječar',
    'Kikinda',
    'Sremska Mitrovica',
    'Jagodina',
    'Vršac',
    'Bor',
    'Prokuplje',
    'Loznica',
    'Gornji Milanovac',
    'Zlatibor',
  ];

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
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtl,
                    itemCount: _serbianCities.length,
                    itemBuilder: (c, i) {
                      final city = _serbianCities[i];
                      final isAll = i == 0;
                      final isSelected = isAll
                          ? provider.selectedCity == null
                          : provider.selectedCity == city;

                      return ListTile(
                        title: Text(city),
                        trailing: isSelected
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () {
                          provider.selectCity(isAll ? null : city);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
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

    // FAB ekstraktovan kao lokalna varijabla
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

    // Scroll tijelo ekstraktovano kao lokalna varijabla
    final scrollBody = RefreshIndicator(
      onRefresh: classifieds.refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Opcioni zaglavlje (npr. MarketModeSwitcher)
          if (widget.headerWidget != null)
            SliverToBoxAdapter(child: widget.headerWidget!),

          // Traka za pretragu i brze filtere
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Pretraži oglasnik (traktori, alati, auto, tehnika...)',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const SizedBox(height: 10),

                  // Filteri: Grad + Sort
                  Row(
                    children: [
                      // Filter grada
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

                      // Filter sortiranja
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

          // Horizontalna traka kategorija
          if (classifieds.categories.isNotEmpty)
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
                          label: const Text('Sve kategorije', style: TextStyle(fontSize: 12)),
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
                    final isSelected = classifieds.selectedCategoryId == cat.id;

                    return ClassifiedCategoryChip(
                      category: cat,
                      isSelected: isSelected,
                      onSelected: classifieds.selectCategory,
                    );
                  },
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Prikaz učitavanja ili greške
          if (classifieds.loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (classifieds.ads.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.search_off_outlined,
                title: 'Nema oglasa po izabranim kriterijumima',
                subtitle: 'Pokušajte sa promenom grada, kategorije ili termina pretrage.',
                ctaLabel: 'Poništi filtere',
                ctaIcon: Icons.refresh,
                onCtaPressed: () {
                  _searchController.clear();
                  classifieds.selectCategory(null);
                  classifieds.selectCity(null);
                  classifieds.search(null);
                },
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
                  (ctx, i) {
                    final ad = classifieds.ads[i];
                    return ClassifiedAdCard(ad: ad);
                  },
                  childCount: classifieds.ads.length,
                ),
              ),
            ),

          // Indikator za load more na dnu
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

    // Ugnjezden mod: vraca Stack bez Scaffolda (HomeScreen vec ima Scaffold)
    if (widget.isEmbedded) {
      return Stack(
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

    // Samostalna ruta: vraca klasican Scaffold
    return Scaffold(
      floatingActionButton: fab,
      body: scrollBody,
    );
  }
}
