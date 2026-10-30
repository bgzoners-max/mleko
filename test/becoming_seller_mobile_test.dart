import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/screens/seller/becoming_seller_screen.dart';
import 'package:mleko/widgets/seller/seller_legal_registration_section.dart';
import 'package:mleko/services/services.dart';

class _MockAuthService extends Fake implements AuthService {}

class _MockUsersService extends Fake implements UsersService {}

class _MockAppState extends ChangeNotifier implements AppState {
  @override
  UserModel? user = const UserModel(
    id: 'user-1',
    role: UserRole.buyer,
    displayName: 'Test User',
    phone: '+38160123456',
    city: 'Beograd',
  );

  @override
  final AuthService authService = _MockAuthService();

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> refreshUser() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('BecomingSellerScreen renders on compact mobile 360x700 without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = _MockAppState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<UsersService>(create: (_) => _MockUsersService()),
        ],
        child: const MaterialApp(
          home: BecomingSellerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Domaćinstvo / Fizičko lice'), findsOneWidget);
    expect(find.text('Gazdinstvo ili Preduzetnik'), findsOneWidget);

    // Tap on Gazdinstvo ili Preduzetnik to reveal BPG/PIB sub-segments
    await tester.tap(find.text('Gazdinstvo ili Preduzetnik'));
    await tester.pumpAndSettle();

    expect(find.text('Poljoprivredno gazdinstvo (BPG)'), findsOneWidget);
    expect(find.text('Preduzetnik / Firma (PIB)'), findsOneWidget);
  });

  testWidgets(
      'SellerLegalRegistrationSection renders on compact mobile 360x700 without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = _MockAppState();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          Provider<UsersService>(create: (_) => _MockUsersService()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: SellerLegalRegistrationSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Status proizvođača hrane'), findsOneWidget);
    expect(find.text('Domaćinstvo / Fizičko lice'), findsOneWidget);
    expect(find.text('Gazdinstvo ili Preduzetnik'), findsOneWidget);

    await tester.tap(find.text('Gazdinstvo ili Preduzetnik'));
    await tester.pumpAndSettle();

    expect(find.text('Poljoprivredno gazdinstvo (BPG)'), findsOneWidget);
    expect(find.text('Preduzetnik / Firma (PIB)'), findsOneWidget);
  });
}
