import 'package:flutter/material.dart';

class ClassifiedConditionSelector extends StatelessWidget {
  final bool isConditionApplicable;
  final String condition;
  final String sellerType;
  final ValueChanged<String?> onChanged;

  const ClassifiedConditionSelector({
    super.key,
    required this.isConditionApplicable,
    required this.condition,
    this.sellerType = 'individual',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConditionApplicable) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isBusiness = sellerType == 'business';
    final currentCondition = (condition == 'new' || condition == 'used')
        ? condition
        : (isBusiness ? 'new' : 'used');

    final List<ButtonSegment<String>> segments = isBusiness
        ? const [
            ButtonSegment<String>(
              value: 'new',
              icon: Icon(Icons.verified_outlined, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Novo (sa garancijom / računom)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),
            ButtonSegment<String>(
              value: 'used',
              icon: Icon(Icons.inventory_2_outlined, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Polovno / Kao novo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),
          ]
        : const [
            ButtonSegment<String>(
              value: 'used',
              icon: Icon(Icons.inventory_2_outlined, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Korišćeno (polovno)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),
            ButtonSegment<String>(
              value: 'new',
              icon: Icon(Icons.verified_outlined, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Nekorišćeno / Kao novo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 15,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Stanje predmeta *',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6),
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            segments: segments,
            selected: {currentCondition},
            onSelectionChanged: (newSelection) {
              if (newSelection.isNotEmpty) {
                onChanged(newSelection.first);
              }
            },
          ),
        ),
      ],
    );
  }
}
