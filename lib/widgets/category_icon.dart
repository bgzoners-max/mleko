import 'package:flutter/material.dart';

import 'emoji_text.dart';

const _categoryAssetIcons = {
  'cvarci_asset': 'assets/images/categories/cvarci.png',
  'slanina_asset': 'assets/images/categories/slanina.png',
  'sunka_asset': 'assets/images/categories/sunka.png',
};

String _normalizeCategoryIconName(String iconName) =>
    iconName.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

/// Prikazuje ikonu kategorije - emoji (🥛, 🍯) ili Material ikonu
Widget buildCategoryIcon(String? iconName, {double size = 48, Color? color}) {
  Widget iconChild;
  if (iconName == null || iconName.isEmpty) {
    iconChild = Icon(Icons.category, size: size * 0.6, color: color);
  } else {
    final lower = _normalizeCategoryIconName(iconName);
    final assetPath = _categoryAssetIcons[lower];
    if (assetPath != null) {
      iconChild = Image.asset(
        assetPath,
        width: size * 0.7,
        height: size * 0.7,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.category,
          size: size * 0.6,
          color: color,
        ),
      );
    } else {
      final knownIcons = [
        'eco',
        'restaurant',
        'egg',
        'water_drop',
        'bakery_dining',
        'agriculture',
        'local_florist',
        'pets'
      ];
      if (knownIcons.contains(lower)) {
        final iconData = switch (lower) {
          'eco' => Icons.eco,
          'restaurant' => Icons.restaurant,
          'egg' => Icons.egg,
          'water_drop' => Icons.water_drop,
          'bakery_dining' => Icons.bakery_dining,
          'agriculture' => Icons.agriculture,
          'local_florist' => Icons.local_florist,
          'pets' => Icons.pets,
          _ => Icons.category,
        };
        iconChild = Icon(iconData, size: size * 0.6, color: color);
      } else {
        iconChild = EmojiText(
          iconName,
          style: TextStyle(fontSize: size * 0.5, color: color),
        );
      }
    }
  }

  return TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutBack,
    tween: Tween(begin: 0.0, end: 1.0),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (color ?? const Color(0xFF1B5E20)).withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: (color ?? const Color(0xFF1B5E20)).withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF1B5E20)).withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Center(child: iconChild),
        ),
      );
    },
  );
}
