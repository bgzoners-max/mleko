import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/seller/product_variants_section.dart';

void main() {
  group('ProductVariant sa podrškom za tipove (Ukus, Vrsta, Nadev, Pakovanje)', () {
    test('ProductVariant serijalizacija sa group poljem', () {
      const variant = ProductVariant(
        id: 'kajsija',
        label: 'Kajsija',
        price: 450,
        group: 'Ukus',
      );

      final json = variant.toJson();
      expect(json['id'], 'kajsija');
      expect(json['label'], 'Kajsija');
      expect(json['price'], 450.0);
      expect(json['group'], 'Ukus');

      final deserialized = ProductVariant.fromJson(json);
      expect(deserialized.id, 'kajsija');
      expect(deserialized.label, 'Kajsija');
      expect(deserialized.price, 450.0);
      expect(deserialized.group, 'Ukus');
      expect(deserialized, equals(variant));
    });

    test('ProductVariant copyWith ispravno ažurira polja', () {
      const variant = ProductVariant(
        id: 'sir',
        label: 'Sa sirom',
        price: 1200,
        group: 'Nadev',
      );

      final updated = variant.copyWith(
        label: 'Sa sirom i zeljem',
        price: 1300,
      );

      expect(updated.id, 'sir');
      expect(updated.label, 'Sa sirom i zeljem');
      expect(updated.price, 1300.0);
      expect(updated.group, 'Nadev');
    });

    test('ProductModel variantGroupTitle prepoznaje eksplicitnu grupu', () {
      final product = ProductModel(
        id: 'p1',
        sellerId: 's1',
        category: 'Džemovi',
        name: 'Domaći džem',
        pricePerKg: 400,
        minOrderKg: 1,
        availableKg: 10,
        unitType: ProductModel.unitPiece,
        description: 'Opis',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Kragujevac',
        createdAt: DateTime(2026, 1, 1),
        variants: const [
          ProductVariant(id: 'jagoda', label: 'Jagoda', price: 400, group: 'Ukus'),
          ProductVariant(id: 'malina', label: 'Malina', price: 450, group: 'Ukus'),
        ],
      );

      expect(product.variantGroupTitle, 'Ukus');
      expect(product.variantSelectorPrompt, 'Izaberi ukus:');
      expect(product.hasUniformVariantPrice, false);
    });

    test('ProductModel hasUniformVariantPrice vraća true kada su cene iste', () {
      final product = ProductModel(
        id: 'p2',
        sellerId: 's1',
        category: 'Pite',
        name: 'Domaća pita ispod sača',
        pricePerKg: 1200,
        minOrderKg: 1,
        availableKg: 5,
        unitType: ProductModel.unitKg,
        description: 'Opis',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Čačak',
        createdAt: DateTime(2026, 1, 1),
        variants: const [
          ProductVariant(id: 'sir', label: 'Sir', price: 1200, group: 'Nadev'),
          ProductVariant(id: 'meso', label: 'Meso', price: 1200, group: 'Nadev'),
          ProductVariant(id: 'krompir', label: 'Krompir', price: 1200, group: 'Nadev'),
        ],
      );

      expect(product.variantGroupTitle, 'Nadev');
      expect(product.variantSelectorPrompt, 'Izaberi nadev:');
      expect(product.hasUniformVariantPrice, true);
    });

    test('ProductModel variantGroupTitle vrši pametnu auto-detekciju za pakovanja', () {
      final product = ProductModel(
        id: 'p3',
        sellerId: 's1',
        category: 'Sokovi',
        name: 'Sok od jabuke',
        pricePerKg: 200,
        minOrderKg: 1,
        availableKg: 20,
        unitType: ProductModel.unitL,
        description: 'Opis',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Požega',
        createdAt: DateTime(2026, 1, 1),
        variants: const [
          ProductVariant(id: '250ml', label: 'Flašica 250 ml', price: 200),
          ProductVariant(id: '1l', label: 'Flaša 1 L', price: 500),
        ],
      );

      expect(product.variantGroupTitle, 'Pakovanje');
      expect(product.variantSelectorPrompt, 'Izaberi pakovanje:');
    });

    test('ProductModel selector prompts za različite grupe', () {
      String getPromptFor(String group) {
        final p = ProductModel(
          id: 'temp',
          sellerId: 's',
          category: 'c',
          name: 'n',
          pricePerKg: 100,
          minOrderKg: 1,
          availableKg: 1,
          description: '',
          imageUrls: const [],
          pickupOptions: const [],
          location: '',
          createdAt: DateTime(2026, 1, 1),
          variants: [
            ProductVariant(id: '1', label: 'Opcija', price: 100, group: group),
          ],
        );
        return p.variantSelectorPrompt;
      }

      expect(getPromptFor('Ukus'), 'Izaberi ukus:');
      expect(getPromptFor('Vrsta'), 'Izaberi vrstu:');
      expect(getPromptFor('Nadev'), 'Izaberi nadev:');
      expect(getPromptFor('Pakovanje'), 'Izaberi pakovanje:');
      expect(getPromptFor('Miris'), 'Izaberi miris:');
      expect(getPromptFor('Oblik'), 'Izaberi oblik:');
    });
  });

  group('ProductVariantsSection Widget Tests', () {
    testWidgets('renderuje dugme za dodavanje varijacija u početnom stanju', (tester) async {
      final basePriceCtrl = TextEditingController(text: '450');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductVariantsSection(
              variants: const [],
              onVariantsChanged: (_) {},
              basePriceController: basePriceCtrl,
            ),
          ),
        ),
      );

      expect(find.textContaining('Dodaj varijacije'), findsOneWidget);
    });

    testWidgets('otvara sekciju sa tipovima varijacija i prečicom za istu cenu', (tester) async {
      final basePriceCtrl = TextEditingController(text: '400');
      List<ProductVariant> emitted = const [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductVariantsSection(
                variants: const [],
                onVariantsChanged: (v) => emitted = v,
                basePriceController: basePriceCtrl,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.textContaining('Dodaj varijacije'));
      await tester.pumpAndSettle();

      expect(find.text('Varijacije proizvoda'), findsOneWidget);
      expect(find.text('Čime se varijante razlikuju?'), findsOneWidget);
      expect(find.textContaining('Ukus / aroma'), findsOneWidget);
      expect(find.textContaining('Vrsta / sorta'), findsOneWidget);
      expect(find.textContaining('Nadev / sastav'), findsOneWidget);
      expect(find.textContaining('Veličina / pakovanje'), findsOneWidget);
      expect(find.textContaining('Sve varijante imaju istu cenu'), findsOneWidget);

      expect(emitted.length, 2);
      expect(emitted.first.group, 'Ukus');
    });
  });
}

