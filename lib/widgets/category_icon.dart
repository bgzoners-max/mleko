import 'package:flutter/material.dart';

import 'emoji_text.dart';

/// Prikazuje ikonu kategorije – emoji (🥛, 🍯) ili Material ikonu
Widget buildCategoryIcon(String? iconName, {double size = 48, Color? color}) {
  if (iconName == null || iconName.isEmpty) {
    return Icon(Icons.category, size: size, color: color);
  }
  final lower = iconName.toLowerCase();
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
    return Icon(iconData, size: size, color: color);
  }
  return EmojiText(
    iconName,
    style: TextStyle(fontSize: size * 0.8, color: color),
  );
}
