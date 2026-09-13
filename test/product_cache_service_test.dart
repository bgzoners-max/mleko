import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/services/catalog/product_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProductModel createDummyProduct(String id) {
    return ProductModel(
      id: id,
      sellerId: 's-1',
      category: 'Mlečni proizvodi',
      name: 'Proizvod $id',
      pricePerKg: 100.0,
      minOrderKg: 1.0,
      orderStep: 1.0,
      availableKg: 10.0,
      unitType: 'kg',
      description: 'Opis $id',
      imageUrls: const [],
      pickupOptions: const ['farm'],
      location: 'Beograd',
      isDomestic: true,
      availableNow: true,
      deliveryMode: ProductDeliveryMode.allSellerPoints,
      selectedDeliveryPointIds: const [],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProductCacheService.clearMemoryCache();
  });

  group('ProductCacheService LRU and Memory Cache', () {
    test('Stores and retrieves items synchronously from memory cache', () async {
      final service = ProductCacheService();
      final p1 = createDummyProduct('p-1');

      await service.cacheProducts('key-1', [p1]);

      final cachedSync = service.getCachedProductsSync('key-1');
      expect(cachedSync, isNotNull);
      expect(cachedSync!.length, equals(1));
      expect(cachedSync.first.id, equals('p-1'));
    });

    test('Enforces 200 items maximum capacity with LRU eviction', () async {
      final service = ProductCacheService();

      // Ubaci tačno 200 stavki
      for (var i = 0; i < 200; i++) {
        await service.cacheProducts('key-$i', [createDummyProduct('p-$i')]);
      }
      expect(ProductCacheService.memoryCacheSize, equals(200));

      // Proveri da je prva ubačena stavka još uvek tu
      expect(service.getCachedProductsSync('key-0'), isNotNull);

      // Sada je key-0 prešao na vrh (MRU), a key-1 je postao najstariji (LRU)!
      // Ubacujemo 201. stavku:
      await service.cacheProducts('key-200', [createDummyProduct('p-200')]);
      expect(ProductCacheService.memoryCacheSize, equals(200));

      // key-1 (najstariji) je izbačen iz memorijskog keša!
      expect(service.getCachedProductsSync('key-1'), isNull);

      // key-0 i key-200 su i dalje u memorijskom kešu!
      expect(service.getCachedProductsSync('key-0'), isNotNull);
      expect(service.getCachedProductsSync('key-200'), isNotNull);
    });

    test('Does not return expired items from memory cache', () async {
      final service = ProductCacheService();
      final p1 = createDummyProduct('p-expired');

      // Keširaj sa negativnim TTL (odmah isteklo)
      await service.cacheProducts(
        'key-expired',
        [p1],
        ttl: const Duration(seconds: -1),
      );

      final cachedSync = service.getCachedProductsSync('key-expired');
      expect(cachedSync, isNull);
    });
  });
}
