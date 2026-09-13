import 'package:flutter/material.dart';

import 'search_category_pill.dart';

class SearchMobileCategories extends StatelessWidget {
  final List<dynamic> categories;
  final String? selectedCategory;
  final Map<String, int> categoryCounts;
  final ValueChanged<String?> onCategorySelected;

  const SearchMobileCategories({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.categoryCounts,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < categories.length; index++) ...[
            Builder(
              builder: (context) {
                final cat = categories[index];
                final selected = selectedCategory == cat.name;
                return SearchCategoryPill(
                  label: cat.name,
                  count: categoryCounts[cat.name],
                  icon: cat.icon,
                  selected: selected,
                  fullWidth: false,
                  onTap: () {
                    onCategorySelected(selected ? null : cat.name);
                  },
                );
              },
            ),
            if (index != categories.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
