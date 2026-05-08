import 'package:flutter/material.dart';

class SearchFilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  const SearchFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      tooltip: label,
      child: Chip(
        label: Text(value ?? label),
        avatar: value != null
            ? const Icon(Icons.close, size: 18, color: Colors.white)
            : null,
        onDeleted: value != null ? () => onSelected(null) : null,
      ),
      itemBuilder: (_) =>
          options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
    );
  }
}
