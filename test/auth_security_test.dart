import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/auth/login_screen.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailingAuthService extends AuthService {
  int attempts = 0;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    attempts++;
    throw Exception('Invalid login credentials');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Auth Security & Validation Tests', () {
    test('checkEmailExists returns false for invalid emails without RPC', () async {
      final auth = AuthService();
      expect(await auth.checkEmailExists(''), isFalse);
      expect(await auth.checkEmailExists('invalid'), isFalse);
      expect(await auth.checkEmailExists('no_at.com'), isFalse);
      expect(await auth.checkEmailExists('a@b'), isFalse);
    });

    test('checkPhoneExists returns false for short or empty numbers without RPC', () async {
      final auth = AuthService();
      expect(await auth.checkPhoneExists(''), isFalse);
      expect(await auth.checkPhoneExists('   '), isFalse);
      expect(await auth.checkPhoneExists('123'), isFalse);
      expect(await auth.checkPhoneExists('+381'), isFalse);
    });

    testWidgets('LoginScreen locks out after 5 consecutive failed attempts', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final failingAuth = FailingAuthService();
      final appState = AppState(
        ordersService: OrdersService(),
        authService: failingAuth,
      );
      final appSettings = AppSettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final emailFinder = find.widgetWithText(TextField, 'Email');
      final passwordFinder = find.widgetWithText(TextField, 'Lozinka');
      final submitFinder = find.widgetWithText(ElevatedButton, 'Prijavi se');

      expect(emailFinder, findsOneWidget);
      expect(passwordFinder, findsOneWidget);
      expect(submitFinder, findsOneWidget);

      await tester.enterText(emailFinder, 'test@example.com');
      await tester.enterText(passwordFinder, 'wrongpass');

      // Izvrši 4 neuspešna pokušaja
      for (int i = 0; i < 4; i++) {
        await tester.ensureVisible(submitFinder);
        await tester.tap(submitFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (find.text('Zatvori').evaluate().isNotEmpty) {
          await tester.tap(find.text('Zatvori'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      expect(failingAuth.attempts, equals(4));
      // Form još nije zaključan
      expect(find.text('Prijavi se'), findsOneWidget);

      // 5. neuspešan pokušaj — aktivira zaključavanje (lockout)
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      if (find.text('Zatvori').evaluate().isNotEmpty) {
        await tester.tap(find.text('Zatvori'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(failingAuth.attempts, equals(5));

      // Dugme sada prikazuje odbrojavanje i onemogućeno je
      expect(find.textContaining('Pokušajte ponovo za'), findsOneWidget);
      final lockedButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Pokušajte ponovo za 30 s'),
      );
      expect(lockedButton.onPressed, isNull);

      // Polja za unos su onemogućena
      final emailTextField = tester.widget<TextField>(emailFinder);
      expect(emailTextField.enabled, isFalse);

      final passwordTextField = tester.widget<TextField>(passwordFinder);
      expect(passwordTextField.enabled, isFalse);
    });

    testWidgets('LoginScreen guest exploration sets market mode without creating guest account', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthService();
      final appState = AppState(
        ordersService: OrdersService(),
        authService: auth,
      );
      final appSettings = AppSettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
          ],
          child: const MaterialApp(
            home: Scaffold(body: LoginScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final guestCardFinder = find.text('Istraži Pijacu hrane →');
      expect(guestCardFinder, findsOneWidget);

      await tester.ensureVisible(guestCardFinder);
      await tester.tap(guestCardFinder);
      await tester.pump();

      expect(appSettings.marketMode, equals(MarketMode.foodMarket));
      expect(appState.user, isNull);
    });
  });
}
