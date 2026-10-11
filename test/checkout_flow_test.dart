import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/screens/checkout_screen.dart';
import 'package:mleko/services/services.dart';

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

class _CreateOrderCall {
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final double quantityKg;
  final String unitType;
  final String note;
  final String buyerCity;
  final String buyerPhone;
  final String? buyerAddress;
  final String? buyerPostalCode;
  final DeliveryMethod deliveryMethod;

  _CreateOrderCall({
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.quantityKg,
    required this.unitType,
    required this.note,
    required this.buyerCity,
    required this.buyerPhone,
    this.buyerAddress,
    this.buyerPostalCode,
    required this.deliveryMethod,
  });
}

class _MockOrdersService implements OrdersService {
  final List<_CreateOrderCall> calls = [];
  String nextOrderId = 'order-mock-001';

  @override
  Future<String> createSingleProductOrder({
    required String buyerId,
    required String sellerId,
    required String productId,
    required String productName,
    required double quantityKg,
    required String unitType,
    required String note,
    required String buyerCity,
    required String buyerPhone,
    String? buyerAddress,
    String? buyerPostalCode,
    DeliveryMethod deliveryMethod = DeliveryMethod.courier,
    DeliverySelectionModel? deliverySelection,
    bool preferCall = false,
  }) async {
    calls.add(_CreateOrderCall(
      buyerId: buyerId,
      sellerId: sellerId,
      productId: productId,
      productName: productName,
      quantityKg: quantityKg,
      unitType: unitType,
      note: note,
      buyerCity: buyerCity,
      buyerPhone: buyerPhone,
      buyerAddress: buyerAddress,
      buyerPostalCode: buyerPostalCode,
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
      'adId': adId,
      'updateOrderIdIfPresent': updateOrderIdIfPresent,
    });
    return 'conv-mock-123';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductModel _createTestProduct({
  String id = 'prod-sir-1',
  String sellerId = 'seller-marko',
  String name = 'Domaći Zlatiborski Sir',
  double pricePerKg = 1200,
  double minOrderKg = 1.0,
  double orderStep = 0.5,
  double availableKg = 25.0,
  bool availableNow = true,
}) {
  return ProductModel(
    id: id,
    sellerId: sellerId,
    category: 'Mlečni proizvodi',
    name: name,
    pricePerKg: pricePerKg,
    unitType: ProductModel.unitKg,
    minOrderKg: minOrderKg,
    orderStep: orderStep,
    availableKg: availableKg,
    availableNow: availableNow,
    description: 'Pravi domaći punomasni kravlji sir sa Zlatibora.',
    imageUrls: const [],
    pickupOptions: const ['Lično preuzimanje', 'Dostava'],
    location: 'Zlatibor',
    createdAt: DateTime(2026, 1, 1),
  );
}

class _TestCartProvider extends CartProvider {
  _TestCartProvider({required super.productsService});
  bool removeCalled = false;

  @override
  Future<void> removeFromSeller({required String sellerId, required String productId}) async {
    removeCalled = true;
    return super.removeFromSeller(sellerId: sellerId, productId: productId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Checkout Flow E2E Tests', () {
    late ProductModel testProduct;
    late _MockProductsService mockProductsService;
    late _MockOrdersService mockOrdersService;
    late _MockUsersService mockUsersService;
    late _MockChatService mockChatService;
    late AppState appState;
    late _TestCartProvider cartProvider;

    const testBuyer = UserModel(
      id: 'buyer-nikola',
      email: 'nikola@test.com',
      displayName: 'Nikola Nikolić',
      phone: '0651122334',
      city: 'Beograd',
      address: 'Knez Mihailova 42',
      postalCode: '11000',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      testProduct = _createTestProduct();
      mockProductsService = _MockProductsService({testProduct.id: testProduct});
      mockOrdersService = _MockOrdersService();
      mockUsersService = _MockUsersService();
      mockChatService = _MockChatService();

      final connectivityService = ConnectivityService(initialOnline: true);
      appState = AppState(
        ordersService: mockOrdersService,
        connectivityService: connectivityService,
      );
      appState.setUserForTesting(testBuyer);

      cartProvider = _TestCartProvider(productsService: mockProductsService);
      await cartProvider.loadFuture;
      await cartProvider.setUser(testBuyer.id);
      await cartProvider.addForSeller(
        sellerId: testProduct.sellerId,
        productId: testProduct.id,
        quantity: 1.0,
      );
    });

    Widget createTestApp({required String productId, double? initialQuantity}) {
      final router = GoRouter(
        initialLocation: '/checkout/$productId',
        routes: [
          GoRoute(
            path: '/checkout/:id',
            builder: (context, state) => CheckoutScreen(
              productId: state.pathParameters['id']!,
              initialQuantity: initialQuantity,
            ),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Moje porudžbine - uspešno poslat upit')),
            ),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
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

    testWidgets('Happy-path: fills form, submits order, invokes RPC, chat and navigates to orders',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Render Checkout Screen with pre-filled item
      await tester.pumpWidget(createTestApp(
        productId: testProduct.id,
        initialQuantity: 1.5,
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 2. Verify Product information is displayed
      expect(find.text('Domaći Zlatiborski Sir'), findsOneWidget);
      expect(find.text('Porudžbina'), findsOneWidget);

      // Verify item exists in cart before checkout submission
      expect(cartProvider.containsInSeller(testProduct.sellerId, testProduct.id), isTrue);

      // 3. Edit Quantity to 2.5 kg (valid with step 0.5)
      final quantityFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText?.contains('Količina') == true,
      );
      expect(quantityFinder, findsOneWidget);
      await tester.enterText(quantityFinder, '2.5');
      await tester.pump();

      // 4. Verify buyer contact fields are prefilled from profile
      expect(find.text('0651122334'), findsOneWidget);
      expect(find.text('Beograd'), findsOneWidget);
      expect(find.text('Knez Mihailova 42'), findsOneWidget);
      expect(find.text('11000'), findsOneWidget);

      // 5. Add custom note
      final noteFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText?.contains('Napomena') == true,
      );
      expect(noteFinder, findsOneWidget);
      await tester.enterText(noteFinder, 'Molim vas spakujte u vakuum pakovanja.');
      await tester.pump();

      // 6. Tap submit button
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Pošalji upit prodavcu');
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

      // 7. Verify backend calls and state modifications
      expect(mockOrdersService.calls.length, equals(1));
      final orderCall = mockOrdersService.calls.first;
      expect(orderCall.buyerId, equals('buyer-nikola'));
      expect(orderCall.sellerId, equals('seller-marko'));
      expect(orderCall.productId, equals('prod-sir-1'));
      expect(orderCall.productName, equals('Domaći Zlatiborski Sir'));
      expect(orderCall.quantityKg, equals(2.5));
      expect(orderCall.buyerPhone, equals('0651122334'));
      expect(orderCall.buyerCity, equals('Beograd'));
      expect(orderCall.buyerAddress, equals('Knez Mihailova 42'));
      expect(orderCall.buyerPostalCode, equals('11000'));
      expect(orderCall.note, equals('Molim vas spakujte u vakuum pakovanja.'));
      expect(orderCall.deliveryMethod, equals(DeliveryMethod.courier));

      // 8. Verify chat conversation was created linking order and product
      expect(mockChatService.convCalls.length, equals(1));
      final convCall = mockChatService.convCalls.first;
      expect(convCall['buyerId'], equals('buyer-nikola'));
      expect(convCall['sellerId'], equals('seller-marko'));
      expect(convCall['orderId'], equals('order-mock-001'));
      expect(convCall['productId'], equals('prod-sir-1'));

      // 9. Verify product was removed from cart after successful order
      expect(cartProvider.containsInSeller(testProduct.sellerId, testProduct.id), isFalse);

      // 10. Verify router navigated to orders list screen
      expect(find.text('Moje porudžbine - uspešno poslat upit'), findsOneWidget);
    });

    testWidgets('Validation: prevents order submission if quantity is below minimum',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(
        productId: testProduct.id,
        initialQuantity: 1.0,
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter invalid quantity (0.2 kg when min is 1.0)
      final quantityFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText?.contains('Količina') == true,
      );
      await tester.enterText(quantityFinder, '0.2');
      await tester.pump();

      // Submit
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Pošalji upit prodavcu');
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Validation error shown
      expect(find.textContaining('Minimalna porudžbina:'), findsOneWidget);
      // No order created
      expect(mockOrdersService.calls.isEmpty, isTrue);
      // Product still in cart
      expect(cartProvider.containsInSeller(testProduct.sellerId, testProduct.id), isTrue);
    });

    testWidgets('Validation: prevents submission if required phone number is cleared',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(
        productId: testProduct.id,
        initialQuantity: 1.0,
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Clear phone field
      final phoneFinder = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText?.contains('Kontakt telefon') == true,
      );
      expect(phoneFinder, findsOneWidget);
      await tester.enterText(phoneFinder, '');
      await tester.pump();

      // Submit
      final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Pošalji upit prodavcu');
      await tester.ensureVisible(submitButtonFinder);
      await tester.tap(submitButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Validation error shown
      expect(find.textContaining('kontakt telefon'), findsOneWidget);
      expect(mockOrdersService.calls.isEmpty, isTrue);
    });
  });
}
