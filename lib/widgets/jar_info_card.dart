import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../utils/jar_standards.dart';

class JarInfoCard extends StatelessWidget {
  final ProductModel product;
  final EdgeInsetsGeometry? margin;

  const JarInfoCard({
    super.key,
    required this.product,
    this.margin,
  });

  bool get _isHoneyLike {
    final combined =
        [product.name, product.category, product.description].join(' ');
    return JarStandards.isHoneyLike(combined);
  }

  String _massHint(JarSizeStandard jar, bool honeyLike) {
    if (honeyLike) {
      if (jar.ml == 720) return '720 ml ~ 1 kg meda';
      if (jar.ml == 370) return '370 ml ~ 500 g meda';
      final mass = JarStandards.honeyKgFromMl(jar.ml);
      return '${jar.ml} ml ~ ${JarStandards.formatKg(mass)} meda';
    }

    if (jar.ml == 720) {
      return '720 ml ~ 700-900 g neto (zavisno od gustine)';
    }

    final range = JarStandards.genericNetRangeKgFromMl(jar.ml);
    return '${jar.ml} ml ~ ${JarStandards.formatKg(range.minKg)}-${JarStandards.formatKg(range.maxKg)} neto';
  }

  @override
  Widget build(BuildContext context) {
    if (product.unitType != ProductModel.unitL) {
      return const SizedBox.shrink();
    }

    final honeyLike = _isHoneyLike;
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Standardi tegli (orijentaciono)',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            honeyLike
                ? 'Za med: 720 ml odgovara oko 1 kg.'
                : 'ml je zapremina, g/kg je masa. Neto masa zavisi od gustine.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...JarStandards.common.map(
            (jar) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- ${_massHint(jar, honeyLike)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Prazna staklena tegla 720 ml je cesto 250-300 g; plastika je laksa.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
