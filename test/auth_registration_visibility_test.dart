import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/cart_provider.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/providers/location_provider.dart';
import 'package:mleko/screens/auth/login_screen.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/catalog/products_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/home/home_mobile_app_bar.dart';
import 'package:mleko/widgets/navigation/desktop_header.dart';
import 'package:mleko/widgets/navigation/main_shell.dart';
import 'package:mleko/widgets/profile/profile_guest_prompt.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentSupabaseUser => null;
}

class _FakeProductsService implements ProductsService {
  @override
  Future<ProductModel?> getProduct(String id) async => null;

  @override
  Future<Map<String, ProductModel>> getProductsByIds(List<String> ids) async =>
      {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  const _FakeNavigationShell(this.currentIndex);

  @override
  final int currentIndex;

  @override
  State<_FakeNavigationShell> createState() => _FakeNavigationShellState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNavigationShellState extends State<_FakeNavigationShell> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _wrapWithProviders(Widget child) {
  final auth = _FakeAuthService();
  final appState = AppState(ordersService: OrdersService(), authService: auth)
    ..setUserForTesting(null);
  final appSettings = AppSettingsProvider();
  final cart = CartProvider(productsService: _FakeProductsService());
  final classifieds = ClassifiedsProvider();
  final location = LocationProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider<ClassifiedsProvider>.value(value: classifieds),
      ChangeNotifierProvider<LocationProvider>.value(value: location),
    ],
    child: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('DesktopHeader prikazuje oba dugmeta za goste i otvara /login?tab=register',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: DesktopHeader(isStandalone: true),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (_, state) {
            final tab = state.uri.queryParameters['tab'] == 'register'
                ? AuthTab.register
                : AuthTab.login;
            return LoginScreen(initialTab: tab);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      _wrapWithProviders(
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('sr', 'RS'),
          supportedLocales: const [Locale('sr', 'RS')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registruj se'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);

    await tester.tap(find.text('Registruj se'));
    await tester.pumpAndSettle();

    expect(find.text('Kreirajte nalog'), findsOneWidget);
    expect(find.text('Registruj se putem Google-a'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Telefon *'), findsOneWidget);
  });

  testWidgets('HomeMobileAppBar za gosta prikazuje dugme Registruj se bez overflow-a na 360px',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrapWithProviders(
        MaterialApp(
          home: Scaffold(
            appBar: HomeMobileAppBar(
              isDark: false,
              isGuest: true,
              unreadCount: 0,
              cartCount: 0,
              onLocationTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registruj se'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MainShell na mobilnom za goste sadrzi Prijavi se i Registruj se',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrapWithProviders(
        const MaterialApp(
          home: Scaffold(
            body: MainShell(navigationShell: _FakeNavigationShell(0)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Prijavi se')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Registruj se')),
        findsOneWidget);
  });

  testWidgets('LoginScreen omogucava prebacivanje izmedju Registracije i Prijave bez overflow-a pri 2.0x skali',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrapWithProviders(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2.0),
            ),
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dobrodošli nazad'), findsOneWidget);

    final regTab = find.text('Registruj se').first;
    await tester.ensureVisible(regTab);
    await tester.tap(regTab);
    await tester.pumpAndSettle();

    expect(find.text('Kreirajte nalog'), findsOneWidget);
    expect(find.text('Registruj se putem Google-a'), findsOneWidget);
    expect(find.text('ili klasična registracija'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final loginTab = find.text('Prijava').first;
    await tester.ensureVisible(loginTab);
    await tester.tap(loginTab);
    await tester.pumpAndSettle();

    expect(find.text('Dobrodošli nazad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileGuestPrompt prikazuje oba dugmeta Registruj se i Prijavi se',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ProfileGuestPrompt()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registruj se'), findsOneWidget);
    expect(find.text('Prijavi se'), findsOneWidget);
  });
}
