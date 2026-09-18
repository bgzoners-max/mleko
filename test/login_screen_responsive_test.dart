import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/auth/login_screen.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp() {
    final auth = AuthService();
    final appState = AppState(
      ordersService: OrdersService(),
      authService: auth,
    );
    final appSettings = AppSettingsProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
      ],
      child: const MaterialApp(
        home: Scaffold(body: LoginScreen()),
      ),
    );
  }

  testWidgets('Desktop mode displays Pijaca and Mali oglasi showcase cards',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify presence of both cards
    expect(find.text('Pijaca domaće hrane'), findsOneWidget);
    expect(find.text('Mali oglasi za sve'), findsOneWidget);

    // Verify side-by-side action buttons
    expect(find.text('Istraži Pijacu hrane →'), findsOneWidget);
    expect(find.text('Pregledaj Male oglase →'), findsOneWidget);

    // Verify form is present
    expect(find.text('Dobrodošli nazad'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Prijavi se'), findsOneWidget);
  });

  testWidgets('Mobile mode displays compact hero and mobile showcase cards',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify brand in compact hero
    expect(find.text('Domaći market'), findsWidgets);
    expect(find.text('100% BESPLATNO POSTAVLJANJE I OBNAVLJANJE OGLASA'), findsOneWidget);

    // Verify login form is immediately visible
    expect(find.text('Dobrodošli nazad'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Prijavi se'), findsOneWidget);

    // Scroll down to check mobile showcase section
    final showcaseFinder = find.text('Zašto izabrati Domaći market?');
    await tester.scrollUntilVisible(showcaseFinder, 300,
        scrollable: find.byType(Scrollable).first);
    expect(showcaseFinder, findsOneWidget);

    expect(find.text('Pijaca domaće hrane'), findsOneWidget);
    expect(find.text('Mali oglasi za sve'), findsOneWidget);
  });

  testWidgets('LoginScreen renders cleanly without overflows with 2.0x accessibility font scale',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final auth = AuthService();
    final appState = AppState(
      ordersService: OrdersService(),
      authService: auth,
    );
    final appSettings = AppSettingsProvider();

    final errorList = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      errorList.add(details);
    };

    try {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(body: LoginScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = originalOnError;
    }

    // Verify AutofillGroup is present
    expect(find.byType(AutofillGroup), findsOneWidget);

    // Verify critical elements are accessible
    expect(find.text('Dobrodošli nazad'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Prijavi se'), findsOneWidget);

    // No exception thrown / no RenderFlex overflow
    expect(errorList, isEmpty);
  });
}
