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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Kategorija *'),
          subtitle: Text(
            selectedCategoryId != null
                ? (selectedCategoryName ?? selectedCategoryId!)
                : 'Kliknite da izaberete kategoriju',
            style: TextStyle(
              color: selectedCategoryId != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              fontWeight: selectedCategoryId != null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }
}
