import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/catalog/products_service.dart';
import 'search_filter_chip.dart';

class SearchFilterBar extends StatelessWidget {
  final ProductSort sort;
  final ValueChanged<ProductSort> onSortChanged;
  final String? region;
  final ValueChanged<String?> onRegionChanged;
  final bool? availableNow;
  final ValueChanged<bool?> onAvailableNowChanged;

  const SearchFilterBar({
    super.key,
    required this.sort,
    required this.onSortChanged,
    required this.region,
    required this.onRegionChanged,
    required this.availableNow,
    required this.onAvailableNowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SearchFilterChip(
            label: 'Sortiraj',
            value: sort.label,
            options: ProductSort.values.map((s) => s.label).toList(),
            onSelected: (v) {
              final idx = ProductSort.values.indexWhere((s) => s.label == v);
              if (idx >= 0) {
                onSortChanged(ProductSort.values[idx]);
              }
            },
          ),
          const SizedBox(width: 8),
          SearchFilterChip(
            label: 'Region',
            value: region,
            options: AppConstants.regions,
            onSelected: onRegionChanged,
          ),
          const SizedBox(width: 8),
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
    );
  }
}
