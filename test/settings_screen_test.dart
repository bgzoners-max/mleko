import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/settings_screen.dart';
import 'package:mleko/services/services.dart';

class _FakeAuthService extends Fake implements AuthService {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  User? get currentSupabaseUser => null;
  @override
  Future<void> signOut() async {}
}

class _FakeOrdersService extends Fake implements OrdersService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 'user-settings-1',
    email: 'korisnik@example.com',
    displayName: 'Petar Petrović',
    role: UserRole.buyer,
    createdAt: DateTime(2025, 1, 1),
  );

  final adminUser = UserModel(
    id: 'admin-settings-1',
    email: 'admin@example.com',
    displayName: 'Admin Korisnik',
    role: UserRole.buyer,
    isAdmin: true,
    createdAt: DateTime(2025, 1, 1),
  );

  Widget createTestWidget({
    required UserModel user,
    required AppSettingsProvider appSettings,
  }) {
    final appState = AppState(
      ordersService: _FakeOrdersService(),
      authService: _FakeAuthService(),
    )..setUserForTesting(user);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<AppSettingsProvider>.value(value: appSettings),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen renders 2-column layout on desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final appSettings = AppSettingsProvider();
    await tester.pumpWidget(
      createTestWidget(user: testUser, appSettings: appSettings),
    );
    await tester.pumpAndSettle();

    expect(find.text('Podešavanja'), findsOneWidget);
    expect(find.text('Izgled i prikaz'), findsOneWidget);
    expect(find.text('Nalog i profil'), findsOneWidget);
    expect(find.text('Podrška i pravno'), findsOneWidget);
    expect(find.text('Odjavi se'), findsOneWidget);

    // Switches
    expect(find.text('Tamna tema'), findsOneWidget);
    expect(find.text('Animacije'), findsOneWidget);
    expect(find.text('Kompaktan prikaz'), findsOneWidget);
    expect(find.text('Veličina teksta'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders admin section for admin user', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final appSettings = AppSettingsProvider();
    await tester.pumpWidget(
      createTestWidget(user: adminUser, appSettings: appSettings),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administracija'), findsOneWidget);
    expect(find.text('Admin panel'), findsOneWidget);
    expect(find.text('Push health'), findsOneWidget);
    expect(find.text('Moderacija oglasa'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders compact single column on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final appSettings = AppSettingsProvider();
    await tester.pumpWidget(
      createTestWidget(user: testUser, appSettings: appSettings),
    );
    await tester.pumpAndSettle();

    expect(find.text('Izgled i prikaz'), findsOneWidget);
    expect(find.text('Tamna tema'), findsOneWidget);
    expect(find.text('Kompaktan prikaz'), findsOneWidget);
  });
}
