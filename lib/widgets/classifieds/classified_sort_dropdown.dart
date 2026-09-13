import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';

/// Dropdown meni za izbor sortiranja oglasa u Amazon compact stilu.
class ClassifiedSortDropdown extends StatelessWidget {
  final ClassifiedsProvider classifieds;

  const ClassifiedSortDropdown({
    super.key,
    required this.classifieds,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClassifiedSort>(
          value: classifieds.sort,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
          ),
          borderRadius: BorderRadius.circular(8),
          dropdownColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: ClassifiedSort.newest,
              child: Text('Najnovije'),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.priceAsc,
              child: Text('Cena: najniža'),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.priceDesc,
              child: Text('Cena: najviša'),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.popular,
              child: Text('Najpopularnije'),
            ),
          ],
          onChanged: (s) {
            if (s != null) classifieds.changeSort(s);
          },
        ),
      ),
    );
  }
}

