import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/utils/quantity_engine.dart';

void main() {
  group('QuantityEngine.resolveStep', () {
    test('prioritizes explicit positive orderStep', () {
      expect(
        QuantityEngine.resolveStep(orderStep: 0.1, minQuantity: 0.5),
        closeTo(0.1, 0.000001),
      );
      expect(
        QuantityEngine.resolveStep(orderStep: 0.25, minQuantity: 1.0),
        closeTo(0.25, 0.000001),
      );
    });

    test('falls back to minQuantity when orderStep is null or non-positive', () {
      expect(
        QuantityEngine.resolveStep(orderStep: null, minQuantity: 0.5),
        closeTo(0.5, 0.000001),
      );
      expect(
        QuantityEngine.resolveStep(orderStep: 0.0, minQuantity: 2.0),
        closeTo(2.0, 0.000001),
      );
      expect(
        QuantityEngine.resolveStep(orderStep: -0.5, minQuantity: 1.5),
        closeTo(1.5, 0.000001),
      );
    });

    test('falls back to 1.0 when both orderStep and minQuantity are 0 or less', () {
      expect(
        QuantityEngine.resolveStep(orderStep: null, minQuantity: 0.0),
        closeTo(1.0, 0.000001),
      );
      expect(
        QuantityEngine.resolveStep(orderStep: 0.0, minQuantity: 0.0),
        closeTo(1.0, 0.000001),
      );
    });
  });

  group('QuantityEngine.isProductQuantityValid', () {
    test('validates correct multiples of step from minOrderKg', () {
      // min: 0.5, step: 0.1 => 0.5, 0.6, 0.7...
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 0.5,
          minOrderKg: 0.5,
          orderStep: 0.1,
        ),
        isTrue,
      );
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 0.7,
          minOrderKg: 0.5,
          orderStep: 0.1,
        ),
        isTrue,
      );
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 1.0,
          minOrderKg: 0.5,
          orderStep: 0.1,
        ),
        isTrue,
      );
    });

    test('rejects quantity below minOrderKg', () {
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 0.4,
          minOrderKg: 0.5,
          orderStep: 0.1,
        ),
        isFalse,
      );
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 0.0,
          minOrderKg: 1.0,
          orderStep: 0.5,
        ),
        isFalse,
      );
    });

    test('rejects quantity not aligned with order step', () {
      // min: 1.0, step: 0.5 => 1.0, 1.5, 2.0...
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 1.3,
          minOrderKg: 1.0,
          orderStep: 0.5,
        ),
        isFalse,
      );
      expect(
        QuantityEngine.isProductQuantityValid(
          quantity: 1.25,
          minOrderKg: 1.0,
          orderStep: 0.5,
        ),
        isFalse,
      );
    });
  });

  group('QuantityEngine.isValidQuantity', () {
    test('standard floating point stability', () {
      expect(
        QuantityEngine.isValidQuantity(
          quantity: 0.3,
          minQuantity: 0.1,
          step: 0.1,
        ),
        isTrue,
      );
      expect(
        QuantityEngine.isValidQuantity(
          quantity: 0.7,
          minQuantity: 0.1,
          step: 0.2,
        ),
        isTrue,
      );
    });
  });

  group('QuantityEngine.normalizeQuantity', () {
    test('clamps and rounds to nearest valid step', () {
      expect(
        QuantityEngine.normalizeQuantity(
          quantity: 0.2,
          minQuantity: 0.5,
          step: 0.25,
        ),
        equals(0.5),
      );
      expect(
        QuantityEngine.normalizeQuantity(
          quantity: 1.2,
          minQuantity: 1.0,
          step: 0.5,
        ),
        equals(1.0),
      );
      expect(
        QuantityEngine.normalizeQuantity(
          quantity: 1.3,
          minQuantity: 1.0,
          step: 0.5,
        ),
        equals(1.5),
      );
    });
  });

  group('QuantityEngine.generateQuantities', () {
    test('generates expected stepped list', () {
      final list = QuantityEngine.generateQuantities(
        minQuantity: 0.5,
        maxLimit: 1.5,
        step: 0.5,
      );
      expect(list, equals([0.5, 1.0, 1.5]));
    });
  });
}
