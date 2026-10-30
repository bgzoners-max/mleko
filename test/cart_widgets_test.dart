import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/widgets/cart/cart_guest_banner.dart';
import 'package:mleko/widgets/cart/cart_item_tile.dart';
import 'package:mleko/widgets/cart/cart_seller_group_card.dart';

/// Minimalan fake servisa — konvencija iz cart_provider_test.dart.
class FakeProductsService implements ProductsService {
  final Map<String, ProductModel> _mockProducts = {};

  void addMockProduct(ProductModel p) {
    _mockProducts[p.id] = p;
  }

  @override
  Future<ProductModel?> getProduct(String id) async => _mockProducts[id];

  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async {
    final result = <String, ProductModel>{};
    for (final id in ids) {
      if (_mockProducts.containsKey(id)) {
        result[id] = _mockProducts[id]!;
      }
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductModel cartProduct({
  String id = 'p1',
  String name = 'Domaci sir',
  double price = 1200,
}) =>
    ProductModel(
      id: id,
      sellerId: 's1',
      category: 'mlecni',
      name: name,
      pricePerKg: price,
      unitType: 'kg',
      minOrderKg: 1,
      availableKg: 50,
      description: '',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Beograd',
      createdAt: DateTime(2026, 1, 2),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartGuestBanner', () {
    testWidgets('prikazuje poruku o sacuvanoj korpi i poziva onDismiss',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartGuestBanner(onDismiss: () => dismissed = true),
          ),
        ),
      );

      expect(find.text('Sačuvana korpa iz gostujuće sesije'), findsOneWidget);
      expect(
        find.textContaining('prebačeni na vaš nalog'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });

  group('CartItemTile', () {
    testWidgets('prikazuje naziv, kolicinu i izracunatu cenu stavke',
        (tester) async {
      var removeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemTile(
              item: (product: cartProduct(), quantity: 2),
              sellerId: 's1',
              onRemove: () => removeCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Domaci sir'), findsOneWidget);
      // 1200 RSD/kg x 2 kg = 2400 RSD.
      expect(find.text('2400 RSD'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      expect(removeCalled, isTrue);
    });
  });

  group('CartSellerGroupCard', () {
    Widget buildApp({
      required Widget child,
    }) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(body: child),
          ),
          GoRoute(
            path: '/checkout-seller/:sellerId',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('CHECKOUT-REACHED')),
            ),
          ),
        ],
      );

      return ChangeNotifierProvider<CartProvider>(
        create: (_) => CartProvider(productsService: FakeProductsService()),
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('prikazuje prodavca, ukupnu cenu i Naruci dugme',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        buildApp(
          child: CartSellerGroupCard(
            sellerId: 's1',
            sellerName: 'Farma Petrovic',
            location: 'Vojvodina',
            items: [
              (product: cartProduct(), quantity: 2),
              (product: cartProduct(id: 'p2', name: 'Med bagrem'), quantity: 1),
            ],
            onRefresh: () {},
          ),
        ),
      );

      expect(find.text('Farma Petrovic'), findsOneWidget);
      expect(find.text('Vojvodina'), findsOneWidget);
      expect(find.text('Domaci sir'), findsOneWidget);
      expect(find.text('Med bagrem'), findsOneWidget);
      // 1200 x 2 + 1200 x 1 = 3600 RSD.
      expect(find.text('3600 RSD'), findsOneWidget);
      expect(find.text('Naruči'), findsOneWidget);
    });

    testWidgets('Naruci dugme vodi na checkout stranicu prodavca',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        buildApp(
          child: CartSellerGroupCard(
            sellerId: 's1',
            sellerName: 'Farma Petrovic',
            location: 'Vojvodina',
            items: [(product: cartProduct(), quantity: 1)],
            onRefresh: () {},
          ),
        ),
      );

      await tester.tap(find.text('Naruči'));
      await tester.pumpAndSettle();

      expect(find.text('CHECKOUT-REACHED'), findsOneWidget);
    });

    testWidgets('uklanjanje stavke poziva onRefresh i animira listu',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      var refreshCalled = false;

      await tester.pumpWidget(
        buildApp(
          child: CartSellerGroupCard(
            sellerId: 's1',
            sellerName: 'Farma Petrovic',
            location: 'Vojvodina',
            items: [
              (product: cartProduct(), quantity: 2),
              (product: cartProduct(id: 'p2', name: 'Med bagrem'), quantity: 1),
            ],
            onRefresh: () => refreshCalled = true,
          ),
        ),
      );

      // Uklanjanje prve stavke (Domaci sir).
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(refreshCalled, isTrue);
      // Druga stavka ostaje u listi.
      expect(find.text('Med bagrem'), findsOneWidget);
    });
  });
}
