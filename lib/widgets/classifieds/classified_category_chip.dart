import 'package:flutter/material.dart';

import '../../models/classified_category_model.dart';

class ClassifiedCategoryChip extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final bool isSelected;
  final ValueChanged<String?> onSelected;

  const ClassifiedCategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(
          category.iconData,
          size: 16,
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
        ),
        label: Text(
          category.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        onSelected: (selected) {
          onSelected(selected ? category.id : null);
        },
      ),
    );
  }
}
