import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/checkout/checkout_product_summary_card.dart';

void main() {
  group('CheckoutProductSummaryCard', () {
    testWidgets('renders product summary with image and guidance', (tester) async {
      final product = ProductModel(
        id: 'prod-1',
        sellerId: 'seller-1',
        category: 'sir',
        name: 'Zlatiborski Kačkavalj',
        pricePerKg: 1200,
        minOrderKg: 1,
        availableKg: 20,
        description: 'Domaći kačkavalj',
        location: 'Zlatibor',
        pickupOptions: const ['Lično'],
        createdAt: DateTime(2026, 1, 1),
        unitType: 'kg',
        imageUrls: const ['https://example.com/kackavalj.jpg'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProductSummaryCard(
              product: product,
              isOffline: false,
            ),
          ),
        ),
      );

      expect(find.text('Šta će se desiti sledeće?'), findsOneWidget);
      expect(find.text('Zlatiborski Kačkavalj'), findsOneWidget);
      expect(find.text('1200 din./kg'), findsOneWidget);
      expect(find.textContaining('OFFLINE'), findsNothing);
    });

    testWidgets('renders fallback icon without image and shows offline badge', (tester) async {
      final product = ProductModel(
        id: 'prod-2',
        sellerId: 'seller-2',
        category: 'med',
        name: 'Bagremov Med',
        pricePerKg: 1000,
        minOrderKg: 0.5,
        availableKg: 15,
        description: 'Domaći med',
        location: 'Valjevo',
        pickupOptions: const ['Dostava'],
        createdAt: DateTime(2026, 1, 1),
        unitType: 'kg',
        imageUrls: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CheckoutProductSummaryCard(
              product: product,
              isOffline: true,
            ),
          ),
        ),
      );

      expect(find.text('Bagremov Med'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.textContaining('OFFLINE'), findsOneWidget);
    });
  });
}
