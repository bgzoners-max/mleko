import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/product_reviews_data.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/product/product_cart_block.dart';
import 'package:mleko/widgets/product/product_info_section.dart';
import 'package:mleko/widgets/product/seller_chat_button.dart';

class _FakeProductsService extends Fake implements ProductsService {
  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async =>
      {};
}

class _FakeUsersService extends Fake implements UsersService {
  @override
  Future<UserModel?> getUser(String id) async => null;
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

Widget _wrapWithProviders({
  required AppState appState,
  required CartProvider cartProvider,
  required Widget child,
  double width = 360,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider<AppSettingsProvider>(
        create: (_) => AppSettingsProvider(),
      ),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      Provider<UsersService>(create: (_) => _FakeUsersService()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders Pošalji poruku OutlinedButton on mobile inside ProductCartBlock',
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
      _wrapWithProviders(
        appState: appState,
        cartProvider: cartProvider,
        width: 360,
        child: ProductCartBlock(product: _sampleProduct(sellerId: 'seller-1')),
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

  testWidgets('omits Pošalji poruku inside ProductCartBlock in desktopMode',
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
      _wrapWithProviders(
        appState: appState,
        cartProvider: cartProvider,
        width: 600,
        child: ProductCartBlock(
          product: _sampleProduct(sellerId: 'seller-1'),
          desktopMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Pošalji poruku'), findsNothing);
  });

  testWidgets(
      'renders Pošalji poruku next to Podeli on desktop ProductInfoSection',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
      _wrapWithProviders(
        appState: appState,
        cartProvider: cartProvider,
        width: 620,
        child: ProductInfoSection(
          product: _sampleProduct(sellerId: 'seller-1'),
          reviewsFuture: Future.value(
            const ProductReviewsData(averageRating: null, reviews: []),
          ),
          onScrollToReviews: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shareFinder = find.widgetWithText(OutlinedButton, 'Podeli');
    final chatFinder = find.widgetWithText(OutlinedButton, 'Pošalji poruku');
    expect(shareFinder, findsOneWidget);
    expect(chatFinder, findsOneWidget);

    final shareRect = tester.getRect(shareFinder);
    final chatRect = tester.getRect(chatFinder);
    expect(chatRect.left, greaterThan(shareRect.right));
    expect((chatRect.center.dy - shareRect.center.dy).abs(), lessThan(4));
  });

  testWidgets('hides SellerChatButton when user owns the product',
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
      _wrapWithProviders(
        appState: appState,
        cartProvider: cartProvider,
        child: const SellerChatButton(
          productId: 'prod-1',
          sellerId: 'seller-1',
          isDesktop: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pošalji poruku'), findsNothing);
  });
}
