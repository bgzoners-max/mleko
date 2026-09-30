import 'package:flutter/material.dart';

class ClassifiedPromotionSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isFeatured;
  final bool isUrgent;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onUrgentChanged;

  const ClassifiedPromotionSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.isFeatured,
    required this.isUrgent,
    required this.onFeaturedChanged,
    required this.onUrgentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: (isFeatured || isUrgent)
              ? (isFeatured ? const Color(0xFFD97706) : const Color(0xFFDC2626))
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: (isFeatured || isUrgent) ? 1.5 : 1.0,
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Promocija oglasa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.star_rounded,
                color: Color(0xFFD97706),
              ),
              title: const Text(
                'Istakni oglas (Featured)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Oglas će se prikazivati na vrhu pretrage i sa zlatnim okvirom.',
              ),
              value: isFeatured,
              onChanged: onFeaturedChanged,
            ),
            const Divider(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFDC2626),
              ),
              title: const Text(
                'Hitna prodaja (Urgent)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Privucite kupce bedžom HITNO u uočljivoj crvenoj boji.',
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
