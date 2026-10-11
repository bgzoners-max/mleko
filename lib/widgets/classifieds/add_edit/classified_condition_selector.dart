import 'package:flutter/material.dart';

class ClassifiedConditionSelector extends StatelessWidget {
  final bool isConditionApplicable;
  final String condition;
  final ValueChanged<String?> onChanged;

  const ClassifiedConditionSelector({
    super.key,
    required this.isConditionApplicable,
    required this.condition,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConditionApplicable) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      initialValue: (condition == 'new' || condition == 'used')
          ? condition
          : 'used',
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Stanje predmeta',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(
          value: 'used',
          child: Text('Polovno', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'new',
          child: Text('Novo / Nekorišćeno', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
