import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/widgets/product_grid_tile.dart';

void main() {
  testWidgets('ProductGridTile meets tap target and contrast guidelines', (WidgetTester tester) async {
    final product = ProductModel(
      id: 'p1',
      sellerId: 's1',
      name: 'Test Product',
      pricePerKg: 500,
      minOrderKg: 1,
      availableKg: 10,
      unitType: ProductModel.unitKg,
      imageUrls: [],
      category: 'Test',
      description: 'Test description',
      orderStep: 1,
      deliveryMode: ProductDeliveryMode.none,
      selectedDeliveryPointIds: [],
      pickupOptions: [],
      location: 'Novi Sad',
      isDomestic: true,
      availableNow: true,
      createdAt: DateTime.now(),
      sellerIsVerified: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductGridTile(
            product: product,
            isFavorite: false,
            onFavoriteToggle: () {},
            onAddToOrder: () {},
          ),
        ),
      ),
    );

    // Provide enough time for the image/placeholder to settle.
    await tester.pumpAndSettle();

    final SemanticsHandle handle = tester.ensureSemantics();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });
}
