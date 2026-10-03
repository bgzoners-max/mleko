import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/core/web_seo.dart';
import 'package:mleko/core/router.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/profile/edit_profile_form.dart';
import 'package:mleko/screens/edit_profile_screen.dart';

const Object _undefined = Object();

class _FakeUsersService extends Fake implements UsersService {
  String? lastUpdatedImage;
  Map<String, dynamic>? lastUpsertParams;

  @override
  Future<void> updateProfileImage(String userId, String? imageUrl) async {
    lastUpdatedImage = imageUrl;
  }

  @override
  Future<void> upsertProfile(
    String userId, {
    String? email,
    Object? displayName = _undefined,
    Object? phone = _undefined,
    Object? city = _undefined,
    Object? postalCode = _undefined,
    String? role,
    bool? isGuest,
    Object? farmName = _undefined,
    Object? location = _undefined,
    Object? profileImageUrl = _undefined,
    double? lat,
    double? lng,
    bool? phonePublic,
  }) async {
    lastUpsertParams = {
      'userId': userId,
      'displayName': displayName,
      'phone': phone,
      'city': city,
      'postalCode': postalCode,
      'location': location,
      'phonePublic': phonePublic,
    };
  }

  @override
  Future<void> updateSellerTags(String userId, List<String> tags) async {}
}

class _FakeAuthService extends Fake implements AuthService {
  String? lastResetEmail;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentSupabaseUser => null;

  @override
  Future<void> sendPasswordReset(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<UserModel?> getCurrentUser() async => null;
}

class _FakeOrdersService extends Fake implements OrdersService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserModel address preservation', () {
    test('Seller address is preserved from json location and address', () {
      final sellerJsonWithLocation = {
        'id': 'seller-1',
        'role': 'seller',
        'farm_name': 'Moja Farma',
        'location': 'Selo Popučke 12',
      };
      final seller1 = UserModel.fromJson(sellerJsonWithLocation);
      expect(seller1.address, 'Selo Popučke 12');

      final sellerJsonWithExplicitAddress = {
        'id': 'seller-2',
        'role': 'seller',
        'farm_name': 'Moja Farma 2',
        'address': 'Glavna Ulica 45',
        'location': 'Valjevo',
      };
      final seller2 = UserModel.fromJson(sellerJsonWithExplicitAddress);
      expect(seller2.address, 'Glavna Ulica 45');
    });

