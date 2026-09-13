import 'package:flutter/material.dart';

import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';

/// Dropdown meni za izbor sortiranja oglasa (Najnovije, Cena rastuće/opadajuće, Popularno).
class ClassifiedSortDropdown extends StatelessWidget {
  final ClassifiedsProvider classifieds;

  const ClassifiedSortDropdown({
    super.key,
    required this.classifieds,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClassifiedSort>(
          value: classifieds.sort,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          borderRadius: BorderRadius.circular(12),
          items: const [
            DropdownMenuItem(
              value: ClassifiedSort.newest,
              child: Text('Najnovije', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.priceAsc,
              child: Text('Cena: najniža', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.priceDesc,
              child: Text('Cena: najviša', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: ClassifiedSort.popular,
              child: Text('Najpopularnije', style: TextStyle(fontSize: 12)),
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
