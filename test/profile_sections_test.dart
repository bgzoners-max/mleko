import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/widgets/profile/profile_account_section.dart';
import 'package:mleko/widgets/profile/profile_classifieds_section.dart';
import 'package:mleko/widgets/profile/profile_guest_prompt.dart';
import 'package:mleko/widgets/profile/profile_market_section.dart';
import 'package:mleko/widgets/profile/profile_reviews_section.dart';

UserModel _user({bool isSeller = true}) => UserModel(
      id: 'u1',
      displayName: 'Marko',
      role: isSeller ? UserRole.seller : UserRole.buyer,
    );

bool _noopSection(String section, bool isWide) => false;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileGuestPrompt', () {
    testWidgets('prikazuje poziv na prijavu', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileGuestPrompt()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prijava'), findsOneWidget);
      expect(find.text('Prijavi se'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });

  group('ProfileMarketSection', () {
    testWidgets('prikazuje prodavačku karticu i porudžbine za prodavca',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMarketSection(
                user: _user(),
                isWide: false,
                onOpenPanel: (_, __, {required bool isWide, String? route}) {},
                isActiveSection: _noopSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MINI PIJACA'), findsOneWidget);
      expect(find.text('Moje porudžbine hrane'), findsOneWidget);
      expect(find.text('Omiljeni proizvodi'), findsOneWidget);
      expect(find.text('Podešavanja gazdinstva / prodavnice'), findsOneWidget);
    });
    testWidgets('kupac bez narudžbe vidi i omiljene stavke', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMarketSection(
                user: _user(isSeller: false),
                isWide: false,
                onOpenPanel: (_, __, {required bool isWide, String? route}) {},
                isActiveSection: _noopSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pratim gazdinstva i prodavce'), findsOneWidget);
      expect(find.text('Podešavanja gazdinstva / prodavnice'), findsNothing);
    });
  });

  group('ProfileClassifiedsSection', () {
    testWidgets('prikazuje sve tri oglasne stavke i poziva panel',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ClassifiedsProvider>.value(
              value: ClassifiedsProvider(),
              child: SingleChildScrollView(
                child: ProfileClassifiedsSection(
                  user: _user(),
                  isWide: false,
                  onOpenPanel: (section, __,
                      {required bool isWide, String? route}) {
                    opened.add(section);
                  },
                  isActiveSection: _noopSection,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OGLASNIK'), findsOneWidget);
      expect(find.text('Moji oglasi'), findsOneWidget);
      expect(find.text('Postavi novi oglas'), findsOneWidget);

      await tester.tap(find.text('Moji oglasi'));
      await tester.pumpAndSettle();
      expect(opened, ['my-classifieds']);
    });

    testWidgets('gost vidi prompt za prijavu umesto panela', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<ClassifiedsProvider>.value(
              value: ClassifiedsProvider(),
              child: SingleChildScrollView(
                child: ProfileClassifiedsSection(
                  user: _user().copyWith(isGuest: true),
                  isWide: false,
                  onOpenPanel: (section, __,
                      {required bool isWide, String? route}) {
                    opened.add(section);
                  },
                  isActiveSection: _noopSection,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Moji oglasi'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });
  });

  group('ProfileReviewsSection', () {
    testWidgets('prodavac vidi obe recenzijske stavke', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileReviewsSection(
                user: _user(),
                isWide: false,
                onOpenPanel: (_, __, {required bool isWide, String? route}) {},
                isActiveSection: _noopSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('OCENE I RECENZIJE'), findsOneWidget);
      expect(find.text('Recenzije kupaca'), findsOneWidget);
      expect(find.text('Moje date recenzije'), findsOneWidget);
    });

    testWidgets('kupac vidi samo svoje date recenzije', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileReviewsSection(
                user: _user(isSeller: false),
                isWide: false,
                onOpenPanel: (_, __, {required bool isWide, String? route}) {},
                isActiveSection: _noopSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recenzije kupaca'), findsNothing);
      expect(find.text('Moje date recenzije'), findsOneWidget);
    });
  });

  group('ProfileAccountSection', () {
    testWidgets('pun profil sadrži nalog, poruke i podešavanja',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileAccountSection(
                user: _user(),
                isWide: false,
                onOpenPanel: (_, __, {required bool isWide, String? route}) {},
                isActiveSection: _noopSection,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NALOG I PODEŠAVANJA'), findsOneWidget);
      expect(find.text('Poruke'), findsOneWidget);
      expect(find.text('Podešavanja'), findsOneWidget);
      expect(find.text('Podrška i pomoć'), findsOneWidget);
      expect(find.text('O aplikaciji'), findsOneWidget);
      expect(find.text('Odjavi se'), findsOneWidget);
    });
  });
}