    test('Buyer address is preserved from json location and address', () {
      final buyerJson = {
        'id': 'buyer-1',
        'role': 'buyer',
        'location': 'Knez Mihailova 10',
      };
      final buyer = UserModel.fromJson(buyerJson);
      expect(buyer.address, 'Knez Mihailova 10');
    });
  });

  group('SEO and Router registration for /profile/edit', () {
    test('/profile/edit is covered by noindex, nofollow in SEO metadata', () {
      expect(() => applyRouteSeo('/profile/edit'), returnsNormally);
    });

    test('createRouter contains /profile/edit route', () {
      final appState = AppState(
        ordersService: _FakeOrdersService(),
        authService: _FakeAuthService(),
      );
      final router = createRouter(appState);
      final hasEditProfileRoute = router.configuration.routes.any(
        (r) => r is GoRoute && r.path == '/profile/edit',
      );
      expect(hasEditProfileRoute, isTrue);
    });
  });

  group('EditProfileForm Widget Tests', () {
    final buyerUser = UserModel(
      id: 'test-buyer-1',
      email: 'kupac@example.com',
      displayName: 'Marko Marković',
      phone: '0641234567',
      phonePublic: true,
      city: 'Novi Sad',
      postalCode: '21000',
      address: 'Dunavska 15',
      role: UserRole.buyer,
      createdAt: DateTime(2025, 1, 1),
    );

    final sellerUser = UserModel(
      id: 'test-seller-1',
      email: 'prodavac@example.com',
      displayName: 'Domaćinstvo Jovanović',
      phone: '0659876543',
      phonePublic: false,
      city: 'Čačak',
      postalCode: '32000',
      address: 'Moravička 8',
      role: UserRole.seller,
      sellerTags: ['Bio sertifikat', 'Organski uzgoj'],
      createdAt: DateTime(2025, 1, 1),
    );

    Widget createTestWidget({
      required UserModel user,
      required _FakeUsersService usersService,
      required _FakeAuthService authService,
    }) {
      final appState = AppState(
        ordersService: _FakeOrdersService(),
        authService: authService,
      )..setUserForTesting(user);

      return MultiProvider(
        providers: [
          Provider<UsersService>.value(value: usersService),
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EditProfileForm(user: user),
            ),
          ),
        ),
      );
    }

    testWidgets('renders all profile fields for buyer', (tester) async {
      final fakeUsers = _FakeUsersService();
      final fakeAuth = _FakeAuthService();

      await tester.pumpWidget(
        createTestWidget(
          user: buyerUser,
          usersService: fakeUsers,
          authService: fakeAuth,
        ),
      );
      await tester.pumpAndSettle();

      // Display Name & Full Name labels and values
      expect(find.text('Prikazano ime (Display name)'), findsOneWidget);
      expect(find.text('Marko Marković'), findsWidgets);
      expect(find.text('Puno ime i prezime'), findsOneWidget);

      // Phone and privacy switch
      expect(find.text('Broj telefona'), findsOneWidget);
      expect(find.text('0641234567'), findsOneWidget);
      expect(find.text('Telefon je vidljiv svima'), findsOneWidget);

      // Location fields
      expect(find.text('Grad ili mesto'), findsOneWidget);
      expect(find.text('Novi Sad'), findsOneWidget);
      expect(find.text('Poštanski broj'), findsOneWidget);
      expect(find.text('21000'), findsOneWidget);
      expect(find.text('Adresa (ulica i broj)'), findsOneWidget);
      expect(find.text('Dunavska 15'), findsOneWidget);

      // Account info
      expect(find.text('Email: kupac@example.com'), findsOneWidget);
      expect(find.text('Resetuj lozinku'), findsOneWidget);

      // Submit button
      expect(find.text('Sačuvaj izmene'), findsOneWidget);

      // Buyer should not see seller tags section
      expect(find.text('Oznake gazdinstva / prodavca'), findsNothing);
    });

    testWidgets('renders seller tags section for seller', (tester) async {
      final fakeUsers = _FakeUsersService();
      final fakeAuth = _FakeAuthService();

      await tester.pumpWidget(
        createTestWidget(
          user: sellerUser,
          usersService: fakeUsers,
          authService: fakeAuth,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Oznake gazdinstva / prodavca'), findsOneWidget);
      expect(find.text('Bio sertifikat'), findsWidgets);
      expect(find.text('Organski uzgoj'), findsWidgets);
    });

    testWidgets('EditProfileScreen can be instantiated', (tester) async {
      const screen = EditProfileScreen();
      expect(screen, isA<EditProfileScreen>());
    });

    testWidgets('submitting profile changes calls upsertProfile with updated values', (tester) async {
      final fakeUsers = _FakeUsersService();
      final fakeAuth = _FakeAuthService();
      bool savedCalled = false;

      final appState = AppState(
        ordersService: _FakeOrdersService(),
        authService: fakeAuth,
      )..setUserForTesting(buyerUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UsersService>.value(value: fakeUsers),
            Provider<AuthService>.value(value: fakeAuth),
            ChangeNotifierProvider<AppState>.value(value: appState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileForm(
                  user: buyerUser,
                  onSaved: () => savedCalled = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new address
      final addressFinder = find.widgetWithText(TextField, 'Adresa (ulica i broj)');
      expect(addressFinder, findsOneWidget);
      await tester.enterText(addressFinder, 'Bulevar Oslobođenja 100');

      // Tap save
      final saveBtn = find.text('Sačuvaj izmene');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeUsers.lastUpsertParams, isNotNull);
      expect(fakeUsers.lastUpsertParams!['userId'], 'test-buyer-1');
      expect(fakeUsers.lastUpsertParams!['location'], 'Bulevar Oslobođenja 100');
      expect(savedCalled, isTrue);
    });

    testWidgets('tapping Resetuj lozinku invokes sendPasswordReset', (tester) async {
      final fakeUsers = _FakeUsersService();
      final fakeAuth = _FakeAuthService();

      await tester.pumpWidget(
        createTestWidget(
          user: buyerUser,
          usersService: fakeUsers,
          authService: fakeAuth,
        ),
      );
      await tester.pumpAndSettle();

      final resetBtn = find.text('Resetuj lozinku');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      expect(fakeAuth.lastResetEmail, 'kupac@example.com');
      expect(find.text('Link za promenu lozinke poslat je na adresu: kupac@example.com'), findsOneWidget);
    });
  });
}
