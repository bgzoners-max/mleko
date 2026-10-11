import 'package:flutter/material.dart';

class ClassifiedPromotionSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isUrgent;
  final ValueChanged<bool> onUrgentChanged;

  const ClassifiedPromotionSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.isUrgent,
    required this.onUrgentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUrgent
              ? const Color(0xFFDC2626)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isUrgent ? 1.5 : 1.0,
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hitna prodaja',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFDC2626),
              ),
              title: const Text(
                'Označi kao HITNO',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: const Text(
                'Privucite kupce uočljivim crvenim bedžom HITNO u pretrazi.',
                style: TextStyle(fontSize: 11),
              ),
              value: isUrgent,
              onChanged: onUrgentChanged,
            ),
          ],
        ),
      ),
    );
  }
}
