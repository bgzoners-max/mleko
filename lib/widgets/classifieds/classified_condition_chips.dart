import 'package:flutter/material.dart';
import '../../providers/classifieds_provider.dart';
import '../../theme/amazon_colors.dart';
import 'classified_filter_bottom_sheets.dart';

class ClassifiedConditionChips extends StatelessWidget {
  final ClassifiedsProvider classifieds;

  const ClassifiedConditionChips({
    super.key,
    required this.classifieds,
  });

  @override
  Widget build(BuildContext context) {
    final selected = classifieds.selectedCondition;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildChipItem({
      required bool isSelected,
      required VoidCallback onTap,
      required String label,
      IconData? icon,
      Color? activeColor,
    }) {
      final effectiveColor = activeColor ?? (isDark ? AmazonColors.amberLight : AmazonColors.navNavy);

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: isDark ? 0.28 : 0.12)
                : (isDark ? AmazonColors.darkCard : AmazonColors.cardWhite),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (!isDark && !isSelected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? effectiveColor : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? effectiveColor : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeRootId = classifieds.activeRootCategory?.id;
    final selectedCatId = classifieds.selectedCategoryId;
    final isRealEstate = activeRootId == 'nekretnine' ||
        selectedCatId == 'nekretnine' ||
        (selectedCatId != null &&
            (selectedCatId.contains('stan') ||
                selectedCatId.contains('kuc') ||
                selectedCatId.contains('plac') ||
                selectedCatId.contains('zemlj') ||
                selectedCatId.contains('poslovn') ||
                selectedCatId.contains('vikendic') ||
                selectedCatId.contains('garaz')));

    final hasCondition = classifieds.isConditionApplicableForSelectedCategory;
    final selectedTx = classifieds.selectedAttributes['transaction_type']?.toString();
    final hasPriceOrArea = classifieds.minPrice != null ||
        classifieds.maxPrice != null ||
        classifieds.selectedAttributes.containsKey('min_area_m2') ||
        classifieds.selectedAttributes.containsKey('max_area_m2');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRealEstate) ...[
          buildChipItem(
            isSelected: selectedTx == null,
            onTap: () => classifieds.removeAttributeFilter('transaction_type'),
            label: 'Sve',
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'prodaja',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'prodaja'),
            label: 'Prodaja',
            icon: Icons.sell_outlined,
            activeColor: AmazonColors.navNavy,
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'izdavanje',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'izdavanje'),
            label: 'Izdavanje',
            icon: Icons.vpn_key_outlined,
            activeColor: const Color(0xFF0284C7),
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selectedTx == 'na_dan',
            onTap: () => classifieds.setAttributeFilter('transaction_type', 'na_dan'),
            label: 'Na dan',
            icon: Icons.hotel_outlined,
            activeColor: const Color(0xFF0F766E),
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 18,
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          ),
          const SizedBox(width: 6),
        ] else if (hasCondition) ...[
          buildChipItem(
            isSelected: selected == null,
            onTap: () => classifieds.selectCondition(null),
            label: 'Sve',
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selected == 'new',
            onTap: () => classifieds.selectCondition('new'),
            label: 'Novo',
            icon: Icons.check_circle_outline,
            activeColor: AmazonColors.green,
          ),
          const SizedBox(width: 5),
          buildChipItem(
            isSelected: selected == 'used',
            onTap: () => classifieds.selectCondition('used'),
            label: 'Polovno',
            icon: Icons.inventory_2_outlined,
            activeColor: AmazonColors.navNavy,
          ),
          const SizedBox(width: 6),
          Container(
            width: 1,
            height: 18,
            color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          ),
          const SizedBox(width: 6),
        ],
        buildChipItem(
          isSelected: hasPriceOrArea,
          onTap: () => showClassifiedPriceAndAreaFilterSheet(context, isRealEstate: isRealEstate),
          label: isRealEstate ? 'Cena i m²' : 'Cena',
          icon: Icons.tune_rounded,
          activeColor: AmazonColors.amberDark,
        ),
        const SizedBox(width: 5),
        buildChipItem(
          isSelected: classifieds.onlyFeatured,
          onTap: () => classifieds.setOnlyFeatured(!classifieds.onlyFeatured),
          label: 'Istaknuto',
          icon: Icons.star_rounded,
          activeColor: AmazonColors.amberDark,
        ),
        const SizedBox(width: 5),
        buildChipItem(
          isSelected: classifieds.onlyUrgent,
          onTap: () => classifieds.setOnlyUrgent(!classifieds.onlyUrgent),
          label: 'Hitno',
          icon: Icons.bolt_rounded,
          activeColor: AmazonColors.badgeRed,
        ),
        const SizedBox(width: 6),
        Container(
          width: 1,
          height: 18,
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
        const SizedBox(width: 6),
        buildChipItem(
          isSelected: classifieds.selectedSellerType == 'individual',
          onTap: () => classifieds.selectSellerType(
            classifieds.selectedSellerType == 'individual' ? null : 'individual',
          ),
          label: 'Fizička lica',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(width: 5),
        buildChipItem(
          isSelected: classifieds.selectedSellerType == 'business',
          onTap: () => classifieds.selectSellerType(
            classifieds.selectedSellerType == 'business' ? null : 'business',
          ),
          label: 'Firme / Trgovci',
          icon: Icons.storefront_outlined,
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }
}
