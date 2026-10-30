import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import '../app_empty_state.dart';
import '../app_footer.dart';
import '../guest_auth_prompt.dart';
import 'classified_active_filters.dart';
import 'classified_ad_card.dart';
import 'classified_attribute_filter_bar.dart';
import 'classified_category_chips_row.dart';
import 'classified_category_tiles.dart';
import 'classified_city_button.dart';
import 'classified_condition_chips.dart';
import 'classified_feed_header.dart';
import 'classified_search_bar.dart';
import 'classified_sort_dropdown.dart';
import 'classified_subcategories_slivers.dart';
import 'classified_subcategory_header.dart';

class ClassifiedsMobileFeedView extends StatelessWidget {
  const ClassifiedsMobileFeedView({
    super.key,
    required this.classifieds,
    required this.user,
    required this.searchController,
    required this.scrollController,
    required this.categoryChipsScrollController,
    required this.isEmbedded,
    required this.isRefreshing,
    required this.isFiltered,
    required this.isGuest,
    required this.isAppOffline,
    required this.isNetworkErr,
    this.headerWidget,
    required this.onSearchChanged,
  });

  final ClassifiedsProvider classifieds;
  final UserModel? user;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ScrollController categoryChipsScrollController;
  final bool isEmbedded;
  final bool isRefreshing;
  final bool isFiltered;
  final bool isGuest;
  final bool isAppOffline;
  final bool isNetworkErr;
  final Widget? headerWidget;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final crossAxisCount = Breakpoints.productGridColumns(context);
    final canvasColor = AmazonColors.getCanvas(context);

    final scrollBody = RefreshIndicator(
      onRefresh: classifieds.refresh,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          if (!isEmbedded)
            const SliverToBoxAdapter(
              child: ClassifiedFeedHeader(),
            ),
          if (headerWidget != null)
            SliverToBoxAdapter(child: headerWidget!),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user?.isAdmin == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/admin/classifieds'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.amber.shade900.withValues(alpha: 0.25)
                                : Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? Colors.amber.shade700
                                  : Colors.amber.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Admin panel: Moderacija prijavljenih oglasa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.amber.shade200
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: isDark
                                    ? Colors.amber.shade200
                                    : Colors.amber.shade900,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ClassifiedSearchBar(
                    classifieds: classifieds,
                    searchController: searchController,
                    onSearchChanged: onSearchChanged,
                  ),
                  const SizedBox(height: 8),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ClassifiedConditionChips(classifieds: classifieds),
                  ),
                  if (isFiltered)
                    ClassifiedActiveFilters(
                      classifieds: classifieds,
                      colorScheme: colorScheme,
                      searchController: searchController,
                    ),
                ],
              ),
            ),
          ),
          if (!isFiltered) ...[
            if (classifieds.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Kategorije',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AmazonColors.darkTextPrimary
                          : AmazonColors.textPrimary,
                    ),
                  ),
                ),
              ),
            if (classifieds.categories.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Breakpoints.isLargeTablet(context)
                        ? 4
                        : (Breakpoints.isSmallTablet(context) ? 3 : 2),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 46,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => CategoryGridTile(
                      category: classifieds.categories[i],
                      onTap: () => classifieds
                          .selectCategory(classifieds.categories[i].id),
                    ),
                    childCount: classifieds.categories.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
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
                        color: isDark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                    if (!classifieds.loading && classifieds.ads.isNotEmpty)
                      Text(
                        '${classifieds.ads.length}+ oglasa',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AmazonColors.darkTextSecondary
                              : AmazonColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (isFiltered && classifieds.categories.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ClassifiedCategoryChipsRow(
                  classifieds: classifieds,
                  colorScheme: colorScheme,
                  isDesktop: false,
                  scrollController: categoryChipsScrollController,
                ),
              ),
            ),
            if (classifieds.activeRootCategory != null)
              SliverToBoxAdapter(
                child: ClassifiedSubcategoryHeader(
                  classifieds: classifieds,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
            if (classifieds.activeRootCategory != null)
              ...buildClassifiedSubcategoriesSlivers(
                context,
                classifieds,
                theme,
                colorScheme,
              ),
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
                        color: isDark
                            ? AmazonColors.darkTextPrimary
                            : AmazonColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        searchController.clear();
                        classifieds
                          ..selectCategory(null)
                          ..selectCity(null)
                          ..selectCondition(null)
                          ..clearAttributeFilters()
                          ..search(null);
                      },
                      icon: Icon(
                        Icons.close,
                        size: 14,
                        color:
                            isDark ? AmazonColors.lightGreen : AmazonColors.link,
                      ),
                      label: Text(
                        'Poništi filtere',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
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
          if (classifieds.loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (classifieds.ads.isEmpty && (isAppOffline || isNetworkErr))
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: AppEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Nema internet veze',
                  subtitle:
                      'Proverite vašu internet konekciju i pokušajte ponovo da učitate oglase.',
                  ctaLabel: 'Pokušaj ponovo',
                  ctaIcon: Icons.refresh,
                  onCtaPressed: classifieds.refresh,
                ),
              ),
            )
          else if (classifieds.error != null && classifieds.ads.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: isFiltered
                      ? 'Nema pronađenih oglasa'
                      : 'Još nema oglasa u ovoj kategoriji',
                  subtitle: isFiltered
                      ? 'Pokušajte sa promenom filtera ili pretrage.'
                      : 'Budite prvi koji će postaviti besplatan oglas i privući kupce!',
                  ctaLabel: isFiltered
                      ? 'Poništi filtere'
                      : 'Postavi besplatan oglas',
                  ctaIcon:
                      isFiltered ? Icons.refresh : Icons.add_circle_outline,
                  onCtaPressed: isFiltered
                      ? () {
                          searchController.clear();
                          classifieds.clearAllFilters();
                        }
                      : () {
                          if (isGuest) {
                            showGuestAuthPrompt(
                              context,
                              title: 'Postavljanje oglasa',
                              message:
                                  'Prijavite se ili se besplatno registrujte da biste postavili oglas za samo 2 minuta.',
                              icon: Icons.add_circle_outline,
                            );
                          } else {
                            context.push('/classifieds/new');
                          }
                        },
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => RepaintBoundary(
                    child: ClassifiedAdCard(ad: classifieds.ads[i]),
                  ),
                  childCount: classifieds.ads.length,
                ),
              ),
            ),
          if (classifieds.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          const SliverToBoxAdapter(child: AppFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );

    return Material(
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
  }
}
