import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/utils/quantity_engine.dart';

void main() {
  group('ProductModel order step', () {
    test('quantityStep uses explicit orderStep from product data', () {
      final product = ProductModel(
        id: 'p1',
        sellerId: 's1',
        category: 'mlecni',
        name: 'Sir',
        pricePerKg: 900,
        minOrderKg: 1,
        orderStep: 0.25,
        availableKg: 10,
        unitType: ProductModel.unitKg,
        description: 'Domaci sir',
        imageUrls: [],
        pickupOptions: [],
        location: 'Topola',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(product.quantityStep, 0.25);
    });

    test('fromJson falls back to min_order_kg when order_step is missing', () {
      final product = ProductModel.fromJson({
        'id': 'p2',
        'seller_id': 's2',
        'category': 'mlecni',
        'name': 'Mleko',
        'price_per_kg': 140,
        'min_order_kg': 0.75,
        'available_kg': 30,
        'unit_type': 'L',
        'description': 'Sveze mleko',
        'image_urls': <String>[],
        'pickup_options': <String>[],
        'location': 'Arandjelovac',
        'created_at': '2026-01-02T10:00:00Z',
      });

      expect(product.orderStep, 0.75);
      expect(product.quantityStep, 0.75);
    });

    test('quantityStep falls back to minOrderKg when orderStep is invalid', () {
      final product = ProductModel(
        id: 'p3',
        sellerId: 's3',
        category: 'meso',
        name: 'Junetina',
        pricePerKg: 1200,
        minOrderKg: 1.5,
        orderStep: 0,
        availableKg: 20,
        unitType: ProductModel.unitKg,
        description: 'Sveze meso',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Kragujevac',
        createdAt: DateTime(2026, 1, 3),
      );

      expect(product.quantityStep, 1.5);
    });
  });

  group('QuantityEngine validation with explicit step', () {
    test('validates arbitrary step values without hardcoded unit rules', () {
      const min = 0.6;
      const step = 0.3;

      final valid = QuantityEngine.isValidQuantity(
        quantity: 1.2,
        minQuantity: min,
        step: step,
      );
      final invalid = QuantityEngine.isValidQuantity(
        quantity: 1.1,
        minQuantity: min,
        step: step,
      );

      expect(valid, isTrue);
      expect(invalid, isFalse);
    });

    test('normalizes entered quantity to nearest explicit step', () {
      final normalized = QuantityEngine.normalizeQuantity(
        quantity: 1.08,
        minQuantity: 0.6,
        step: 0.3,
      );

      expect(normalized, 1.2);
    });

    test('accepts quantity exactly equal to minimum', () {
      final validAtMinimum = QuantityEngine.isValidQuantity(
        quantity: 1.0,
        minQuantity: 1.0,
        step: 0.25,
      );

      expect(validAtMinimum, isTrue);
    });

    test('normalization clamps values below minimum to minimum', () {
      final normalized = QuantityEngine.normalizeQuantity(
        quantity: 0.2,
        minQuantity: 0.8,
        step: 0.2,
      );

      expect(normalized, 0.8);
    });
  });
}
