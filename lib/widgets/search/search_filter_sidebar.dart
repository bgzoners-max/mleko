import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/catalog/products_service.dart';
import 'search_category_pill.dart';
import 'search_filter_chip.dart';

class SearchFilterSidebar extends StatelessWidget {
  final ProductSort sort;
  final ValueChanged<ProductSort> onSortChanged;
  final String? region;
  final ValueChanged<String?> onRegionChanged;
  final bool? availableNow;
  final ValueChanged<bool?> onAvailableNowChanged;
  final List<dynamic> categories;
  final String? selectedCategory;
  final Map<String, int> categoryCounts;
  final ValueChanged<String?> onCategorySelected;

  const SearchFilterSidebar({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.region,
    required this.onRegionChanged,
    required this.availableNow,
    required this.onAvailableNowChanged,
    required this.categories,
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          right: Divider.createBorderSide(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Filteri',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SearchFilterChip(
                  label: 'Sortiraj',
                  value: sort.label,
                  options: ProductSort.values.map((s) => s.label).toList(),
                  onSelected: (v) {
                    final idx =
                        ProductSort.values.indexWhere((s) => s.label == v);
                    if (idx >= 0) {
                      onSortChanged(ProductSort.values[idx]);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SearchFilterChip(
                  label: 'Region',
                  value: region,
                  options: AppConstants.regions,
                  onSelected: onRegionChanged,
                ),
                const SizedBox(height: 8),
                ActionChip(
                  label: const Text('Dostupno sada'),
                  onPressed: () {
                    onAvailableNowChanged(availableNow == true ? null : true);
                  },
                  backgroundColor: availableNow == true
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Kategorije',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ...categories.map(
            (cat) {
              final isSelected = selectedCategory == cat.name;
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: SearchCategoryPill(
                  label: cat.name,
                  count: categoryCounts[cat.name],
                  icon: cat.icon,
                  selected: isSelected,
                  fullWidth: true,
                  onTap: () {
                    onCategorySelected(isSelected ? null : cat.name);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
