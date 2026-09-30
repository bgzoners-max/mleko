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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: (condition == 'new' || condition == 'used')
              ? condition
              : 'used',
          decoration: const InputDecoration(labelText: 'Stanje predmeta'),
          items: const [
            DropdownMenuItem(value: 'used', child: Text('Polovno')),
            DropdownMenuItem(value: 'new', child: Text('Novo / Nekorišćeno')),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
