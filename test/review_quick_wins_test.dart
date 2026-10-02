import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, User;
import 'package:mleko/core/router.dart';
import 'package:mleko/main.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/auth/auth_service.dart';
import 'package:mleko/services/media/storage_service.dart';
import 'package:mleko/services/orders/orders_service.dart';

void main() {
  group('GlobalScrollBehavior (a11y scrollbar)', () {
    testWidgets('prikazuje Scrollbar na desktop platformi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          scrollBehavior: GlobalScrollBehavior(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(height: 2000, child: Text('sadrzaj')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scrollbar), findsWidgets);
    });

    testWidgets('ne prikazuje Scrollbar na touch platformi (Android)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          scrollBehavior: GlobalScrollBehavior(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(height: 2000, child: Text('sadrzaj')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scrollbar), findsNothing);
    });
  });

  group('StorageService.extractPathFromPublicUrl', () {
    test('izdvaja putanju i odbacuje query parametre', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/product-images/uid/abc.jpg?t=123',
        ),
        'uid/abc.jpg',
      );
    });

    test('radi za ostale buckete', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'farm-gallery',
          'https://x.supabase.co/storage/v1/object/public/farm-gallery/s1/foto.webp',
        ),
        's1/foto.webp',
      );
    });

    test('vraca null za pogresan bucket ili praznu putanju', () {
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/drugi-bucket/a.jpg',
        ),
        isNull,
      );
      expect(
        StorageService.extractPathFromPublicUrl(
          'product-images',
          'https://x.supabase.co/storage/v1/object/public/product-images/',
        ),
        isNull,
      );
    });
  });

  group('MainShell navigation index', () {
    testWidgets('gost na tabu Oglasi (currentIndex 1) ima selektovan index 1', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );
      final settings = AppSettingsProvider();
      const shell = _FakeNavigationShell(1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: settings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MainShell(navigationShell: shell),
            ),
          ),
        ),
      );
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });

    testWidgets('gost na tabu Pocetna (currentIndex 0) ima selektovan index 0', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );
      final settings = AppSettingsProvider();
      const shell = _FakeNavigationShell(0);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: settings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MainShell(navigationShell: shell),
            ),
          ),
        ),
      );
      await tester.pump();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);
    });

    testWidgets('gost na mobilnom ekranu ima selektovan index 1 na NavigationBar kada je currentIndex 1', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final appState = AppState(
        ordersService: OrdersService(),
        authService: _FakeAuthService(),
      );
      final settings = AppSettingsProvider();
      const shell = _FakeNavigationShell(1);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<AppSettingsProvider>.value(value: settings),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MainShell(navigationShell: shell),
            ),
          ),
        ),
      );
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 1);
    });
  });
}

class _FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentSupabaseUser => null;
}

class _FakeNavigationShell extends StatefulWidget implements StatefulNavigationShell {
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
  Widget build(BuildContext context) => const SizedBox();
}

