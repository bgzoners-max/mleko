import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/home_products_data.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/services/catalog/product_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProduct = ProductModel(
    id: 'p1',
    sellerId: 's1',
    name: 'Domaće Kravlje Mleko',
    description: 'Sveže punomasno mleko',
    pricePerKg: 150.0,
    minOrderKg: 1.0,
    availableKg: 50.0,
    unitType: 'l',
    category: 'Mlečni proizvodi',
    imageUrls: const ['https://example.com/mleko.jpg'],
    pickupOptions: const ['Lično preuzimanje'],
    location: 'Valjevo',
    createdAt: DateTime.now(),
  );

  group('ProductCacheService in-memory sync cache', () {
    test('cacheProducts populates memory cache for immediate sync read', () async {
      final cache = ProductCacheService();
      expect(cache.getCachedProductsSync('test_key'), isNull);

      await cache.cacheProducts('test_key', [sampleProduct]);
      final syncResult = cache.getCachedProductsSync('test_key');
      expect(syncResult, isNotNull);
      expect(syncResult!.length, 1);
      expect(syncResult.first.id, 'p1');

      await cache.clearKey('test_key');
      expect(cache.getCachedProductsSync('test_key'), isNull);
    });
  });

  group('Stream.multi replay behavior for new subscribers', () {
    test('new subscriber receives latest emitted data immediately', () async {
      final controller = StreamController<HomeProductsData>.broadcast();
      HomeProductsData? lastEmitted;

      Stream<HomeProductsData> createStream() {
        return Stream.multi((multiController) {
          if (lastEmitted != null) {
            multiController.add(lastEmitted);
          }
          final sub = controller.stream.listen(
            multiController.add,
            onError: multiController.addError,
            onDone: multiController.close,
          );
          multiController.onCancel = () => sub.cancel();
        }, isBroadcast: true);
      }

      final stream = createStream();

      // Emit an event before subscriber 2 connects
      final HomeProductsData data1 = (
        products: <ProductModel>[sampleProduct],
        salesCounts: <String, int>{'p1': 5},
        ratings: <String, ({double avg, int count})>{'p1': (avg: 4.8, count: 10)},
      );
      lastEmitted = data1;
      controller.add(data1);

      // Subscriber 2 subscribes after emission
      final completer = Completer<HomeProductsData>();
      final sub2 = stream.listen((data) {
        if (!completer.isCompleted) completer.complete(data);
      });

      final received = await completer.future.timeout(const Duration(seconds: 1));
      expect(received.products.length, 1);
      expect(received.products.first.id, 'p1');
      await sub2.cancel();
      await controller.close();
    });
  });

  group('StreamBuilder waiting state with initialData', () {
    testWidgets('StreamBuilder with initialData does not enter waiting-without-data branch', (tester) async {
      final controller = StreamController<HomeProductsData>.broadcast();
      final HomeProductsData initialData = (
        products: <ProductModel>[sampleProduct],
        salesCounts: <String, int>{},
        ratings: <String, ({double avg, int count})>{},
      );

      bool renderedSkeletons = false;
      bool renderedProducts = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamBuilder<HomeProductsData>(
              initialData: initialData,
              stream: controller.stream,
              builder: (context, snap) {
                // The fix: snap.connectionState == ConnectionState.waiting && !snap.hasData
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  renderedSkeletons = true;
                  return const Text('SKELETON_LOADING');
                }
                renderedProducts = true;
                return Text('PRODUCT: ${snap.data?.products.first.name}');
              },
            ),
          ),
        ),
      );

      expect(renderedSkeletons, isFalse);
      expect(renderedProducts, isTrue);
      expect(find.text('PRODUCT: Domaće Kravlje Mleko'), findsOneWidget);
      expect(find.text('SKELETON_LOADING'), findsNothing);

      await controller.close();
    });
  });
}
