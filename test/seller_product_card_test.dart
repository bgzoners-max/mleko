import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/widgets/seller_product_card.dart';

class _FakeProductsService extends Fake implements ProductsService {
  String? deletedProductId;
  bool updateAvailableNowCalled = false;

  @override
  Future<void> deleteProduct(String id) async {
    deletedProductId = id;
  }

  @override
  Future<void> updateAvailableNow(String productId, bool availableNow) async {
    updateAvailableNowCalled = true;
  }
}

void main() {
  group('SellerProductCard', () {
    late ProductModel product;
    late _FakeProductsService fakeService;
    late bool refreshed;

    setUp(() {
      product = ProductModel(
        id: 'prod-101',
        sellerId: 'seller-1',
        category: 'mlecni-proizvodi',
        name: 'Punomasno mleko',
        pricePerKg: 150,
        minOrderKg: 1,
        availableKg: 10,
        description: 'Sveže domaće mleko',
        location: 'Vojvodina',
        pickupOptions: const ['Lično'],
        createdAt: DateTime(2026, 1, 1),
        unitType: 'L',
        availableNow: true,
        imageUrls: const [],
      );
      fakeService = _FakeProductsService();
      refreshed = false;
    });

    testWidgets('renders product details, edit button, and delete button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SellerProductCard(
              product: product,
              productsService: fakeService,
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      expect(find.text('Punomasno mleko'), findsOneWidget);
      expect(find.textContaining('150 din./L'), findsOneWidget);
      expect(find.text('Dostupno'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('cancels deletion when user taps Odustani', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SellerProductCard(
              product: product,
              productsService: fakeService,
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Trajno brisanje proizvoda'), findsOneWidget);
      expect(
        find.text(
          'Da li ste sigurni da želite trajno da obrišete proizvod „Punomasno mleko”? Ova akcija se ne može poništiti.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Odustani'));
      await tester.pumpAndSettle();

      expect(find.text('Trajno brisanje proizvoda'), findsNothing);
      expect(fakeService.deletedProductId, isNull);
      expect(refreshed, isFalse);
    });

    testWidgets('deletes product, calls onRefresh, and shows SnackBar when confirmed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SellerProductCard(
              product: product,
              productsService: fakeService,
              onRefresh: () => refreshed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trajno obriši'));
      await tester.pumpAndSettle();

      expect(fakeService.deletedProductId, equals('prod-101'));
      expect(refreshed, isTrue);
      expect(find.text('Proizvod „Punomasno mleko” je trajno obrisan.'), findsOneWidget);
    });
  });
}
