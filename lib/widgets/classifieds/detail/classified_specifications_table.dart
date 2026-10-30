import 'package:flutter/material.dart';
import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_design.dart';
import '../../../utils/classified_attributes_engine.dart';

class ClassifiedSpecificationsTable extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const ClassifiedSpecificationsTable({
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
            'Karakteristike predmeta',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Kategorija', ad.categoryName ?? ad.categoryId, colorScheme),
          const Divider(height: 18),
          if (ad.showConditionBadge) ...[
            _buildSpecRow('Stanje', ad.conditionLabel, colorScheme),
            const Divider(height: 18),
          ],
          _buildSpecRow('Mesto / Lokacija', ad.city, colorScheme),
          const Divider(height: 18),
          _buildSpecRow(
            'Prodaje',
            ad.sellerTypeLabel,
            colorScheme,
            icon: ad.isBusinessSeller
                ? Icons.storefront_outlined
                : Icons.person_outline_rounded,
          ),
          const Divider(height: 18),
          if (ad.attributes.isNotEmpty) ...[
            for (final entry in ad.attributes.entries) ...[
              () {
                final val = entry.value;
                if (val == null || val == false) return const SizedBox.shrink();
                final attr =
                    ClassifiedAttributesEngine.findAttributeByKey(entry.key);
                final label = attr?.label ?? entry.key;
                final formatted = attr != null
                    ? attr.formatValue(val)
                    : (val is bool ? (val ? 'Da' : 'Ne') : val.toString());
                if (formatted.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _buildSpecRow(
                      label,
                      formatted,
                      colorScheme,
                      icon: attr?.icon,
                    ),
                    const Divider(height: 18),
                  ],
                );
              }(),
            ],
          ],
          _buildSpecRow('Datum objave', ad.timeAgo, colorScheme),
          const Divider(height: 18),
          _buildSpecRow('Broj pregleda', '${ad.viewsCount} pregleda', colorScheme),
        ],
      ),
    );
  }

  Widget _buildSpecRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: AmazonColors.link),
          ),
          const SizedBox(width: 8),
        ],
        // Expanded (a ne Flexible.loose) da bi kolona vrednosti uvek
        // završavala na desnoj ivici kartice, nezavisno od dužine labele.
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
