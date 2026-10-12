import 'package:flutter/material.dart';

import '../../../core/design_system.dart';
import '../../../models/category_attribute_model.dart';
import '../../../providers/classifieds_provider.dart';

/// Sekcija dinamičkih karakteristika i specifikacija kategorije (npr. gorivo, kvadratura, rasa).
class ClassifiedsSidebarAttributesSection extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final List<CategoryAttribute> attributes;
  final bool isDark;

  const ClassifiedsSidebarAttributesSection({
    super.key,
    required this.classifieds,
    required this.attributes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'KARAKTERISTIKE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
        ),
        ...attributes.map((attr) {
          final isApplied = classifieds.selectedAttributes.containsKey(attr.key);
          final currentValue = classifieds.selectedAttributes[attr.key];

          if (attr.type == AttributeType.boolean) {
            final isTrue = currentValue == true;
            return InkWell(
              onTap: () {
                if (isTrue) {
                  classifieds.removeAttributeFilter(attr.key);
                } else {
                  classifieds.setAttributeFilter(attr.key, true);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isTrue ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 15,
                      color: isTrue
                          ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                          : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    if (attr.icon != null) ...[
                      Icon(
                        attr.icon,
                        size: 13,
                        color: isTrue
                            ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                            : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        attr.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isTrue ? FontWeight.w700 : FontWeight.w500,
                          color: isTrue
                              ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                              : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (attr.type == AttributeType.select && (attr.options?.isNotEmpty ?? false)) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attr.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isApplied
                          ? (isDark ? AmazonColors.amber.withValues(alpha: 0.15) : AmazonColors.amberLight.withValues(alpha: 0.3))
                          : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isApplied
                            ? AmazonColors.amberDark
                            : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: currentValue?.toString(),
                        hint: Text(
                          'Sve opcije',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(
                              'Sve opcije',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                              ),
                            ),
                          ),
                          ...attr.options!.map((opt) {
                            return DropdownMenuItem<String>(
                              value: opt.value,
                              child: Text(
                                opt.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val == null) {
                            classifieds.removeAttributeFilter(attr.key);
                          } else {
                            classifieds.setAttributeFilter(attr.key, val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
