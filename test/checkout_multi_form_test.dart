import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/checkout/checkout_multi_form.dart';

// ── Mock Services ────────────────────────────────────────────────────────────

class _MockProductsService implements ProductsService {
  final Map<String, ProductModel> products;
  _MockProductsService(this.products);

  @override
  Future<ProductModel?> getProduct(String id) async => products[id];

  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async {
    final result = <String, ProductModel>{};
    for (final id in ids) {
      if (products.containsKey(id)) {
        result[id] = products[id]!;
      }
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MultiOrderCall {
  final String buyerId;
  final String sellerId;
  final int itemCount;
  final List<String> productIds;
  final List<double> quantities;
  final String buyerPhone;
  final String buyerCity;
  final DeliveryMethod deliveryMethod;

  _MultiOrderCall({
    required this.buyerId,
    required this.sellerId,
    required this.itemCount,
    required this.productIds,
    required this.quantities,
    required this.buyerPhone,
    required this.buyerCity,
    required this.deliveryMethod,
  });
}

class _MockOrdersService implements OrdersService {
  final List<_MultiOrderCall> calls = [];
  String nextOrderId = 'order-multi-mock-001';

  @override
  Future<String> createOrderWithItems({
    required String buyerId,
    required String sellerId,
    required List<dynamic> items,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.agreement,
    DeliverySelectionModel? deliverySelection,
  }) async {
    calls.add(_MultiOrderCall(
      buyerId: buyerId,
      sellerId: sellerId,
      itemCount: items.length,
      productIds: items.map((e) => e.productId as String).toList(),
      quantities: items.map((e) => e.quantityKg as double).toList(),
      buyerPhone: buyerPhone,
      buyerCity: buyerCity,
      deliveryMethod: deliveryMethod,
    ));
    return nextOrderId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockUsersService implements UsersService {
  final List<Map<String, dynamic>> upsertCalls = [];

  @override
  Future<void> upsertProfile(
    String userId, {
    String? email,
    Object? displayName,
    Object? phone,
    Object? city,
    Object? postalCode,
    Object? address,
    String? role,
    bool? isGuest,
    Object? farmName,
    Object? location,
    Object? profileImageUrl,
    double? lat,
    double? lng,
    bool? phonePublic,
    Object? sellerStory,
    List<String>? farmGalleryUrls,
    List<String>? sellerTags,
    List<String>? sellerQuickReplies,
    Object? legalType,
    Object? bpg,
    Object? pib,
    DateTime? legalLiabilityAcceptedAt,
  }) async {
    upsertCalls.add({
      'userId': userId,
      'phone': phone,
      'postalCode': postalCode,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockChatService implements ChatService {
  final List<Map<String, dynamic>> convCalls = [];

  @override
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) async {
    convCalls.add({
      'buyerId': buyerId,
      'sellerId': sellerId,
      'orderId': orderId,
      'productId': productId,
    });
    return 'conv-multi-mock-123';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testSellerId = 'seller-milos';
const _testBuyer = UserModel(
  id: 'buyer-nikola',
  email: 'nikola@test.com',
  displayName: 'Nikola Nikolić',
  phone: '0651122334',
  city: 'Beograd',
  address: 'Knez Mihailova 42',
  postalCode: '11000',
);

ProductModel _createProduct({
  required String id,
  required String name,
  double pricePerKg = 1200,
  double minOrderKg = 1.0,
  double orderStep = 0.5,
  bool availableNow = true,
}) {
  return ProductModel(
    id: id,
    sellerId: _testSellerId,
    category: 'Mlečni proizvodi',
    name: name,
    pricePerKg: pricePerKg,
    unitType: ProductModel.unitKg,
    minOrderKg: minOrderKg,
    orderStep: orderStep,
    availableKg: 25.0,
    availableNow: availableNow,
    description: 'Testni proizvod.',
    imageUrls: const [],
    pickupOptions: const ['Lično preuzimanje', 'Dostava'],
    location: 'Valjevo',
    createdAt: DateTime(2026, 1, 1),
  );
}

/// In-memory zamena za FlutterSecureStorage MethodChannel.
///
/// `OrderQueueService` čita/piše red porudžbina kroz `flutter_secure_storage`,
/// čiji MethodChannel pozivi u FakeAsync widget testovima visi zauvek
/// (niko ne odgovara na platformsku poruku). Ovim mock-om se
/// read/write ponašaju kao običan keš u memoriji.
final Map<String, String> _secureStorageValues = {};

void _mockSecureStorageChannel() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    final args = (call.arguments as Map<dynamic, dynamic>?) ?? const {};
    switch (call.method) {
      case 'read':
        return _secureStorageValues[args['key'] as String?];
      case 'write':
        final key = args['key'] as String?;
        final value = args['value'] as String?;
        if (key != null && value != null) _secureStorageValues[key] = value;
        return null;
      case 'delete':
      case 'remove':
        _secureStorageValues.remove(args['key'] as String?);
        return null;
      case 'containsKey':
        return _secureStorageValues.containsKey(args['key']);
      case 'readAll':
        return _secureStorageValues;
      case 'deleteAll':
        _secureStorageValues.clear();
        return null;
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckoutMultiForm E2E Tests', () {
    late ProductModel sirProduct;
    late ProductModel medProduct;
    late _MockProductsService mockProductsService;
    late _MockOrdersService mockOrdersService;
    late _MockUsersService mockUsersService;
    late _MockChatService mockChatService;
    late AppState appState;
    late CartProvider cartProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      _secureStorageValues.clear();
      _mockSecureStorageChannel();
      sirProduct = _createProduct(id: 'prod-sir', name: 'Domaći Sir');
      medProduct = _createProduct(
        id: 'prod-med',
        name: 'Livadski Med',
        pricePerKg: 1000,
        minOrderKg: 0.5,
      );
      mockProductsService = _MockProductsService({
        sirProduct.id: sirProduct,
        medProduct.id: medProduct,
      });
      mockOrdersService = _MockOrdersService();
      mockUsersService = _MockUsersService();
      mockChatService = _MockChatService();

      final connectivityService = ConnectivityService(initialOnline: true);
      appState = AppState(
        ordersService: mockOrdersService,
        connectivityService: connectivityService,
      )..setUserForTesting(_testBuyer);

      cartProvider = CartProvider(productsService: mockProductsService);
      await cartProvider.loadFuture;
      await cartProvider.setUser(_testBuyer.id);
      await cartProvider.addForSeller(
        sellerId: _testSellerId,
        productId: sirProduct.id,
        quantity: 2.0,
      );
      await cartProvider.addForSeller(
        sellerId: _testSellerId,
        productId: medProduct.id,
        quantity: 1.0,
      );
    });

    Widget createTestApp({
      required List<({ProductModel product, double quantity})> items,
      bool online = true,
    }) {
      final connectivityService = ConnectivityService(initialOnline: online);
      final localAppState = online
          ? appState
          : AppState(
              ordersService: mockOrdersService,
              connectivityService: connectivityService,
            )..setUserForTesting(_testBuyer);

      final router = GoRouter(
        initialLocation: '/checkout-multi',
        routes: [
          GoRoute(
            path: '/checkout-multi',
            builder: (context, state) => Scaffold(
              body: CheckoutMultiForm(
                sellerId: _testSellerId,
                sellerName: 'Miloševo gazdinstvo',
                items: items,
              ),
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Moje porudžbine - uspešno poslat upit')),
            ),
          ),
          GoRoute(
            path: '/seller/:id',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Prodavac placeholder')),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Početna placeholder')),
            ),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: localAppState),
          ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
          Provider<ProductsService>.value(value: mockProductsService),
          Provider<OrdersService>.value(value: mockOrdersService),
          Provider<UsersService>.value(value: mockUsersService),
          Provider<ChatService>.value(value: mockChatService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    List<({ProductModel product, double quantity})> validItems() => [
          (product: sirProduct, quantity: 2.0),
          (product: medProduct, quantity: 1.0),
        ];

    testWidgets(
        'Happy-path: multi-item order submits via createOrderWithItems, opens chat, clears cart and navigates',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(items: validItems()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Both items from the seller group are displayed
      expect(find.text('Domaći Sir'), findsWidgets);
      expect(find.text('Livadski Med'), findsWidgets);
      expect(find.text('Porudžbina kod: Miloševo gazdinstvo'), findsOneWidget);

      // 2. Total amount: 2 * 1200 + 1 * 1000 = 3400 RSD
      expect(find.text('3400 RSD'), findsOneWidget);

      // 3. Buyer contact fields prefilled from profile
      expect(find.text('0651122334'), findsOneWidget);
      expect(find.text('Beograd'), findsOneWidget);

      // 4. Cart contains both items before submission
      expect(cartProvider.count, 2);

      // 5. Submit
      final submitButtonFinder =
          find.widgetWithText(FilledButton, 'Pošalji porudžbinu');
      expect(submitButtonFinder, findsOneWidget);
      await tester.ensureVisible(submitButtonFinder);
      await tester.pump();

      await tester.tap(submitButtonFinder);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Exactly one order RPC call containing BOTH items
      expect(mockOrdersService.calls.length, equals(1));
      final orderCall = mockOrdersService.calls.first;
      expect(orderCall.buyerId, equals('buyer-nikola'));
      expect(orderCall.sellerId, equals(_testSellerId));
      expect(orderCall.itemCount, equals(2));
      expect(orderCall.productIds, equals(['prod-sir', 'prod-med']));
      expect(orderCall.quantities, equals([2.0, 1.0]));
      expect(orderCall.buyerPhone, equals('0651122334'));
      expect(orderCall.buyerCity, equals('Beograd'));
      expect(orderCall.deliveryMethod, equals(DeliveryMethod.courier));

      // 7. Chat conversation created linking order and first product
      expect(mockChatService.convCalls.length, equals(1));
      final convCall = mockChatService.convCalls.first;
      expect(convCall['buyerId'], equals('buyer-nikola'));
      expect(convCall['sellerId'], equals(_testSellerId));
      expect(convCall['orderId'], equals('order-multi-mock-001'));
      expect(convCall['productId'], equals('prod-sir'));

      // 8. Seller cart group fully cleared after successful order
      expect(
          cartProvider.containsInSeller(_testSellerId, 'prod-sir'), isFalse);
      expect(
          cartProvider.containsInSeller(_testSellerId, 'prod-med'), isFalse);

      // 9. Navigated to orders screen
      expect(
          find.text('Moje porudžbine - uspešno poslat upit'), findsOneWidget);
    });

    testWidgets(
        'Validation: prevents submission if required phone is cleared',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(items: validItems()));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final phoneFinder = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText?.contains('Kontakt telefon') == true,
      );
      expect(phoneFinder, findsOneWidget);
      await tester.enterText(phoneFinder, '');
      await tester.pump();

      final submitButtonFinder =
          find.widgetWithText(FilledButton, 'Pošalji porudžbinu');
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Validation error shown, no order created, cart untouched
      expect(find.textContaining('kontakt telefon'), findsOneWidget);
      expect(mockOrdersService.calls.isEmpty, isTrue);
      expect(cartProvider.count, 2);
    });

    testWidgets(
        'Validation: rejects quantity below product minimum at submission time',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Item injected directly with quantity below the product minimum
      // (bypasses cart-side validation and must be caught at submit time).
      final badItems = [
        (product: sirProduct, quantity: 0.4),
        (product: medProduct, quantity: 1.0),
      ];

      await tester.pumpWidget(createTestApp(items: badItems));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final submitButtonFinder =
          find.widgetWithText(FilledButton, 'Pošalji porudžbinu');
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Domaći Sir: minimalno'), findsOneWidget);
      expect(mockOrdersService.calls.isEmpty, isTrue);
    });

    testWidgets('Unavailable product disables submit and shows Nedostupno',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final unavailable = _createProduct(
          id: 'prod-stari', name: 'Stari Sir', availableNow: false);
      final itemsWithUnavailable = [
        (product: sirProduct, quantity: 2.0),
        (product: unavailable, quantity: 1.0),
      ];

      await tester.pumpWidget(createTestApp(items: itemsWithUnavailable));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Submit button is disabled and labelled accordingly
      expect(find.text('Nedostupno'), findsOneWidget);
      final disabledButton = tester.widget<FilledButton>(
        find
            .ancestor(
              of: find.text('Nedostupno'),
              matching: find.byType(FilledButton),
            )
            .first,
      );
      expect(disabledButton.onPressed, isNull);

      // No order may be created while an item is unavailable
      expect(mockOrdersService.calls.isEmpty, isTrue);
    });

    testWidgets(
        'Offline: order is queued locally, snackbar shown, cart cleared and navigated',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
          createTestApp(items: validItems(), online: false));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final submitButtonFinder =
          find.widgetWithText(FilledButton, 'Pošalji porudžbinu');
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // No online order call was made
      expect(mockOrdersService.calls.isEmpty, isTrue);

      // One pending order per item was queued locally
      final pending = await appState.orderQueue.getPendingOrders();
      expect(pending.length, equals(2));
      expect(
        pending.map((e) => e.productId).toSet(),
        equals({'prod-sir', 'prod-med'}),
      );
      expect(pending.first.sellerId, equals(_testSellerId));

      // Offline confirmation snackbar is visible
      expect(find.textContaining('sačuvana offline'), findsOneWidget);

      // Cart cleared and navigation happened
      expect(cartProvider.count, 0);
      expect(
          find.text('Moje porudžbine - uspešno poslat upit'), findsOneWidget);
    });
  });
}
