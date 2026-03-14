import '../models/product_model.dart';

class OrderingPreset {
  final String unitType;
  final double minQuantity;
  final bool forceUnit;

  const OrderingPreset({
    required this.unitType,
    required this.minQuantity,
    this.forceUnit = false,
  });
}

class AgriculturalOrderingDefaults {
  const AgriculturalOrderingDefaults._();

  static OrderingPreset suggest({
    required String category,
    required String name,
    required String description,
    String? currentUnitType,
  }) {
    final haystack = '$category $name $description'.toLowerCase();

    // Med na pijaci se gotovo uvek prodaje na kg (tegla je samo pakovanje).
    if (_containsAny(haystack, const ['med', 'honey'])) {
      return const OrderingPreset(
        unitType: ProductModel.unitKg,
        minQuantity: 0.5,
        forceUnit: true,
      );
    }

    if (_containsAny(haystack, const ['jaje', 'jaja', 'egg'])) {
      return const OrderingPreset(
        unitType: ProductModel.unitPiece,
        minQuantity: 10,
      );
    }

    if (_containsAny(haystack,
        const ['mleko', 'mlijeko', 'milk', 'sok', 'sirup', 'rakij'])) {
      return const OrderingPreset(
        unitType: ProductModel.unitL,
        minQuantity: 1,
      );
    }

    if (_containsAny(
      haystack,
      const [
        'sir',
        'kajmak',
        'suhomesnat',
        'prsut',
        'prsut',
        'kulen',
        'slanina'
      ],
    )) {
      return const OrderingPreset(
        unitType: ProductModel.unitKg,
        minQuantity: 0.5,
      );
    }

    if (_containsAny(
      haystack,
      const ['meso', 'junet', 'svinj', 'telet', 'pilet', 'jagnjet'],
    )) {
      return const OrderingPreset(
        unitType: ProductModel.unitKg,
        minQuantity: 1,
      );
    }

    if (_containsAny(haystack,
        const ['povrc', 'povrć', 'voce', 'voće', 'fruit', 'vegetable'])) {
      return const OrderingPreset(
        unitType: ProductModel.unitKg,
        minQuantity: 1,
      );
    }

    if (_containsAny(haystack, const [
      'zimnica',
      'dzem',
      'džem',
      'pekmez',
      'ajvar',
      'turš',
      'tegla'
    ])) {
      return const OrderingPreset(
        unitType: ProductModel.unitL,
        minQuantity: 1,
      );
    }

    final fallbackUnit = currentUnitType == ProductModel.unitL ||
            currentUnitType == ProductModel.unitPiece
        ? currentUnitType!
        : ProductModel.unitKg;
    return OrderingPreset(
      unitType: fallbackUnit,
      minQuantity: 1,
    );
  }

  static bool isHoneyLike({
    required String category,
    required String name,
    required String description,
  }) {
    final haystack = '$category $name $description'.toLowerCase();
    return _containsAny(haystack, const ['med', 'honey']);
  }

  static bool _containsAny(String text, List<String> keys) {
    for (final key in keys) {
      if (text.contains(key)) {
        return true;
      }
    }
    return false;
  }
}
