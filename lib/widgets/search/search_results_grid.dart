import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../app_error_retry.dart';
import '../app_shimmer.dart';

/// Reusable grid/list view component for displaying search results with loading,
/// error, and empty state handling.
class SearchResultsGrid extends StatelessWidget {
  final List<ProductModel> products;
  final bool loading;
  final bool loadingMore;
  final String? searchError;
  final ScrollController scrollController;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget emptyStateWidget;
  final int crossAxisCount;
  final double mainAxisExtent;
  final double spacing;
  final double contentPadding;
  final bool asGrid;

  const SearchResultsGrid({
    super.key,
    required this.products,
    required this.loading,
    required this.loadingMore,
    required this.searchError,
    required this.scrollController,
    required this.onRefresh,
    required this.onRetry,
    required this.itemBuilder,
    required this.emptyStateWidget,
    required this.crossAxisCount,
    required this.mainAxisExtent,
    required this.spacing,
    required this.contentPadding,
    this.asGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return GridView.builder(
        padding: EdgeInsets.all(contentPadding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: asGrid ? crossAxisCount : 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: asGrid ? mainAxisExtent : 255,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
    }

    if (searchError != null) {
      return AppErrorRetry(
        message: 'Greška pri učitavanju proizvoda.',
        detail: searchError,
        onRetry: onRetry,
      );
    }

    if (products.isEmpty) {
      return emptyStateWidget;
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: asGrid
          ? GridView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(contentPadding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                mainAxisExtent: mainAxisExtent,
              ),
              itemCount: products.length + (loadingMore ? 2 : 0),
              itemBuilder: (context, i) {
                if (i >= products.length) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return itemBuilder(context, i);
              },
            )
          : ListView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(contentPadding),
              itemCount: products.length + (loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == products.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: itemBuilder(context, i),
                );
              },
            ),
    );
  }
}
