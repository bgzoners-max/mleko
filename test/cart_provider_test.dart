import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/services/catalog/products_service.dart';

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

ProductModel _createProduct({
  required String id,
  required String sellerId,
  required String name,
}) {
  return ProductModel(
    id: id,
    sellerId: sellerId,
    category: 'mlecni',
    name: name,
    pricePerKg: 1000,
    unitType: 'kg',
    minOrderKg: 1,
    availableKg: 50,
    description: '',
    imageUrls: const [],
    pickupOptions: const [],
    location: '',
    createdAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CartProvider Race Condition & Persistence Tests', () {
    test('addForSeller immediately after constructor does not get wiped by _load()', () async {
      // Pre-seed storage with existing item for seller A
      final initialData = {
        'seller-1': {'product-1': 2.0}
      };
      SharedPreferences.setMockInitialValues({
        'mleko_seller_drafts': jsonEncode(initialData),
      });

      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);

      // Immediately add a new product for seller-2 or seller-1 without waiting for _load
      final addFuture = provider.addForSeller(
        sellerId: 'seller-2',
        productId: 'product-2',
        quantity: 3.0,
      );

      await addFuture;
      await provider.loadFuture;

      // Both the stored item from seller-1 AND the newly added item from seller-2 must exist!
      expect(provider.getQuantityForSeller('seller-1', 'product-1'), 2.0);
      expect(provider.getQuantityForSeller('seller-2', 'product-2'), 3.0);
      expect(provider.count, 2);

      // Verify that storage also saved both
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('mleko_seller_drafts');
      expect(savedJson, isNotNull);
      final decoded = jsonDecode(savedJson!) as Map<String, dynamic>;
      expect(decoded['seller-1']?['product-1'], 2.0);
      expect(decoded['seller-2']?['product-2'], 3.0);
    });

    test('mutations wait for _initFuture and update correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);

      await provider.addForSeller(sellerId: 's1', productId: 'p1', quantity: 1.5);
      expect(provider.getQuantityForSeller('s1', 'p1'), 1.5);

      await provider.setQuantityForSeller(sellerId: 's1', productId: 'p1', quantity: 4.0);
      expect(provider.getQuantityForSeller('s1', 'p1'), 4.0);

      await provider.removeFromSeller(sellerId: 's1', productId: 'p1');
      expect(provider.containsInSeller('s1', 'p1'), isFalse);
      expect(provider.isEmpty, isTrue);
    });
  });

  group('CartProvider Legacy Format Migration', () {
    test('migrates legacy mleko_cart string and groups items by seller', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_cart': 'p1:2.5;p2:1.0;p3:3.0',
      });

      final service = FakeProductsService();
      // p1 and p2 belong to seller-A, p3 belongs to seller-B
      service.addMockProduct(_createProduct(id: 'p1', sellerId: 'seller-A', name: 'Kravlji sir'));
      service.addMockProduct(_createProduct(id: 'p2', sellerId: 'seller-A', name: 'Mleko'));
      service.addMockProduct(_createProduct(id: 'p3', sellerId: 'seller-B', name: 'Kajmak'));

      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      // Verify in-memory state grouped by seller
      expect(provider.sellerCount, equals(2));
      expect(provider.count, equals(3));
      expect(provider.getQuantityForSeller('seller-A', 'p1'), equals(2.5));
      expect(provider.getQuantityForSeller('seller-A', 'p2'), equals(1.0));
      expect(provider.getQuantityForSeller('seller-B', 'p3'), equals(3.0));

      // Verify persistent storage updated to new JSON format
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('mleko_seller_drafts');
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(decoded['seller-A']?['p1'], equals(2.5));
      expect(decoded['seller-A']?['p2'], equals(1.0));
      expect(decoded['seller-B']?['p3'], equals(3.0));

      // Verify legacy keys were removed
      expect(prefs.getString('mleko_cart'), isNull);
      expect(prefs.getStringList('mleko_cart_ids'), isNull);
    });

    test('migrates legacy mleko_cart_ids list with default 1.0 quantity', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_cart': 'p1:5.0',
        'mleko_cart_ids': ['p1', 'p2'],
      });

      final service = FakeProductsService();
      service.addMockProduct(_createProduct(id: 'p1', sellerId: 'seller-X', name: 'Sir'));
      service.addMockProduct(_createProduct(id: 'p2', sellerId: 'seller-Y', name: 'Jogurt'));

      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      // p1 was already 5.0 in string, so putIfAbsent keeps 5.0; p2 becomes 1.0
      expect(provider.getQuantityForSeller('seller-X', 'p1'), equals(5.0));
      expect(provider.getQuantityForSeller('seller-Y', 'p2'), equals(1.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mleko_cart'), isNull);
      expect(prefs.getStringList('mleko_cart_ids'), isNull);
      expect(prefs.getString('mleko_seller_drafts'), isNotNull);
    });

    test('gracefully ignores deleted/unknown product IDs during migration', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_cart': 'existing:2.0;deleted-product:1.0',
      });

      final service = FakeProductsService();
      service.addMockProduct(_createProduct(id: 'existing', sellerId: 'seller-1', name: 'Puter'));
      // deleted-product is not in mock service

      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      expect(provider.count, equals(1));
      expect(provider.getQuantityForSeller('seller-1', 'existing'), equals(2.0));
      expect(provider.contains('deleted-product'), isFalse);
    });

    test('claimGuestCart sets hasMigratedFromGuest = true and saves user ID when items present', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      await provider.addForSeller(sellerId: 'seller-guest', productId: 'prod-1', quantity: 3.0);
      expect(provider.count, equals(1));
      expect(provider.hasMigratedFromGuest, isFalse);
      expect(provider.currentUserId, isNull);

      await provider.claimGuestCart('user-777');
      expect(provider.hasMigratedFromGuest, isTrue);
      expect(provider.currentUserId, equals('user-777'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mleko_cart_user_id'), equals('user-777'));

      // Dismiss banner
      provider.dismissGuestCartBanner();
      expect(provider.hasMigratedFromGuest, isFalse);
      expect(provider.currentUserId, equals('user-777'));

      // Logout
      await provider.clearForLogout();
      expect(provider.currentUserId, isNull);
      expect(provider.hasMigratedFromGuest, isFalse);
      expect(prefs.getString('mleko_cart_user_id'), isNull);
    });

    test('claimGuestCart does not set hasMigratedFromGuest if cart is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      expect(provider.isEmpty, isTrue);
      await provider.claimGuestCart('user-empty');
      expect(provider.hasMigratedFromGuest, isFalse);
      expect(provider.currentUserId, equals('user-empty'));
    });
  });
}
