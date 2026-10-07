import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/product_card.dart';

void main() {
  group('ProductModel.pricePerUnit', () {
    test('pricePerUnit is an alias for pricePerKg for all unit types', () {
      final productKg = ProductModel(
        id: 'p1',
        sellerId: 's1',
        category: 'sir',
        name: 'Sjenicki sir',
        pricePerKg: 1200.0,
        minOrderKg: 0.5,
        availableKg: 10.0,
        unitType: ProductModel.unitKg,
        description: 'Domaci sir',
        imageUrls: const ['https://example.com/sir.jpg'],
        pickupOptions: const ['licno'],
        location: 'Beograd',
        createdAt: DateTime.now(),
      );
      expect(productKg.pricePerUnit, 1200.0);
      expect(productKg.pricePerUnit, equals(productKg.pricePerKg));

      final productPiece = productKg.copyWith(
        unitType: ProductModel.unitPiece,
        pricePerKg: 950.0,
      );
      expect(productPiece.pricePerUnit, 950.0);
      expect(productPiece.pricePerKg, 950.0);

      final productLiter = productKg.copyWith(
        unitType: ProductModel.unitL,
        pricePerKg: 350.0,
      );
      expect(productLiter.pricePerUnit, 350.0);

      final productVeza = productKg.copyWith(
        unitType: ProductModel.unitVeza,
        pricePerKg: 150.0,
      );
      expect(productVeza.pricePerUnit, 150.0);

      final productPak = productKg.copyWith(
        unitType: ProductModel.unitPak,
        pricePerKg: 400.0,
      );
      expect(productPak.pricePerUnit, 400.0);
    });
  });

  group('ProductCard Hero and Verified Badge', () {
    final testProduct = ProductModel(
      id: 'prod-duplicate-123',
      sellerId: 'seller-1',
      category: 'mlecni',
      name: 'Kačkavalj domaći',
      pricePerKg: 1400.0,
      minOrderKg: 0.5,
      availableKg: 15.0,
      unitType: ProductModel.unitKg,
      description: 'Zlatiborski kačkavalj',
      imageUrls: const ['https://example.com/kackavalj.jpg'],
      pickupOptions: const ['licno'],
      location: 'Zlatibor',
      sellerIsVerified: true,
      createdAt: DateTime.now(),
    );

    testWidgets(
        'Rendering duplicate ProductCards on screen does not throw duplicate Hero tag errors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Kartica u feed-u (enableHero: false po defaultu)
                SizedBox(
                  height: 250,
                  child: ProductCard(product: testProduct),
                ),
                // Ista kartica u sekciji "popularno"
                SizedBox(
                  height: 250,
                  child: ProductCard(product: testProduct),
                ),
              ],
            ),
          ),
        ),
      );

      // Provera da nema exception-a
      expect(tester.takeException(), isNull);

      // Pronalazi oba prikaza naziva proizvoda
      expect(find.text('Kačkavalj domaći'), findsNWidgets(2));

      // Pronalazi verified ikone bez ikakvog aktivnog tickera
      expect(find.byIcon(Icons.verified), findsNWidgets(2));
    });

    testWidgets('ProductCard with enableHero: true renders Hero widget',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 250,
              child: ProductCard(
                product: testProduct,
                enableHero: true,
                heroTag: 'custom_hero_tag',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'custom_hero_tag',
      );
      expect(heroFinder, findsOneWidget);
    });
  });
}
