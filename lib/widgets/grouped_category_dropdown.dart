import 'package:flutter/material.dart';
import '../models/category.dart';

/// Dropdown sa grupisanim kategorijama – roditelj (npr. Sirevi) pa podkategorije ispod
class GroupedCategoryDropdown extends StatelessWidget {
  final List<CategoryGroup> groups;
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;
  final String label;

  const GroupedCategoryDropdown({
    super.key,
    required this.groups,
    required this.value,
    required this.onChanged,
    this.validator,
    this.label = 'Kategorija *',
  });

  static const String _headerPrefix = '__HEADER__';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <DropdownMenuItem<String>>[];
    for (final group in groups) {
      items.add(
        DropdownMenuItem<String>(
          value: '$_headerPrefix${group.parent.name}',
          enabled: false,
          child: Text(
            group.parent.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
      for (final child in group.selectable) {
        items.add(
          DropdownMenuItem<String>(
            value: child.name,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(child.name),
            ),
          ),
        );
      }
    }

    final effectiveValue = value != null && _isSelectableValue(value!, groups)
        ? value
        : _firstSelectable(groups);
    return DropdownButtonFormField<String>(
      key: ValueKey(effectiveValue),
      initialValue: effectiveValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: (v) {
        if (v != null && !v.startsWith(_headerPrefix)) {
          onChanged(v);
        }
      },
      validator: validator,
    );
  }

  bool _isSelectableValue(String v, List<CategoryGroup> groups) {
    for (final g in groups) {
      for (final c in g.selectable) {
        if (c.name == v) return true;
      }
    }
    return false;
  }

  String? _firstSelectable(List<CategoryGroup> groups) {
    for (final g in groups) {
      final sel = g.selectable;
      if (sel.isNotEmpty) return sel.first.name;
    }
    return null;
  }
}
