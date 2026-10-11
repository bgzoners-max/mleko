import 'package:flutter/material.dart';

class ClassifiedCategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const ClassifiedCategorySelector({
    super.key,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Kategorija *',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        child: Text(
          selectedCategoryId != null
              ? (selectedCategoryName ?? selectedCategoryId!)
              : 'Kliknite da izaberete kategoriju',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            color: selectedCategoryId != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontWeight: selectedCategoryId != null
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
