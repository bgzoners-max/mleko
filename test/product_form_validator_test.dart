import 'package:flutter_test/flutter_test.dart';

import 'package:mleko/models/category.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/utils/product_form_validator.dart';

void main() {
  group('ProductFormValidator.firstSelectableCategory', () {
    test('returns null when groups are null', () {
      expect(ProductFormValidator.firstSelectableCategory(null), isNull);
    });

    test('returns null when groups are empty', () {
      expect(
          ProductFormValidator.firstSelectableCategory(<CategoryGroup>[]),
          isNull);
    });

    test('returns parent name when group has no children', () {
      // selectable => [parent] kad children nije prazan
      const groups = [
        CategoryGroup(
          parent: Category(id: 'c1', name: 'Voće', section: 'hrana'),
          children: [],
        ),
      ];
      expect(ProductFormValidator.firstSelectableCategory(groups),
          equals('Voće'));
    });

    test('returns the first child of the first group', () {
      const groups = [
        CategoryGroup(
          parent:
              Category(id: 'p1', name: 'Mlečni proizvodi', section: 'hrana'),
          children: [
            Category(id: 'c1', name: 'Kravlji sir', parentId: 'p1'),
            Category(id: 'c2', name: 'Kozji sir', parentId: 'p1'),
          ],
        ),
      ];
      expect(ProductFormValidator.firstSelectableCategory(groups),
          equals('Kravlji sir'));
    });

    test('returns from the first group when multiple groups exist', () {
      const groups = [
        CategoryGroup(
          parent: Category(id: 'p1', name: 'Hrana', section: 'hrana'),
          children: [
            Category(id: 'c1', name: 'Hleb', parentId: 'p1'),
          ],
        ),
        CategoryGroup(
          parent: Category(id: 'p2', name: 'Piće', section: 'pica'),
          children: [
            Category(id: 'c2', name: 'Sok', parentId: 'p2'),
          ],
        ),
      ];
      expect(ProductFormValidator.firstSelectableCategory(groups),
          equals('Hleb'));
    });
  });

  group('ProductFormValidator.resolveOrderStep', () {
    test('returns parsed step when it is greater than zero', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Sir',
          name: 'Kačkavalj',
          unitType: ProductModel.unitKg,
          minOrderKg: 1.0,
          parsedOrderStep: 0.5,
        ),
        equals(0.5),
      );
    });

    test('returns 0.1 when minOrderKg <= 0 and no parsed step', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Med',
          name: 'Livadski med',
          unitType: ProductModel.unitKg,
          minOrderKg: 0.0,
        ),
        equals(0.1),
      );
    });

    test('unitL defaults to 1.0 step', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Tečnost',
          name: 'Mleko',
          unitType: ProductModel.unitL,
          minOrderKg: 2.0,
        ),
        equals(1.0),
      );
    });

    test('unitG defaults to 0.05 step', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Ostalo',
          name: 'Something in grams',
          unitType: ProductModel.unitG,
          minOrderKg: 0.1,
        ),
        equals(0.05),
      );
    });

    test('unitPiece, veza and pak default to 1.0 step', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Komadi',
          name: 'Jaja',
          unitType: ProductModel.unitPiece,
          minOrderKg: 1.0,
        ),
        equals(1.0),
      );
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Zeleni',
          name: 'Peršun',
          unitType: ProductModel.unitVeza,
          minOrderKg: 1.0,
        ),
        equals(1.0),
      );
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Pakovanja',
          name: 'Čaj',
          unitType: ProductModel.unitPak,
          minOrderKg: 1.0,
        ),
        equals(1.0),
      );
    });

    test('kg unit without kačkavalj uses minOrderKg as step', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Sir',
          name: 'Beli sir',
          unitType: ProductModel.unitKg,
          minOrderKg: 0.5,
        ),
        equals(0.5),
      );
    });

    test('kg unit with kačkavalj caps step at 0.1', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Sir',
          name: 'Kačkavalj stari',
          unitType: ProductModel.unitKg,
          minOrderKg: 1.0,
        ),
        equals(0.1),
      );
    });

    test('kg unit with kačkavalj and small minOrder returns minOrder', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Sir',
          name: 'Kačkavalj',
          unitType: ProductModel.unitKg,
          minOrderKg: 0.05,
        ),
        equals(0.05),
      );
    });

    test('step is capped by minOrderKg for unitL', () {
      expect(
        ProductFormValidator.resolveOrderStep(
          category: 'Mleko',
          name: 'Kravlje mleko',
          unitType: ProductModel.unitL,
          minOrderKg: 0.5,
        ),
        equals(0.5),
      );
    });
  });

  group('ProductFormValidator.formatQuantityHint', () {
    test('returns null for empty text', () {
      expect(
        ProductFormValidator.formatQuantityHint('', ProductModel.unitKg),
        isNull);
    });

    test('returns null for whitespace-only text', () {
      expect(
        ProductFormValidator.formatQuantityHint('   ', ProductModel.unitKg),
        isNull);
    });

    test('formats kilograms correctly', () {
      expect(
        ProductFormValidator.formatQuantityHint('0.5', ProductModel.unitKg),
        equals('Prikaz kupcima: 500 g'),
      );
      expect(
        ProductFormValidator.formatQuantityHint('1', ProductModel.unitKg),
        equals('Prikaz kupcima: 1 kg'),
      );
      expect(
        ProductFormValidator.formatQuantityHint('2,5', ProductModel.unitKg),
        equals('Prikaz kupcima: 2,5 kg'),
      );
    });

    test('formats liters correctly', () {
      expect(
        ProductFormValidator.formatQuantityHint('1.5', ProductModel.unitL),
        equals('Prikaz kupcima: 1,5 L'),
      );
      expect(
        ProductFormValidator.formatQuantityHint('2', ProductModel.unitL),
        equals('Prikaz kupcima: 2 L'),
      );
    });

    test('returns null for invalid number input', () {
      expect(
        ProductFormValidator.formatQuantityHint('abc', ProductModel.unitKg),
        isNull);
      expect(
        ProductFormValidator.formatQuantityHint('-2', ProductModel.unitKg),
        isNull);
    });
  });
}
