import 'package:flutter/material.dart';
import '../../constants/serbian_districts.dart';
import '../../providers/classifieds_provider.dart';
import '../../theme/amazon_colors.dart';
import 'classified_filter_bottom_sheets.dart';

class ClassifiedCityButton extends StatelessWidget {
  final ClassifiedsProvider classifieds;

  const ClassifiedCityButton({
    super.key,
    required this.classifieds,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSelectedCity = classifieds.selectedCity != null;
    final hasSelectedDistrict = classifieds.selectedDistrict != null;
    final hasSelection = hasSelectedCity || hasSelectedDistrict;

    String labelText = 'Sve lokacije';
    if (hasSelectedCity) {
      labelText = classifieds.selectedCity!;
    } else if (hasSelectedDistrict) {
      final d = SerbianDistricts.findDistrictById(classifieds.selectedDistrict!);
      labelText = d?.name ?? classifieds.selectedDistrict!;
    }

    final btnBg = hasSelection
        ? (isDark ? AmazonColors.amber.withValues(alpha: 0.2) : AmazonColors.amberLight.withValues(alpha: 0.25))
        : (isDark ? AmazonColors.darkCard : AmazonColors.cardWhite);
    final btnBorder = hasSelection
        ? AmazonColors.amberDark
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);
    final btnTextColor = hasSelection
        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
        : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary);
    final btnIconColor = hasSelection
        ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
        : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary);

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () => showClassifiedCityPickerSheet(context),
        icon: Icon(
          hasSelectedDistrict ? Icons.map_outlined : Icons.location_on_outlined,
          size: 15,
          color: btnIconColor,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasSelection ? FontWeight.w700 : FontWeight.w500,
                  color: btnTextColor,
                ),
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  classifieds.selectCity(null);
                  classifieds.selectDistrict(null);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 13, color: btnIconColor),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: btnBorder,
            width: hasSelection ? 1.4 : 1.0,
          ),
          backgroundColor: btnBg,
          elevation: 0,
        ),
      ),
    );
  }
}
