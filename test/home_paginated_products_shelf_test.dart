import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/constants.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/favorites_provider.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/home/home_paginated_products_shelf.dart';
import 'package:mleko/widgets/product_card.dart';
import 'package:provider/provider.dart';

ProductModel _createProduct(String id, String name, DateTime createdAt) {
  return ProductModel(
    id: id,
    sellerId: 's_$id',
    category: 'zimnica',
    name: name,
    pricePerKg: 800,
    minOrderKg: 1,
    availableKg: 20,
    description: 'Domaći proizvod',
    imageUrls: const [],
    pickupOptions: const ['Lično'],
    location: 'Valjevo',
    createdAt: createdAt,
  );
}

Widget _wrapWithProviders({required Widget child}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(
          create: (_) => AppState(ordersService: OrdersService())),
      ChangeNotifierProvider(create: (_) => FavoritesProvider()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('HomePaginatedProductsShelf', () {
    testWidgets('renders single page without arrows when items <= itemsPerPage',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final products = [
        _createProduct('1', 'Domaći ajvar', now),
        _createProduct('2', 'Sjenički sir', now.subtract(const Duration(days: 30))),
        _createProduct('3', 'Bagremov med', now.subtract(const Duration(days: 60))),
        _createProduct('4', 'Kajmak', now.subtract(const Duration(days: 90))),
      ];

      await tester.pumpWidget(
        _wrapWithProviders(
          child: HomePaginatedProductsShelf(
            products: products,
            salesCounts: const {},
            ratings: const {},
            canFavorite: false,
            userId: null,
            productGridExtent: 290.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Sva 4 proizvoda moraju biti na ekranu (nijedan stari proizvod ne sme nestati!)
      expect(find.text('Domaći ajvar'), findsOneWidget);
      expect(find.text('Sjenički sir'), findsOneWidget);
      expect(find.text('Bagremov med'), findsOneWidget);
      expect(find.text('Kajmak'), findsOneWidget);

      // Kad ima 4 proizvoda na desktopu (stane na jednu stranu), strelice i brojač se ne prikazuju
      expect(find.text('1 / 1'), findsNothing);
      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('paginates when items exceed itemsPerPage and turns page on arrow click',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      // 10 proizvoda: na desktopu (4 kolone x 2 reda = 8 po strani) -> 2 stranice (8 + 2)
      final products = List.generate(
        10,
        (i) => _createProduct('p_$i', 'Proizvod $i', now.subtract(Duration(hours: i))),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: HomePaginatedProductsShelf(
            products: products,
            salesCounts: const {},
            ratings: const {},
            canFavorite: false,
            userId: null,
            productGridExtent: 290.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Prva stranica: prikazuje "1 / 2"
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Proizvod 0'), findsOneWidget);
      expect(find.text('Proizvod 7'), findsOneWidget);

      // Klik na desnu strelicu (sledeća strana)
      final nextArrow = find.byTooltip('Sledeća stranica');
      expect(nextArrow, findsOneWidget);
      await tester.tap(nextArrow);
      await tester.pumpAndSettle();

      // Druga stranica: prikazuje "2 / 2"
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Proizvod 8'), findsOneWidget);
      expect(find.text('Proizvod 9'), findsOneWidget);

      // Klik na levu strelicu (nazad)
      final prevArrow = find.byTooltip('Prethodna stranica');
      expect(prevArrow, findsOneWidget);
      await tester.tap(prevArrow);
      await tester.pumpAndSettle();

      // Vratili smo se na stranu 1
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Proizvod 0'), findsOneWidget);
    });

    testWidgets('NOVO badge appears within 48 hours and disappears after 48 hours',
        (tester) async {
      final now = DateTime.now();
      // 10h star -> NOVO
      final pFresh = _createProduct('fresh', 'Svež ajvar', now.subtract(const Duration(hours: 10)));
      // 36h star -> NOVO (unutar 48h!)
      final pYesterday = _createProduct('yesterday', 'Jučerašnji med', now.subtract(const Duration(hours: 36)));
      // 55h star -> NIJE novo (> 48h)
      final pOlder = _createProduct('older', 'Stari sir', now.subtract(const Duration(hours: 55)));

      await tester.pumpWidget(
        _wrapWithProviders(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ProductCard(
                  product: pFresh,
                  salesCount: 0,
                  isPopular: false,
                  isFavorite: false,
                ),
                ProductCard(
                  product: pYesterday,
                  salesCount: 0,
                  isPopular: false,
                  isFavorite: false,
                ),
                ProductCard(
                  product: pOlder,
                  salesCount: 0,
                  isPopular: false,
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Treba da ima tačno 2 bedža "NOVO" (za pFresh i pYesterday), a 0 za pOlder
      expect(find.text('NOVO'), findsNWidgets(2));
      expect(AppConstants.newProductHours, 48);
    });
  });
}
