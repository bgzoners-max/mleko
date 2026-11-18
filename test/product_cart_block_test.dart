import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/widgets/product/product_cart_block.dart';

class _FakeProductsService extends Fake implements ProductsService {
  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async =>
      {};
}

class _FakeAppState extends ChangeNotifier implements AppState {
  @override
  UserModel? user;

  _FakeAppState({this.user});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductModel _sampleProduct({String sellerId = 'seller-1'}) => ProductModel(
      id: 'prod-1',
      sellerId: sellerId,
      category: 'rakija',
      name: 'Domaća rakija',
      pricePerKg: 800,
      unitType: 'L',
      minOrderKg: 1,
      availableKg: 20,
      description: 'Odležala u hrastovim buradima',
      imageUrls: const [],
      pickupOptions: const ['Lično', 'Kurir'],
      location: 'Aleksandrovac',
      createdAt: DateTime(2026, 1, 2),
    );

Widget _wrapBlock({
  required AppState appState,
  required CartProvider cartProvider,
  required ProductModel product,
  bool desktopMode = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider<AppSettingsProvider>(
        create: (_) => AppSettingsProvider(),
      ),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: desktopMode ? 600 : 360,
          child: ProductCartBlock(
            product: product,
            desktopMode: desktopMode,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders Pošalji poruku OutlinedButton on mobile for buyer',
      (tester) async {
    final appState = _FakeAppState(
      user: const UserModel(
        id: 'buyer-1',
        role: UserRole.buyer,
        displayName: 'Kupac',
        phone: '+38160111222',
        city: 'Beograd',
      ),
    );
    final cartProvider = CartProvider(productsService: _FakeProductsService());

    await tester.pumpWidget(
      _wrapBlock(
        appState: appState,
        cartProvider: cartProvider,
        product: _sampleProduct(sellerId: 'seller-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imaš pitanje? Pošalji poruku prodavcu'), findsNothing);
    final buttonFinder = find.widgetWithText(OutlinedButton, 'Pošalji poruku');
    expect(buttonFinder, findsOneWidget);

    final size = tester.getSize(buttonFinder);
    expect(size.height, 46);
    expect(size.width, 360);
  });

  testWidgets('renders Pošalji poruku OutlinedButton with minWidth on desktop',
      (tester) async {
    final appState = _FakeAppState(
      user: const UserModel(
        id: 'buyer-1',
        role: UserRole.buyer,
        displayName: 'Kupac',
        phone: '+38160111222',
        city: 'Beograd',
      ),
    );
    final cartProvider = CartProvider(productsService: _FakeProductsService());

    await tester.pumpWidget(
      _wrapBlock(
        appState: appState,
        cartProvider: cartProvider,
        product: _sampleProduct(sellerId: 'seller-1'),
        desktopMode: true,
      ),
    );
    await tester.pumpAndSettle();

    final buttonFinder = find.widgetWithText(OutlinedButton, 'Pošalji poruku');
    expect(buttonFinder, findsOneWidget);

    final size = tester.getSize(buttonFinder);
    expect(size.height, 46);
    expect(size.width, greaterThanOrEqualTo(220));
  });

  testWidgets('hides Pošalji poruku button when user owns the product',
      (tester) async {
    final appState = _FakeAppState(
      user: const UserModel(
        id: 'seller-1',
        role: UserRole.seller,
        displayName: 'Prodavac',
        phone: '+38160999888',
        city: 'Aleksandrovac',
      ),
    );
    final cartProvider = CartProvider(productsService: _FakeProductsService());

    await tester.pumpWidget(
      _wrapBlock(
        appState: appState,
        cartProvider: cartProvider,
        product: _sampleProduct(sellerId: 'seller-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pošalji poruku'), findsNothing);
  });
}
