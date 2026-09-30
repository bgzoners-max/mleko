import 'package:flutter/material.dart';
import '../../models/category_attribute_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../theme/amazon_colors.dart';

class ClassifiedAttributeFilterBar extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final ColorScheme colorScheme;
  final List<CategoryAttribute> attributes;

  const ClassifiedAttributeFilterBar({
    super.key,
    required this.classifieds,
    required this.colorScheme,
    required this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prikazujemo atribute sa predefinisanim opcijama (select i boolean) za horizontalni brzi filter
    final filterable = attributes
        .where((a) =>
            a.type == AttributeType.select || a.type == AttributeType.boolean)
        .toList();

    if (filterable.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filterable.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final attr = filterable[i];
          final isApplied = classifieds.selectedAttributes.containsKey(attr.key);
          final currentValue = classifieds.selectedAttributes[attr.key];

          if (attr.type == AttributeType.boolean) {
            final isTrue = currentValue == true;
            return FilterChip(
              selected: isTrue,
              label: Text(attr.label, style: const TextStyle(fontSize: 11.5)),
              avatar: attr.icon != null ? Icon(attr.icon, size: 13) : null,
              visualDensity: VisualDensity.compact,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              selectedColor: isDark
                  ? AmazonColors.amber.withValues(alpha: 0.25)
                  : AmazonColors.amberLight.withValues(alpha: 0.35),
              side: BorderSide(
                color: isTrue
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                width: isTrue ? 1.4 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (sel) {
                if (sel) {
                  classifieds.setAttributeFilter(attr.key, true);
                } else {
                  classifieds.removeAttributeFilter(attr.key);
                }
              },
            );
          }

          if (attr.type == AttributeType.select) {
            String labelText = attr.label;
            final options = attr.options ?? const [];
            if (isApplied) {
              final opt = options.firstWhere(
                (o) => o.value == currentValue.toString(),
                orElse: () => CategoryAttributeOption(
                  value: currentValue.toString(),
                  label: currentValue.toString(),
                ),
              );
              labelText = '${attr.label}: ${opt.label}';
            }

            final activeBg = isDark
                ? AmazonColors.amber.withValues(alpha: 0.22)
                : AmazonColors.amberLight.withValues(alpha: 0.35);
            final inactiveBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
            final activeBorder = AmazonColors.amberDark;
            final inactiveBorder = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

            return PopupMenuButton<String>(
              tooltip: attr.label,
              initialValue: currentValue?.toString(),
              onSelected: (val) {
                if (val == '__clear__') {
                  classifieds.removeAttributeFilter(attr.key);
                } else {
                  classifieds.setAttributeFilter(attr.key, val);
                }
              },
              itemBuilder: (context) => [
                if (isApplied)
                  const PopupMenuItem(
                    value: '__clear__',
                    child: Text('Poništi filter',
                        style: TextStyle(color: AmazonColors.badgeRed)),
                  ),
                ...options.map(
                  (opt) => PopupMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isApplied ? activeBg : inactiveBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isApplied ? activeBorder : inactiveBorder,
                    width: isApplied ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (attr.icon != null) ...[
                      Icon(
                        attr.icon,
                        size: 13,
                        color: isApplied
                            ? AmazonColors.amberDark
                            : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isApplied ? FontWeight.w700 : FontWeight.w500,
                        color: isApplied
                            ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                            : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: isApplied
                          ? AmazonColors.amberDark
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
