import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mleko/models/app_error.dart';
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
      await provider.flush();

      // Both the stored item from seller-1 AND the newly added item from seller-2 must exist!
      expect(provider.getQuantityForSeller('seller-1', 'product-1'), 2.0);
      expect(provider.getQuantityForSeller('seller-2', 'product-2'), 3.0);
      expect(provider.count, 2);

      // Verify that storage also saved both under namespaced key
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(CartProvider.storageKeyFor(null));
      expect(savedJson, isNotNull);
      final decoded = jsonDecode(savedJson!) as Map<String, dynamic>;
      expect(decoded['seller-1']?['product-1'], 2.0);
      expect(decoded['seller-2']?['product-2'], 3.0);
    });

    test('mutations are non-blocking write-behind and flush writes to storage', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);

      // Mutation is instant
      await provider.addForSeller(sellerId: 's1', productId: 'p1', quantity: 2.0);
      expect(provider.getQuantityForSeller('s1', 'p1'), 2.0);

      // Before flush, memory has it; flush persists it
      await provider.flush();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(CartProvider.storageKeyFor(null));
      expect(saved, contains('p1'));

      provider.dispose();
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

      // p1 and p2 belong to seller-A, p3 belongs to seller-B
      final service = FakeProductsService()
        ..addMockProduct(_createProduct(id: 'p1', sellerId: 'seller-A', name: 'Kravlji sir'))
        ..addMockProduct(_createProduct(id: 'p2', sellerId: 'seller-A', name: 'Mleko'))
        ..addMockProduct(_createProduct(id: 'p3', sellerId: 'seller-B', name: 'Kajmak'));

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
      final storedJson = prefs.getString(CartProvider.storageKeyFor(null));
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

      final service = FakeProductsService()
        ..addMockProduct(_createProduct(id: 'p1', sellerId: 'seller-X', name: 'Sir'))
        ..addMockProduct(_createProduct(id: 'p2', sellerId: 'seller-Y', name: 'Jogurt'));

      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      // p1 was already 5.0 in string, so putIfAbsent keeps 5.0; p2 becomes 1.0
      expect(provider.getQuantityForSeller('seller-X', 'p1'), equals(5.0));
      expect(provider.getQuantityForSeller('seller-Y', 'p2'), equals(1.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mleko_cart'), isNull);
      expect(prefs.getStringList('mleko_cart_ids'), isNull);
      expect(prefs.getString(CartProvider.storageKeyFor(null)), isNotNull);
    });

    test('gracefully ignores deleted/unknown product IDs during migration', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_cart': 'existing:2.0;deleted-product:1.0',
      });

      final service = FakeProductsService()
        ..addMockProduct(_createProduct(id: 'existing', sellerId: 'seller-1', name: 'Puter'));
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
      expect(provider.isEmpty, isTrue);
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

    test('Cart does NOT leak to a new user after logout', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      // Korisnik A se prijavi i doda artikle
      await provider.setUser('user-A');
      await provider.addForSeller(sellerId: 's1', productId: 'p1', quantity: 2.0);
      expect(provider.count, 1);
      expect(provider.currentUserId, 'user-A');

      // Korisnik A se odjavi
      await provider.clearForLogout();
      expect(provider.isEmpty, isTrue);
      expect(provider.currentUserId, isNull);

      // Korisnik B se prijavi na istom uređaju
      await provider.setUser('user-B');
      // Korpa korisnika B MORA biti prazna, a ne nasleđena od Korisnika A!
      expect(provider.isEmpty, isTrue);
      expect(provider.count, 0);
      expect(provider.hasMigratedFromGuest, isFalse);

      // Korisnik B doda svoj artikal
      await provider.addForSeller(sellerId: 's2', productId: 'p2', quantity: 5.0);
      expect(provider.count, 1);

      // Korisnik B se odjavi, a Korisnik A se ponovo prijavi
      await provider.clearForLogout();
      expect(provider.isEmpty, isTrue);

      await provider.setUser('user-A');
      // Korpa Korisnika A je sačuvana i ponovo učitana!
      expect(provider.count, 1);
      expect(provider.getQuantityForSeller('s1', 'p1'), 2.0);
      expect(provider.containsInSeller('s2', 'p2'), isFalse);
    });

    test('Guest cart is claimed by logging-in user, but does not overwrite other user carts', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final provider = CartProvider(productsService: service);
      await provider.loadFuture;

      // Gost doda artikal
      await provider.addForSeller(sellerId: 's-guest', productId: 'p-guest', quantity: 1.0);
      expect(provider.count, 1);
      expect(provider.currentUserId, isNull);

      // Gost se prijavi kao User-C
      await provider.setUser('user-C');
      expect(provider.count, 1);
      expect(provider.getQuantityForSeller('s-guest', 'p-guest'), 1.0);
      expect(provider.hasMigratedFromGuest, isTrue);

      // Logout
      await provider.clearForLogout();
      expect(provider.isEmpty, isTrue);

      // Gostujući ključ u storage-u je očišćen
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(CartProvider.storageKeyFor(null)), isNull);
    });
  });

  group('CartProvider QuantityEngine Validation & Normalization Tests', () {
    late FakeProductsService service;
    late ProductModel cheese;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FakeProductsService();
      cheese = ProductModel(
        id: 'p-cheese',
        sellerId: 's-farm',
        category: 'mlečni',
        name: 'Domaći sir',
        pricePerKg: 800,
        unitType: ProductModel.unitKg,
        minOrderKg: 0.5,
        orderStep: 0.5,
        availableKg: 20,
        availableNow: true,
        description: 'Sir',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Ub',
        createdAt: DateTime(2026, 1, 1),
      );
      service.addMockProduct(cheese);
    });

    test('addForSeller with valid quantity succeeds and normalizes', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      await cart.addForSeller(
        sellerId: 's-farm',
        productId: 'p-cheese',
        quantity: 0.5,
      );
      expect(cart.getQuantityForSeller('s-farm', 'p-cheese'), 0.5);

      await cart.addForSeller(
        sellerId: 's-farm',
        productId: 'p-cheese',
        quantity: 0.5,
      );
      expect(cart.getQuantityForSeller('s-farm', 'p-cheese'), 1.0);
    });

    test('addForSeller with invalid non-step quantity (e.g. 1.37 kg) throws AppError validation', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      expect(
        () => cart.addForSeller(
          sellerId: 's-farm',
          productId: 'p-cheese',
          quantity: 1.37,
        ),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
      expect(cart.containsInSeller('s-farm', 'p-cheese'), isFalse);
    });

    test('addForSeller below minOrderKg throws AppError validation', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      expect(
        () => cart.addForSeller(
          sellerId: 's-farm',
          productId: 'p-cheese',
          quantity: 0.2, // minOrder is 0.5
        ),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
    });

    test('setQuantityForSeller validates and normalizes', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      await cart.setQuantityForSeller(
        sellerId: 's-farm',
        productId: 'p-cheese',
        quantity: 2.5,
      );
      expect(cart.getQuantityForSeller('s-farm', 'p-cheese'), 2.5);

      // Invalid non-step quantity rejected
      expect(
        () => cart.setQuantityForSeller(
          sellerId: 's-farm',
          productId: 'p-cheese',
          quantity: 1.37,
        ),
        throwsA(isA<AppError>().having((e) => e.type, 'type', ErrorType.validation)),
      );
      // Value in cart remains unchanged
      expect(cart.getQuantityForSeller('s-farm', 'p-cheese'), 2.5);
    });

    test('setQuantityForSeller handles floating-point inexact steps cleanly', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      // 0.5 + 0.5000000000000001 (IEEE floating point artifact) normalizes cleanly
      await cart.setQuantityForSeller(
        sellerId: 's-farm',
        productId: 'p-cheese',
        quantity: 1.0000000000000002,
      );
      expect(cart.getQuantityForSeller('s-farm', 'p-cheese'), 1.0);
    });
  });

  group('CartProvider User Isolation, Merging & Debounce Flush', () {
    late FakeProductsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = FakeProductsService()
        ..addMockProduct(_createProduct(id: 'p-1', sellerId: 's-1', name: 'Mleko'))
        ..addMockProduct(_createProduct(id: 'p-2', sellerId: 's-2', name: 'Sir'));
    });

    test('switching between User A and User B preserves isolation without cross-contamination', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      // User A adds p-1
      await cart.setUser('user-A');
      await cart.addForSeller(sellerId: 's-1', productId: 'p-1', quantity: 2.0);
      await cart.flush();

      expect(cart.getQuantityForSeller('s-1', 'p-1'), 2.0);
      expect(cart.count, 1);

      // Switch to User B (cart should be empty initially for User B)
      await cart.setUser('user-B');
      expect(cart.getQuantityForSeller('s-1', 'p-1'), isNull);
      expect(cart.isEmpty, isTrue);

      // User B adds p-2
      await cart.addForSeller(sellerId: 's-2', productId: 'p-2', quantity: 1.0);
      await cart.flush();
      expect(cart.getQuantityForSeller('s-2', 'p-2'), 1.0);
      expect(cart.count, 1);

      // Switch back to User A (cart should restore User A items only)
      await cart.setUser('user-A');
      expect(cart.getQuantityForSeller('s-1', 'p-1'), 2.0);
      expect(cart.getQuantityForSeller('s-2', 'p-2'), isNull);
      expect(cart.count, 1);
    });

    test('guest items are merged with existing user items upon login', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      // 1. User X already has p-1 in their account
      await cart.setUser('user-X');
      await cart.addForSeller(sellerId: 's-1', productId: 'p-1', quantity: 1.0);
      await cart.flush();

      // 2. User logs out -> becomes guest
      await cart.setUser(null);
      expect(cart.isEmpty, isTrue);

      // 3. Guest adds p-2
      await cart.addForSeller(sellerId: 's-2', productId: 'p-2', quantity: 3.0);
      expect(cart.count, 1);

      // 4. Guest logs in as User X
      await cart.setUser('user-X');

      // Both p-1 (from existing user cart) and p-2 (from guest session) must exist!
      expect(cart.getQuantityForSeller('s-1', 'p-1'), 1.0);
      expect(cart.getQuantityForSeller('s-2', 'p-2'), 3.0);
      expect(cart.count, 2);
      expect(cart.hasMigratedFromGuest, isTrue);

      // Storage under guest key must be wiped
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(CartProvider.storageKeyFor(null)), isFalse);
    });

    test('flush forces pending debounce save to storage immediately', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      await cart.setUser('user-debounce');
      await cart.addForSeller(sellerId: 's-1', productId: 'p-1', quantity: 2.0);

      // Call flush to commit pending write
      await cart.flush();

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(CartProvider.storageKeyFor('user-debounce'));
      expect(saved, isNotNull);
      expect(saved, contains('p-1'));

      cart.dispose();
    });

    test('addForSeller with injected ProductModel and cache invalidation', () async {
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      final product = (await service.getProduct('p-1'))!;
      await cart.addForSeller(
        sellerId: product.sellerId,
        productId: product.id,
        quantity: 1.0,
        product: product,
      );

      expect(cart.getQuantityForSeller('s-1', 'p-1'), 1.0);

      final items = await cart.getProductsBySeller('s-1');
      expect(items.length, 1);
      expect(items.first.product.id, 'p-1');

      // Invalidate cache and force refresh
      cart.invalidateProductsCache('s-1');
      final refreshedItems = await cart.getProductsBySeller('s-1', forceRefresh: true);
      expect(refreshedItems.length, 1);

      cart.dispose();
    });

    test('reload re-reads cart from SharedPreferences after in-memory change', () async {
      SharedPreferences.setMockInitialValues({
        CartProvider.storageKeyFor('user-reload'): jsonEncode({'s-1': {'p-1': 2.0}}),
      });
      final service = FakeProductsService();
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;
      await cart.setUser('user-reload');

      // Verify loaded state
      expect(cart.getQuantityForSeller('s-1', 'p-1'), 2.0);
      expect(cart.count, 1);

      // Change in memory without persisting
      await cart.addForSeller(sellerId: 's-2', productId: 'p-2', quantity: 5.0);
      expect(cart.getQuantityForSeller('s-2', 'p-2'), 5.0);
      expect(cart.count, 2);

      // reload() should discard in-memory changes and re-read from storage
      await cart.reload();
      expect(cart.getQuantityForSeller('s-1', 'p-1'), 2.0);
      expect(cart.getQuantityForSeller('s-2', 'p-2'), isNull);
      expect(cart.count, 1);

      cart.dispose();
    });

    test('clearForLogout clears cart and resets user', () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeProductsService();
      final cart = CartProvider(productsService: service);
      await cart.loadFuture;

      await cart.setUser('user-logout');
      await cart.addForSeller(sellerId: 's-1', productId: 'p-1', quantity: 2.0);
      await cart.flush();

      expect(cart.currentUserId, 'user-logout');
      expect(cart.count, 1);

      await cart.clearForLogout();

      expect(cart.currentUserId, isNull);
      expect(cart.isEmpty, isTrue);
      expect(cart.count, 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('mleko_cart_user_id'), isNull);

      cart.dispose();
    });
  });
}
