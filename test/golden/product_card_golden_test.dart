import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'golden_test_helpers.dart';

/// Golden testovi za [ProductCard] — najzastupljeniji widget u aplikaciji
/// (pijaca feed, kategorije, pretraga, početna).
///
/// Fiksiraju: raspored slojeva (slika/bedževi/omiljeni/cena), boje po temi,
/// i statusne bedževe (RASPRODATO / NOVO / PROVERENO / N+ PRODAJA).
/// Regeneracija: `flutter test --update-goldens test/golden/`.
///
/// Determinističnost: proizvod BEZ slike (prazan `imageUrls`) renderuje
/// `RusticImagePlaceholder` (čist CustomPaint) — nema mrežnih poziva ni
/// keša. Sve ikone su Material (Ahem rasterizer u test okruženju).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  goldenFileComparator = TolerantGoldenFileComparator(
    Uri.parse('test/golden/product_card_golden_test.dart'),
    maxDiffRatio: 0.005,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProductModel buildProduct({
    bool availableNow = true,
    bool sellerIsVerified = false,
    int orderCount = 0,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: 'golden-product-1',
      sellerId: 'seller-1',
      category: 'Med',
      name: 'Bagremov med sa Fruške gore',
      pricePerKg: 1200,
      minOrderKg: 0.5,
      orderStep: 0.5,
      availableKg: 12,
      unitType: ProductModel.unitKg,
      description: 'Domaći, nerađen med iz gazdinstva.',
      imageUrls: const [],
      pickupOptions: const ['Lično', 'Dogovor'],
      location: 'Sremski Karlovci',
      availableNow: availableNow,
      createdAt:
          createdAt ?? DateTime.now().subtract(const Duration(days: 30)),
      sellerIsVerified: sellerIsVerified,
      orderCount: orderCount,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required Brightness brightness,
    required String goldenName,
    required ProductModel product,
    bool isFavorite = false,
    VoidCallback? onFavoriteToggle,
  }) async {
    final settings = AppSettingsProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                height: 320,
                child: ProductCard(
                  product: product,
                  isFavorite: isFavorite,
                  onFavoriteToggle: onFavoriteToggle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProductCard),
      matchesGoldenFile('goldens/$goldenName.png'),
    );
  }

  testWidgets('Golden: ProductCard — svetla tema, čista kartica', (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.light,
      goldenName: 'product_card_light',
      product: buildProduct(),
    );
  });

  testWidgets('Golden: ProductCard — tamna tema', (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.dark,
      goldenName: 'product_card_dark',
      product: buildProduct(),
    );
  });

  testWidgets('Golden: ProductCard — bedževi (RASPRODATO/NOVO/PROVERENO/25+ PRODAJA)',
      (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.light,
      goldenName: 'product_card_badges',
      product: buildProduct(
        availableNow: false,
        sellerIsVerified: true,
        orderCount: 25,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    );
  });

  testWidgets('Golden: ProductCard — omiljeni (puno srce, svetla tema)',
      (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.light,
      goldenName: 'product_card_favorite',
      product: buildProduct(),
      isFavorite: true,
      onFavoriteToggle: () {},
    );
  });
}
