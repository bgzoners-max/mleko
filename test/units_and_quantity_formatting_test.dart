import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/utils/quantity_engine.dart';

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
      expect(productKg.formatQuantity(2.25), '2,25 kg');
      expect(productKg.formatQuantity(1.125), '1,125 kg');
    });

    test('formatQuantityWithUnit matches formatQuantity behavior and supports up to 3 decimals', () {
      expect(ProductModel.formatQuantityWithUnit(0.1, ProductModel.unitKg), '100 g');
      expect(ProductModel.formatQuantityWithUnit(0.5, ProductModel.unitKg), '500 g');
      expect(ProductModel.formatQuantityWithUnit(1.0, ProductModel.unitKg), '1 kg');
      expect(ProductModel.formatQuantityWithUnit(2.5, ProductModel.unitKg), '2,5 kg');
      expect(ProductModel.formatQuantityWithUnit(2.25, ProductModel.unitKg), '2,25 kg');
      expect(ProductModel.formatQuantityWithUnit(1.125, ProductModel.unitKg), '1,125 kg');
      expect(ProductModel.formatQuantityWithUnit(1.75, ProductModel.unitL), '1,75 L');
    });
  });

  group('New unit types: veza and pak', () {
    test('formatQuantity and priceFormatted for veza and pak with Slavic plurals', () {
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
      expect(productVeza.formatQuantity(2), '2 veze');
      expect(productVeza.formatQuantity(3), '3 veze');
      expect(productVeza.formatQuantity(4), '4 veze');
      expect(productVeza.formatQuantity(5), '5 veza');
      expect(productVeza.formatQuantity(11), '11 veza');
      expect(productVeza.formatQuantity(12), '12 veza');
      expect(productVeza.formatQuantity(14), '14 veza');
      expect(productVeza.formatQuantity(20), '20 veza');
      expect(productVeza.formatQuantity(21), '21 veza');
      expect(productVeza.formatQuantity(22), '22 veze');
      expect(productVeza.formatQuantity(25), '25 veza');
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
      expect(productPak.formatQuantity(1), '1 pakovanje');
      expect(productPak.formatQuantity(2), '2 pakovanja');
      expect(productPak.formatQuantity(3), '3 pakovanja');
      expect(productPak.formatQuantity(4), '4 pakovanja');
      expect(productPak.formatQuantity(5), '5 pakovanja');
      expect(productPak.formatQuantity(11), '11 pakovanja');
      expect(productPak.formatQuantity(12), '12 pakovanja');
      expect(productPak.formatQuantity(14), '14 pakovanja');
      expect(productPak.formatQuantity(20), '20 pakovanja');
      expect(productPak.formatQuantity(21), '21 pakovanje');
      expect(productPak.formatQuantity(22), '22 pakovanja');
      expect(productPak.formatQuantity(25), '25 pakovanja');
      expect(productPak.quantityUnitLabel, 'pak');
    });

    test('priceNumber and priceFormatted support decimal prices with Serbian comma', () {
      final productDecimal = ProductModel(
        id: 'p-dec',
        sellerId: 's1',
        category: 'sir',
        name: 'Kozji sir',
        pricePerKg: 199.99,
        minOrderKg: 1,
        availableKg: 10,
        unitType: ProductModel.unitKg,
        description: 'Test',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Valjevo',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(productDecimal.priceNumber, '199,99');
      expect(productDecimal.priceFormatted, '199,99 din./kg');
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
      expect(label, contains('3 veze'));
      expect(label, contains('2 pakovanja'));
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

  group('Availability (REPO_BIBLE §11: Upit vs. Magacin)', () {
    test('isAvailable depends on availableNow, availableKg is informative', () {
      final makeToOrder = ProductModel(
        id: 'p-mto',
        sellerId: 's1',
        category: 'mlečni',
        name: 'Svež sir',
        pricePerKg: 600,
        minOrderKg: 0.5,
        availableKg: 0,
        availableNow: true,
        unitType: ProductModel.unitKg,
        description: 'Pravi se sveže po narudžbini',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Ub',
        createdAt: DateTime(2026, 1, 1),
      );

      // availableNow = true, availableKg = 0 -> DOSTUPNO po porudžbini, nema stock info
      expect(makeToOrder.isAvailable, isTrue);
      expect(makeToOrder.hasStockInfo, isFalse);

      final inStock = makeToOrder.copyWith(availableKg: 10);
      expect(inStock.isAvailable, isTrue);
      expect(inStock.hasStockInfo, isTrue);

      final soldOutWithZeroStock = makeToOrder.copyWith(availableNow: false);
      expect(soldOutWithZeroStock.isAvailable, isFalse);
      expect(soldOutWithZeroStock.hasStockInfo, isFalse);

      final soldOutWithResidualStock = makeToOrder.copyWith(
        availableNow: false,
        availableKg: 5,
      );
      expect(soldOutWithResidualStock.isAvailable, isFalse);
      expect(soldOutWithResidualStock.hasStockInfo, isTrue);
    });

    test('QuantityEngine.resolveMaxQuantity calculates reasonable UI stepper bounds', () {
      // 0.1 kg sir (step 0.1): min 0.1 -> max(0.1*20=2.0, 0.1+50*0.1=5.1) -> 5.1 kg
      expect(
        QuantityEngine.resolveMaxQuantity(minQuantity: 0.1, step: 0.1),
        closeTo(5.1, 0.001),
      );

      // 1 L mleko (step 1): min 1 -> max(20, 1+50*1=51) -> 51 L
      expect(
        QuantityEngine.resolveMaxQuantity(minQuantity: 1.0, step: 1.0),
        51.0,
      );

      // 10 kom jaja (step 10): min 10 -> max(200, 10+50*10=510) -> 510 kom
      expect(
        QuantityEngine.resolveMaxQuantity(minQuantity: 10.0, step: 10.0),
        510.0,
      );

      // 50 kg krompir (step 25): candidate = max(1000, 50+1250=1300), defaultCap 1000 -> 1000 kg
      expect(
        QuantityEngine.resolveMaxQuantity(minQuantity: 50.0, step: 25.0),
        1000.0,
      );
    });

    test('ProductModel.maxOrderQuantity delegates to QuantityEngine', () {
      final product = ProductModel(
        id: 'p-step',
        sellerId: 's1',
        category: 'mlečni',
        name: 'Kačkavalj',
        pricePerKg: 1400,
        minOrderKg: 0.2,
        orderStep: 0.1,
        availableKg: 0,
        unitType: ProductModel.unitKg,
        description: 'Test',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Pirot',
        createdAt: DateTime(2026, 1, 1),
      );

      // min 0.2, step 0.1 -> max(0.2*20=4.0, 0.2+50*0.1=5.2) -> 5.2
      expect(product.maxOrderQuantity, closeTo(5.2, 0.001));
    });
  });
}
