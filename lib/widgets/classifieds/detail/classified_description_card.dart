import 'package:flutter/material.dart';
import '../../../models/classified_ad_model.dart';
import '../../../theme/amazon_colors.dart';
import '../../../theme/app_design.dart';

class ClassifiedDescriptionCard extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const ClassifiedDescriptionCard({
    super.key,
    required this.ad,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detaljan opis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ad.description.isEmpty
                ? 'Prodavac nije uneo detaljan opis za ovaj oglas.'
                : ad.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              fontSize: 14.5,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
