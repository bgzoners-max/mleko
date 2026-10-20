import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/providers/location_provider.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/navigation/desktop_header.dart';
import 'package:mleko/widgets/navigation/desktop_header_search.dart';

class _FakeProductsService implements ProductsService {
  @override
  Future<ProductModel?> getProduct(String id) async => null;

  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildHeaderTestWidget({
    required double width,
    double height = 900,
  }) {
    final appSettings = AppSettingsProvider();
    final appState = AppState(ordersService: OrdersService());
    final cart = CartProvider(productsService: _FakeProductsService());
    final classifieds = ClassifiedsProvider();
    final location = LocationProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<CartProvider>.value(value: cart),
        ChangeNotifierProvider<ClassifiedsProvider>.value(value: classifieds),
        ChangeNotifierProvider<LocationProvider>.value(value: location),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: DesktopHeader(isStandalone: true),
            ),
          ),
        ),
      ),
    );
  }

  group('DesktopHeaderSearch', () {
    testWidgets('renders input, search icon, clear button, and amber submit button', (tester) async {
      String submitted = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesktopHeaderSearch(
              isDark: false,
              onSearchSubmitted: (q) => submitted = q,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsNWidgets(2)); // prefix icon + submit button icon

      // Type text and submit via Enter
      await tester.enterText(find.byType(TextField), 'domaći sir');
      await tester.pump();
      expect(find.byIcon(Icons.clear), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'domaći sir');

      // Submit via amber search button tap
      submitted = '';
      await tester.tap(find.byTooltip('Pretraži'));
      expect(submitted, 'domaći sir');
    });
  });

  group('DesktopHeader responsive layout tests', () {
    testWidgets('renders cleanly at 1200px without collision between search and cart', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHeaderTestWidget(width: 1200));
      await tester.pumpAndSettle();

      // Brand Logo
      expect(find.text('Domaći Market'), findsOneWidget);

      // Search Bar
      expect(find.byType(DesktopHeaderSearch), findsOneWidget);

      // Cart Action
      final cartFinder = find.byTooltip('Korpa za narudžbine');
      expect(cartFinder, findsOneWidget);

      // Verify the search bar and cart have positive horizontal clearance
      final searchRect = tester.getRect(find.byType(DesktopHeaderSearch));
      final cartRect = tester.getRect(cartFinder);

      expect(searchRect.width, greaterThan(150.0));
      expect(cartRect.left, greaterThan(searchRect.right + 10));

      // Sub-nav tabs
      expect(find.text('Pijaca hrane'), findsOneWidget);
      expect(find.text('Seoska gazdinstva'), findsOneWidget);
      expect(find.text('Mali oglasi'), findsOneWidget);
      expect(find.text('O nama'), findsOneWidget);

      final pijacaX = tester.getTopLeft(find.text('Pijaca hrane')).dx;
      final gazdinstvaX = tester.getTopLeft(find.text('Seoska gazdinstva')).dx;
      final oglasiX = tester.getTopLeft(find.text('Mali oglasi')).dx;
      final oNamaX = tester.getTopLeft(find.text('O nama')).dx;

      expect(pijacaX, lessThan(gazdinstvaX));
      expect(gazdinstvaX, lessThan(oglasiX));
      expect(oglasiX, lessThan(oNamaX));
    });

    testWidgets('renders cleanly at 1366px laptop resolution with spacious search bar', (tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHeaderTestWidget(width: 1366));
      await tester.pumpAndSettle();

      final searchRect = tester.getRect(find.byType(DesktopHeaderSearch));
      final cartRect = tester.getRect(find.byTooltip('Korpa za narudžbine'));

      // At 1366px, search bar has generous width (> 350px)
      expect(searchRect.width, greaterThanOrEqualTo(350.0));
      // Distance between search bar and cart is at least 15px
      expect(cartRect.left - searchRect.right, greaterThanOrEqualTo(15.0));
    });

    testWidgets('renders cleanly at 1920px wide desktop resolution', (tester) async {
      tester.view.physicalSize = const Size(1920, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildHeaderTestWidget(width: 1920));
      await tester.pumpAndSettle();

      final searchRect = tester.getRect(find.byType(DesktopHeaderSearch));
      final cartRect = tester.getRect(find.byTooltip('Korpa za narudžbine'));

      expect(searchRect.width, greaterThanOrEqualTo(350.0));
      expect(cartRect.left, greaterThan(searchRect.right));
      expect(cartRect.left - searchRect.right, greaterThanOrEqualTo(15.0));
    });
  });
}
