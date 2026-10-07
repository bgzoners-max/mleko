import 'package:flutter/material.dart';

/// Metrika (pregledi, pozivi, deljenja) — dio kartice oglasa,
/// izvučena iz MyClassifiedAdsScreen da smanji veličinu ekrana.
class MetricBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final String tooltip;
  final Color color;

  const MetricBadge({
    super.key,
    required this.icon,
    required this.text,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
