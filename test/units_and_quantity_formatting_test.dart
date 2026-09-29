import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/product_model.dart';

void main() {
  group('Smart quantity formatting (kg -> g conversion)', () {
    final productKg = ProductModel(
      id: 'p-kg',
      sellerId: 's1',
      category: 'povrće',
      name: 'Beli luk',
      pricePerKg: 800,
      minOrderKg: 0.1,
      availableKg: 5,
      unitType: ProductModel.unitKg,
      description: 'Domaći beli luk',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Valjevo',
      createdAt: DateTime(2026, 1, 1),
    );

    test('formatQuantity formats quantities < 1 kg as grams', () {
      expect(productKg.formatQuantity(0.05), '50 g');
      expect(productKg.formatQuantity(0.1), '100 g');
      expect(productKg.formatQuantity(0.2), '200 g');
      expect(productKg.formatQuantity(0.25), '250 g');
      expect(productKg.formatQuantity(0.5), '500 g');
      expect(productKg.formatQuantity(0.75), '750 g');
    });

    test('formatQuantity formats quantities >= 1 kg as kg', () {
      expect(productKg.formatQuantity(1.0), '1 kg');
      expect(productKg.formatQuantity(1.5), '1,5 kg');
      expect(productKg.formatQuantity(2.0), '2 kg');
    });

    test('formatQuantityWithUnit matches formatQuantity behavior', () {
      expect(ProductModel.formatQuantityWithUnit(0.1, ProductModel.unitKg), '100 g');
      expect(ProductModel.formatQuantityWithUnit(0.5, ProductModel.unitKg), '500 g');
      expect(ProductModel.formatQuantityWithUnit(1.0, ProductModel.unitKg), '1 kg');
      expect(ProductModel.formatQuantityWithUnit(2.5, ProductModel.unitKg), '2,5 kg');
    });
  });

  group('New unit types: veza and pak', () {
    test('formatQuantity and priceFormatted for veza and pak', () {
      final productVeza = ProductModel(
        id: 'p-veza',
        sellerId: 's1',
        category: 'zeleniš',
        name: 'Mladi luk',
        pricePerKg: 70,
        minOrderKg: 1,
        availableKg: 20,
        unitType: ProductModel.unitVeza,
        description: 'Mladi luk u vezicama',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Futog',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(productVeza.priceFormatted, '70 din./veza');
      expect(productVeza.formatQuantity(1), '1 veza');
      expect(productVeza.formatQuantity(5), '5 veza');
      expect(productVeza.quantityUnitLabel, 'veza');

      final productPak = ProductModel(
        id: 'p-pak',
        sellerId: 's1',
        category: 'pečurke',
        name: 'Bukovača',
        pricePerKg: 250,
        minOrderKg: 1,
        availableKg: 15,
        unitType: ProductModel.unitPak,
        description: 'Pakovanje bukovače 400g',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Kragujevac',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(productPak.priceFormatted, '250 din./pak');
      expect(productPak.formatQuantity(1), '1 pak');
      expect(productPak.formatQuantity(3), '3 pak');
      expect(productPak.quantityUnitLabel, 'pak');
    });

    test('ProductModel.fromJson parses unit_type veza and pak correctly', () {
      final p1 = ProductModel.fromJson({
        'id': 'p1',
        'seller_id': 's1',
        'category': 'zeleniš',
        'name': 'Peršun',
        'price_per_kg': 60,
        'min_order_kg': 1,
        'available_kg': 10,
        'unit_type': 'veza',
      });
      expect(p1.unitType, ProductModel.unitVeza);

      final p2 = ProductModel.fromJson({
        'id': 'p2',
        'seller_id': 's1',
        'category': 'jaja',
        'name': 'Domaća jaja 10 kom',
        'price_per_kg': 250,
        'min_order_kg': 1,
        'available_kg': 50,
        'unit_type': 'pak',
      });
      expect(p2.unitType, ProductModel.unitPak);
    });

    test('OrderItemModel.totalQuantityLabel includes veza and pak', () {
      final items = [
        const OrderItemModel(
          productId: '1',
          productName: 'Mladi luk',
          quantityKg: 3,
          unitType: ProductModel.unitVeza,
        ),
        const OrderItemModel(
          productId: '2',
          productName: 'Jaja pakovanje',
          quantityKg: 2,
          unitType: ProductModel.unitPak,
        ),
        const OrderItemModel(
          productId: '3',
          productName: 'Beli luk',
          quantityKg: 0.1,
          unitType: ProductModel.unitKg,
        ),
      ];

      final label = OrderItemModel.totalQuantityLabel(items);
      expect(label, contains('100 g'));
      expect(label, contains('3 veza'));
      expect(label, contains('2 pak'));
    });
  });

  group('parseQuantityKg', () {
    test('parses decimal inputs with dot and comma', () {
      expect(ProductModel.parseQuantityKg('0.1'), 0.1);
      expect(ProductModel.parseQuantityKg('0,1'), 0.1);
      expect(ProductModel.parseQuantityKg('0.25'), 0.25);
      expect(ProductModel.parseQuantityKg('0,5'), 0.5);
      expect(ProductModel.parseQuantityKg('1'), 1.0);
      expect(ProductModel.parseQuantityKg('1.5'), 1.5);
      expect(ProductModel.parseQuantityKg('2,5'), 2.5);
    });

    test('parses inputs with kg suffix', () {
      expect(ProductModel.parseQuantityKg('0.1 kg'), 0.1);
      expect(ProductModel.parseQuantityKg('0,1kg'), 0.1);
      expect(ProductModel.parseQuantityKg('1.5 kg'), 1.5);
    });

    test('parses grams inputs and converts to kg', () {
      expect(ProductModel.parseQuantityKg('100g'), 0.1);
      expect(ProductModel.parseQuantityKg('100 g'), 0.1);
      expect(ProductModel.parseQuantityKg('100 gr'), 0.1);
      expect(ProductModel.parseQuantityKg('100 grama'), 0.1);
      expect(ProductModel.parseQuantityKg('250g'), 0.25);
      expect(ProductModel.parseQuantityKg('500g'), 0.5);
      expect(ProductModel.parseQuantityKg('750 grama'), 0.75);
    });

    test('handles empty or invalid inputs gracefully', () {
      expect(ProductModel.parseQuantityKg(''), 0.0);
      expect(ProductModel.parseQuantityKg('abc'), 0.0);
      expect(ProductModel.parseQuantityKg('-5'), 0.0);
    });
  });
}
