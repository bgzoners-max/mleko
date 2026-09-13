import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/utils/image_precache_utils.dart';

void main() {
  testWidgets('warmupProductImages respects preloaded set and limits', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Test')),
      ),
    );

    final context = tester.element(find.text('Test'));
    final preloaded = <String>{'https://example.com/already.jpg'};

    final products = [
      ProductModel(
        id: '1',
        sellerId: 's1',
        category: 'cat',
        name: 'P1',
        pricePerKg: 100,
        minOrderKg: 1,
        availableKg: 10,
        unitType: 'kg',
        description: '',
        imageUrls: [
          'https://example.com/already.jpg',
          'https://example.com/new1.jpg',
        ],
        pickupOptions: [],
        location: 'L',
        isDomestic: true,
        createdAt: DateTime.now(),
      ),
      ProductModel(
        id: '2',
        sellerId: 's2',
        category: 'cat',
        name: 'P2',
        pricePerKg: 200,
        minOrderKg: 1,
        availableKg: 10,
        unitType: 'kg',
        description: '',
        imageUrls: [
          'https://example.com/new2.jpg',
        ],
        pickupOptions: [],
        location: 'L',
        isDomestic: true,
        createdAt: DateTime.now(),
      ),
    ];

    warmupProductImages(
      context: context,
      products: products,
      preloadedUrls: preloaded,
      isMounted: () => true,
      topCountWithSecondary: 2,
      maxTotalUrls: 5,
    );

    // Schedule and run the frame so postFrameCallbacks execute
    tester.binding.scheduleFrame();
    await tester.pump();

    expect(preloaded.contains('https://example.com/already.jpg'), isTrue);
    expect(preloaded.contains('https://example.com/new1.jpg'), isTrue);
    expect(preloaded.contains('https://example.com/new2.jpg'), isTrue);
  });
}
