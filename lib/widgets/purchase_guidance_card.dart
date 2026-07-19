import 'package:flutter/material.dart';

class PurchaseGuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? accentColor;

  const PurchaseGuidanceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
