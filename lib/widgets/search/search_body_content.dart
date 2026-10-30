import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import 'search_filter_bar.dart';
import 'search_filter_sidebar.dart';
import 'search_history_panel.dart';
import 'search_input_app_bar.dart';
import 'search_mobile_categories.dart';
import 'search_results_grid.dart';
import 'search_tips_banner.dart';
import 'search_widgets.dart';

class SearchBodyContent extends StatelessWidget {
  const SearchBodyContent({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onClearSearch,
    required this.onSubmittedSearch,
    required this.isTwoPaneLayout,
    required this.isDebounceActive,
    required this.sort,
    required this.onSortChanged,
    required this.region,
    required this.onRegionChanged,
    required this.availableNow,
    required this.onAvailableNowChanged,
    required this.topCategories,
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
    required this.historyFuture,
    required this.isSearchEmpty,
    required this.onClearAllHistory,
    required this.onSelectHistory,
    required this.onRemoveHistory,
    required this.hasActiveFilters,
    required this.onClearActiveFilters,
    required this.onResetSearchFilters,
    required this.products,
    required this.salesCounts,
    required this.ratings,
    required this.user,
    required this.loading,
    required this.loadingMore,
    required this.searchError,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSubmittedSearch;
  final bool isTwoPaneLayout;
  final bool isDebounceActive;
  final ProductSort sort;
  final ValueChanged<ProductSort> onSortChanged;
  final String? region;
  final ValueChanged<String?> onRegionChanged;
  final bool? availableNow;
  final ValueChanged<bool?> onAvailableNowChanged;
  final List<Category> topCategories;
  final String? selectedCategory;
  final Map<String, int> categoryCounts;
  final ValueChanged<String?> onCategorySelected;
  final Future<List<String>> historyFuture;
  final bool isSearchEmpty;
  final VoidCallback onClearAllHistory;
  final ValueChanged<String> onSelectHistory;
  final ValueChanged<String> onRemoveHistory;
  final bool hasActiveFilters;
  final VoidCallback onClearActiveFilters;
  final VoidCallback onResetSearchFilters;
  final List<ProductModel> products;
  final Map<String, int> salesCounts;
  final Map<String, ({double avg, int count})> ratings;
  final UserModel? user;
  final bool loading;
  final bool loadingMore;
  final String? searchError;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  Widget _buildProductCard(int index) {
    final product = products[index];
    final rating = ratings[product.id];
    final count = salesCounts[product.id] ?? 0;
    return SearchProductCard(
      product: product,
      user: user,
      salesCount: count,
      isPopular: count >= AppConstants.popularProductMinSales,
      avgRating: rating?.avg,
      reviewCount: rating?.count,
    );
  }

  Widget _buildEmptyState() => SearchEmptyState(
        hasFilters: hasActiveFilters,
        onResetFilters: onResetSearchFilters,
      );

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final mobileResultsAsGrid = isSmallTablet || isLargeTablet;
    final stackedResultColumns = isLargeTablet ? 3 : 2;
    final stackedGridExtent = isLargeTablet ? 336.0 : 348.0;
    final stackedGridSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 12,
      smallTabletValue: 12,
      largeTabletValue: 14,
      desktop: 14,
    );
    final wideGridColumns = Breakpoints.isDesktop(context) ? 4 : 3;
    final wideGridExtent = Breakpoints.isDesktop(context) ? 380.0 : 356.0;
    final isDesktopOrWeb = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            searchFocusNode.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            searchFocusNode.requestFocus,
        const SingleActivator(LogicalKeyboardKey.slash): () {
          if (!searchFocusNode.hasFocus) {
            searchFocusNode.requestFocus();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (searchController.text.isNotEmpty) {
            onClearSearch();
          } else {
            searchFocusNode.unfocus();
          }
        },
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: SearchInputAppBar(
          controller: searchController,
          focusNode: searchFocusNode,
          isDesktopOrWeb: isDesktopOrWeb,
          onClear: onClearSearch,
          onSubmitted: onSubmittedSearch,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTwoPaneLayout
                  ? Breakpoints.dataContentWidth(context)
                  : Breakpoints.maxContentWidth(context),
            ),
            child: isTwoPaneLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 20,
                        child: SearchFilterSidebar(
                          sort: sort,
                          onSortChanged: onSortChanged,
                          region: region,
                          onRegionChanged: onRegionChanged,
                          availableNow: availableNow,
                          onAvailableNowChanged: onAvailableNowChanged,
                          categories: topCategories,
                          selectedCategory: selectedCategory,
                          categoryCounts: categoryCounts,
                          onCategorySelected: onCategorySelected,
                        ),
                      ),
                      Expanded(
                        flex: 80,
                        child: Column(
                          children: [
                            if (isDebounceActive)
                              const LinearProgressIndicator(minHeight: 2),
                            SearchHistoryPanel(
                              historyFuture: historyFuture,
                              isSearchEmpty: isSearchEmpty,
                              onClearAll: onClearAllHistory,
                              onSelectHistory: onSelectHistory,
                              onRemoveHistory: onRemoveHistory,
                            ),
                            if (hasActiveFilters)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: contentPadding,
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: onClearActiveFilters,
                                    icon: const Icon(Icons.clear_all_rounded,
                                        size: 18),
                                    label: const Text('Očisti filtere'),
                                  ),
                                ),
                              ),
                            SearchTipsBanner(
                              margin: EdgeInsets.symmetric(
                                horizontal: contentPadding,
                                vertical: 4,
                              ),
                            ),
                            Expanded(
                              child: SearchResultsGrid(
                                products: products,
                                loading: loading,
                                loadingMore: loadingMore,
                                searchError: searchError,
                                scrollController: scrollController,
                                onRefresh: onRefresh,
                                onRetry: onRetry,
                                itemBuilder: (ctx, i) => _buildProductCard(i),
                                emptyStateWidget: _buildEmptyState(),
                                crossAxisCount: wideGridColumns,
                                mainAxisExtent: wideGridExtent,
                                spacing: stackedGridSpacing,
                                contentPadding: contentPadding,
                                asGrid: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      if (isDebounceActive)
                        const LinearProgressIndicator(minHeight: 2),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: contentPadding,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategorije',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SearchMobileCategories(
                              categories: topCategories,
                              selectedCategory: selectedCategory,
                              categoryCounts: categoryCounts,
                              onCategorySelected: onCategorySelected,
                            ),
                          ],
                        ),
                      ),
                      SearchHistoryPanel(
                        historyFuture: historyFuture,
                        isSearchEmpty: isSearchEmpty,
                        onClearAll: onClearAllHistory,
                        onSelectHistory: onSelectHistory,
                        onRemoveHistory: onRemoveHistory,
                      ),
                      SearchFilterBar(
                        sort: sort,
                        onSortChanged: onSortChanged,
                        region: region,
                        onRegionChanged: onRegionChanged,
                        availableNow: availableNow,
                        onAvailableNowChanged: onAvailableNowChanged,
                      ),
                      if (hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: onClearActiveFilters,
                              icon:
                                  const Icon(Icons.clear_all_rounded, size: 18),
                              label: const Text('Očisti filtere'),
                            ),
                          ),
                        ),
                      SearchTipsBanner(
                        margin: EdgeInsets.symmetric(
                          horizontal: contentPadding,
                          vertical: 4,
                        ),
                      ),
                      Expanded(
                        child: SearchResultsGrid(
                          products: products,
                          loading: loading,
                          loadingMore: loadingMore,
                          searchError: searchError,
                          scrollController: scrollController,
                          onRefresh: onRefresh,
                          onRetry: onRetry,
                          itemBuilder: (ctx, i) => _buildProductCard(i),
                          emptyStateWidget: _buildEmptyState(),
                          crossAxisCount:
                              mobileResultsAsGrid ? stackedResultColumns : 2,
                          mainAxisExtent:
                              mobileResultsAsGrid ? stackedGridExtent : 255,
                          spacing: stackedGridSpacing,
                          contentPadding: contentPadding,
                          asGrid: mobileResultsAsGrid,
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
