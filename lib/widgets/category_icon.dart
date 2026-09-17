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
    iconChild = Semantics(
      label: 'Kategorija',
      child: Icon(Icons.category, size: size * 0.6, color: color),
    );
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
          style: TextStyle(fontSize: size * 0.75),
        );
      }
    }
  }

  return iconChild;
}

/// Određuje prepoznatljivu boju za kategoriju hrane na osnovu naziva.
Color getFoodCategoryColor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('mlek') || lower.contains('sir') || lower.contains('kajmak')) {
    return const Color(0xFF0288D1); // Mlečni proizvodi - Plava
  }
  if (lower.contains('med') || lower.contains('pčel')) {
    return const Color(0xFFE65100); // Med i pčelinji proizvodi - Zlatno narandžasta
  }
  if (lower.contains('meso') ||
      lower.contains('suhomesnato') ||
      lower.contains('specijalitet') ||
      lower.contains('slanina') ||
      lower.contains('čvarci') ||
      lower.contains('šunka')) {
    return const Color(0xFFB71C1C); // Suhomesnato - Bordo/Crvena
  }
  if (lower.contains('voće') ||
      lower.contains('povrće') ||
      lower.contains('bašta') ||
      lower.contains('zelen')) {
    return const Color(0xFF2E7D32); // Voće i povrće - Sveže zelena
  }
  if (lower.contains('hleb') || lower.contains('peciv') || lower.contains('brašno')) {
    return const Color(0xFF795548); // Peciva i brašno - Topla pekar siva
  }
  if (lower.contains('jaj')) {
    return const Color(0xFFF57F17); // Jaja - Žuto-zlatna
  }
  if (lower.contains('pić') || lower.contains('sok') || lower.contains('vino')) {
    return const Color(0xFF6A1B9A); // Pića i sokovi - Ljubičasta
  }
  return const Color(0xFF1B5E20); // Podrazumevana primarna zelena
}
