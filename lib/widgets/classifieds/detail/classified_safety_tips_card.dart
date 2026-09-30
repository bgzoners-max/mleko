import 'package:flutter/material.dart';
import '../../../theme/app_design.dart';
import '../../../theme/amazon_colors.dart';

class ClassifiedSafetyTipsCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isDark;

  const ClassifiedSafetyTipsCard({
    super.key,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceM),
      decoration: BoxDecoration(
        color: isDark
            ? AmazonColors.darkCard
            : const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Savet za bezbednu kupovinu',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Preporučujemo lično preuzimanje i proveru ispravnosti predmeta pre plaćanja. Ne uplaćujte novac unapred nepoznatim licima.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
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
