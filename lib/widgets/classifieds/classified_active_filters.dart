import 'package:flutter/material.dart';
import '../../constants/serbian_districts.dart';
import '../../core/design_system.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/classified_attributes_engine.dart';
import 'classified_subscription_chip.dart';

class ClassifiedActiveFilters extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final ColorScheme colorScheme;
  final TextEditingController searchController;

  const ClassifiedActiveFilters({
    super.key,
    required this.classifieds,
    required this.colorScheme,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 13,
                color: isDark ? AmazonColors.amberLight : AmazonColors.darkNavy,
              ),
              const SizedBox(width: 3),
              Text(
                'Filteri:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
          if (classifieds.selectedCity != null)
            InputChip(
              avatar: const Icon(Icons.location_on, size: 13),
              label: Text(classifieds.selectedCity!, style: const TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.selectCity(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedDistrict != null) ...[
            () {
              final dist = SerbianDistricts.findDistrictById(classifieds.selectedDistrict!);
              final name = dist?.name ?? classifieds.selectedDistrict!;
              return InputChip(
                avatar: const Icon(Icons.map_outlined, size: 13),
                label: Text('Okrug: $name', style: const TextStyle(fontSize: 11)),
                onDeleted: () => classifieds.selectDistrict(null),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              );
            }(),
          ],
          if (classifieds.minPrice != null || classifieds.maxPrice != null)
            InputChip(
              avatar: const Icon(Icons.payments_outlined, size: 13),
              label: Text(
                'Cena: ${classifieds.minPrice != null ? '${classifieds.minPrice!.toInt()}€' : '0€'} - ${classifieds.maxPrice != null ? '${classifieds.maxPrice!.toInt()}€' : '∞'}',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.setPriceRange(minPrice: null, maxPrice: null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedCondition != null)
            InputChip(
              avatar: Icon(
                classifieds.selectedCondition == 'new'
                    ? Icons.check_circle_outline
                    : Icons.inventory_2_outlined,
                size: 13,
              ),
              label: Text(
                classifieds.selectedCondition == 'new' ? 'Novo' : 'Polovno',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.selectCondition(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.searchQuery != null && classifieds.searchQuery!.isNotEmpty)
            InputChip(
              avatar: const Icon(Icons.search, size: 13),
              label: Text('„${classifieds.searchQuery}”', style: const TextStyle(fontSize: 11)),
              onDeleted: () {
                searchController.clear();
                classifieds.search(null);
              },
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.onlyFeatured)
            InputChip(
              avatar: const Icon(Icons.star_rounded, size: 13, color: AmazonColors.amberDark),
              label: const Text('Istaknuto', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyFeatured(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.onlyUrgent)
            InputChip(
              avatar: const Icon(Icons.bolt_rounded, size: 13, color: AmazonColors.badgeRed),
              label: const Text('Hitno', style: TextStyle(fontSize: 11)),
              onDeleted: () => classifieds.setOnlyUrgent(false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedSellerType != null)
            InputChip(
              avatar: Icon(
                classifieds.selectedSellerType == 'business'
                    ? Icons.storefront_outlined
                    : Icons.person_outline_rounded,
                size: 13,
                color: classifieds.selectedSellerType == 'business'
                    ? const Color(0xFF2563EB)
                    : null,
              ),
              label: Text(
                classifieds.selectedSellerType == 'business'
                    ? 'Firme / Trgovci'
                    : 'Fizička lica',
                style: const TextStyle(fontSize: 11),
              ),
              onDeleted: () => classifieds.selectSellerType(null),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            ),
          if (classifieds.selectedAttributes.isNotEmpty) ...[
            for (final entry in classifieds.selectedAttributes.entries) ...[
              () {
                final attr =
                    ClassifiedAttributesEngine.findAttributeByKey(entry.key);
                final label = attr?.label ?? entry.key;
                final formatted = attr != null
                    ? attr.formatValue(entry.value)
                    : entry.value.toString();
                return InputChip(
                  avatar:
                      attr?.icon != null ? Icon(attr!.icon, size: 13) : null,
                  label: Text('$label: $formatted',
                      style: const TextStyle(fontSize: 11)),
                  onDeleted: () => classifieds.removeAttributeFilter(entry.key),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                  side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                );
              }(),
            ],
          ],
          if (classifieds.selectedCategoryId != null ||
              (classifieds.searchQuery != null &&
                  classifieds.searchQuery!.isNotEmpty))
            ActionChip(
              avatar: Icon(
                (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? Icons.notifications_active_rounded
                    : Icons.notification_add_outlined,
                size: 13,
                color: (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? AmazonColors.amberDark
                    : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
              ),
              label: Text(
                (classifieds.selectedCategoryId != null &&
                        classifieds.isCategorySubscribed(
                            classifieds.selectedCategoryId!))
                    ? 'Pratite'
                    : 'Sačuvaj pretragu',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
              side: BorderSide(color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              onPressed: () => handleClassifiedSubscribe(
                context,
                classifieds,
                categoryId: classifieds.selectedCategoryId,
                searchQuery: classifieds.searchQuery,
              ),
            ),
          TextButton.icon(
            onPressed: () {
              searchController.clear();
              classifieds.clearAllFilters();
            },
            icon: Icon(Icons.close, size: 12, color: isDark ? AmazonColors.lightGreen : AmazonColors.link),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            label: Text(
              'Poništi sve',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
