import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../app_empty_state.dart';
import '../app_footer.dart';
import 'classified_active_filters.dart';
import 'classified_ad_card.dart';
import 'classified_search_bar.dart';
import 'classified_sort_dropdown.dart';
import 'classifieds_desktop_sidebar.dart';

/// Prikaz feed-a malih oglasa za desktop rezolucije:
/// Levi bočni panel (270px filteri) + desna kolona (pretraga, sortiranje, grid kartica).
class ClassifiedsDesktopFeedView extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final UserModel? user;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final bool isRefreshing;
  final bool isFiltered;
  final bool isGuest;
  final Widget? headerWidget;
  final ValueChanged<String> onSearchChanged;

  const ClassifiedsDesktopFeedView({
    super.key,
    required this.classifieds,
    required this.user,
    required this.searchController,
    required this.scrollController,
    required this.isRefreshing,
    required this.isFiltered,
    required this.isGuest,
    this.headerWidget,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvasColor = AmazonColors.getCanvas(context);
    final isAppOffline = context.watch<AppState>().isOffline;
    final isNetworkErr = classifieds.error != null &&
        (isAppOffline ||
            classifieds.error!.toLowerCase().contains('socket') ||
            classifieds.error!.toLowerCase().contains('network') ||
            classifieds.error!.toLowerCase().contains('offline') ||
            classifieds.error!.toLowerCase().contains('konekcij') ||
            classifieds.error!.toLowerCase().contains('connection') ||
            classifieds.error!.toLowerCase().contains('host lookup') ||
            classifieds.error!.toLowerCase().contains('timeout'));

    return Material(
      color: canvasColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.dataContentWidth(context),
          ),
          child: RefreshIndicator(
            onRefresh: classifieds.refresh,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Opcioni header (MarketModeSwitcher)
                  if (headerWidget != null) ...[
                    headerWidget!,
                    const SizedBox(height: 16),
                  ],

                  // Suptilni progress bar tokom refresh-a
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isRefreshing ? 3 : 0,
                    child: isRefreshing
                        ? LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Glavni 2-kolonski raspored: Levi Desktop Sidebar (270px) + Desni Feed
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── LEVA KOLONA: FILTRI SIDEBAR ──
                      SizedBox(
                        width: 270,
                        child: ClassifiedsDesktopSidebar(
                          classifieds: classifieds,
                          searchController: searchController,
                        ),
                      ),
                      const SizedBox(width: 24),

                      // ── DESNA KOLONA: PRETRAGA, SORT & GRID OGLASA ──
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (user?.isAdmin == true) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => context.push('/admin/classifieds'),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amber.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.shield_outlined, size: 18, color: Colors.amber.shade900),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Admin panel: Moderacija prijavljenih oglasa',
                                            style: TextStyle(
                                              fontSize: 12.5,
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
                            ClassifiedSearchBar(
                              classifieds: classifieds,
                              searchController: searchController,
                              onSearchChanged: onSearchChanged,
                            ),
                            const SizedBox(height: 12),

                            // Controls bar: Broj pronađenih oglasa + Sort dropdown
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  classifieds.loading
                                      ? 'Učitavanje oglasa...'
                                      : 'Pronađeno ${classifieds.ads.length} oglasa',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                                  ),
                                ),
                                ClassifiedSortDropdown(classifieds: classifieds),
                              ],
                            ),

                            // Aktivni filteri (pills sa opcijom uklanjanja)
                            if (isFiltered) ...[
                              const SizedBox(height: 8),
                              ClassifiedActiveFilters(
                                classifieds: classifieds,
                                colorScheme: colorScheme,
                                searchController: searchController,
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Stanja: Loading / Nema interneta / Greška / Prazno / Grid
                            if (classifieds.loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else if (classifieds.ads.isEmpty && (isAppOffline || isNetworkErr))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: AppEmptyState(
                                  icon: Icons.wifi_off_rounded,
                                  title: 'Nema internet veze',
                                  subtitle: 'Proverite vašu internet vezu i pokušajte ponovo da učitate oglase.',
                                  ctaLabel: 'Pokušaj ponovo',
                                  ctaIcon: Icons.refresh,
                                  onCtaPressed: classifieds.refresh,
                                ),
                              )
                            else if (classifieds.error != null && classifieds.ads.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: AppEmptyState(
                                  icon: Icons.error_outline,
                                  title: 'Greška pri učitavanju',
                                  subtitle: classifieds.error,
                                  ctaLabel: 'Pokušaj ponovo',
                                  ctaIcon: Icons.refresh,
                                  onCtaPressed: classifieds.refresh,
                                ),
                              )
                            else if (classifieds.ads.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: AppEmptyState(
                                  icon: Icons.search_off_outlined,
                                  title: 'Nema oglasa za izabrane filtere',
                                  subtitle: isFiltered
                                      ? 'Pokušajte sa promenom kategorije, cene ili lokacije.'
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
                                          searchController.clear();
                                          classifieds.clearAllFilters();
                                        }
                                      : (isGuest
                                          ? null
                                          : () => context.push('/classifieds/new')),
                                ),
                              )
                            else ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: Breakpoints.isWideDesktop(context) ? 4 : 3,
                                  childAspectRatio: 0.74,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  ),
                                itemCount: classifieds.ads.length,
                                itemBuilder: (ctx, i) => ClassifiedAdCard(ad: classifieds.ads[i]),
                              ),
                              if (classifieds.loadingMore)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),
                  const AppFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
