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

  group('isKackavaljLike', () {
    test('prepoznaje obe varijante pisanja', () {
      expect(isKackavaljLike('Kackavalj'), isTrue);
      expect(isKackavaljLike('Kačkavalj'), isTrue);
      expect(isKackavaljLike('Zlatiborski kačkavalj'), isTrue);
      expect(isKackavaljLike('Sir'), isFalse);
    });
  });

  group('suggestedOrderStepKg', () {
    test('za kačkavalj vraća 0.1 kg osim kad je min manji', () {
      expect(
        suggestedOrderStepKg(
            category: 'Sir', name: 'Kačkavalj', minOrderKg: 1),
        0.1,
      );
      expect(
        suggestedOrderStepKg(
            category: 'Sir', name: 'Kackavalj', minOrderKg: 0.05),
        0.05,
      );
    });

    test('za ostale vraća minOrderKg', () {
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
