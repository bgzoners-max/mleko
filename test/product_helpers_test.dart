import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/product_helpers.dart';

void main() {
  group('inferUnitType', () {
    test('vraća litre za tečne kategorije', () {
      expect(inferUnitType('Kravlje mleko', 'kg'), 'L');
      expect(inferUnitType('Prirodni sok', 'kg'), 'L');
      expect(inferUnitType('Bazga sirup', 'kom'), 'L');
    });

    test('zadržava trenutnu jedinicu za netečne kategorije', () {
      expect(inferUnitType('Zimnica', 'kg'), 'kg');
      expect(inferUnitType('Med', 'kg'), 'kg');
      expect(inferUnitType('Kačkavalj', 'kg'), 'kg');
    });
  });

  group('suggestedOrderStepKg', () {
    test('vraća minOrderKg kao podrazumevani korak', () {
      expect(
        suggestedOrderStepKg(
            category: 'Sir', name: 'Kačkavalj', minOrderKg: 1),
        1,
      );
      expect(
        suggestedOrderStepKg(
            category: 'Sir', name: 'Kackavalj', minOrderKg: 0.05),
        0.05,
      );
      expect(
        suggestedOrderStepKg(category: 'Sir', name: 'Beli sir', minOrderKg: 1),
        1,
      );
      expect(
        suggestedOrderStepKg(category: 'Med', name: 'Bagrem', minOrderKg: 0.5),
        0.5,
      );
    });
  });
}
