import 'package:flutter/material.dart';

import 'emoji_text.dart';

const _categoryAssetIcons = {
  'cvarci_asset': 'assets/images/categories/cvarci.png',
  'slanina_asset': 'assets/images/categories/slanina.png',
  'sunka_asset': 'assets/images/categories/sunka.png',
  'specijaliteti': 'assets/images/categories/sunka.png',
  'suhomesnato': 'assets/images/categories/slanina.png',
  'cvarci': 'assets/images/categories/cvarci.png',
  'slanina': 'assets/images/categories/slanina.png',
  'sunka': 'assets/images/categories/sunka.png',
};

String _normalizeCategoryIconName(String iconName) =>
    iconName.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

/// Pristupačna komponenta za prikaz ikone kategorije ili sekcije
class CategoryIcon extends StatelessWidget {
  final String? iconName;
  final double size;
  final Color? color;
  final String? semanticLabel;

  const CategoryIcon({
    super.key,
    required this.iconName,
    this.size = 48,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final child = buildCategoryIcon(iconName, size: size, color: color);
    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        label: semanticLabel,
        child: child,
      );
    }
    return child;
  }
}

/// Prikazuje ikonu kategorije - asset, Material ikonu ili fallback emoji
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
        'pets',
        'category',
        'hrana',
        'osnove',
        'domace',
        'sveze',
        'pica',
        'ostalo',
      ];
      if (knownIcons.contains(lower)) {
        final iconData = switch (lower) {
          'eco' || 'domace' => Icons.eco,
          'restaurant' || 'hrana' => Icons.restaurant,
          'egg' => Icons.egg,
          'water_drop' || 'pica' => Icons.water_drop,
          'bakery_dining' => Icons.bakery_dining,
          'agriculture' || 'osnove' => Icons.agriculture,
          'local_florist' || 'sveze' => Icons.local_florist,
          'pets' => Icons.pets,
          'category' || 'ostalo' => Icons.category,
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
  return const Color(0xFF245938); // Podrazumevana primarna zelena
}
