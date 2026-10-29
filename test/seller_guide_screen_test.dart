import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mleko/screens/seller_guide_screen.dart';

void main() {
  Future<void> pumpGuide(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/vodic-za-proizvodjace',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/vodic-za-proizvodjace',
          builder: (context, state) => const SellerGuideScreen(),
        ),
        GoRoute(
          path: '/becoming-seller',
          builder: (context, state) => const Scaffold(body: Text('Becoming Seller')),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const Scaffold(body: Text('Categories')),
        ),
        GoRoute(
          path: '/classifieds',
          builder: (context, state) => const Scaffold(body: Text('Classifieds')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('SellerGuideScreen renders hero and key sections', (tester) async {
    await pumpGuide(tester);

    // AppBar naslov + footer link ka vodiču.
    expect(find.text('Kako postaviti proizvode'), findsNWidgets(2));
    expect(
      find.text('Izložite svoje proizvode na Pijaci domacimarket.rs — besplatno'),
      findsOneWidget,
    );
    expect(find.text('Pijaca ili Mali oglasi — gde šta ide?'), findsOneWidget);
    expect(find.text('Zlatno pravilo'), findsOneWidget);
    expect(
      find.text('Kako postaviti proizvode na sajt — korak po korak'),
      findsOneWidget,
    );
    expect(find.text('Česta pitanja proizvođača'), findsOneWidget);
    expect(find.text('Spremni da otvorite svoju tezgu?'), findsOneWidget);
  });

  testWidgets('SellerGuideScreen explains Pijaca vs Mali oglasi difference',
      (tester) async {
    await pumpGuide(tester);

    expect(find.text('Pijaca domaće hrane'), findsOneWidget);
    expect(find.text('Mali oglasi (100% besplatno)'), findsOneWidget);
    // „Zlatno pravilo" objašnjava da hrana ide na Pijacu, a ne u oglase.
    final goldenRule =
        find.textContaining('Hrana se ne objavljuje kao mali oglas');
    expect(goldenRule, findsOneWidget);
  });

  testWidgets('SellerGuideScreen shows all five guide steps', (tester) async {
    await pumpGuide(tester);

    expect(find.text('Registrujte besplatan nalog'), findsOneWidget);
    expect(
      find.text('Otvorite prodavnički profil — „Postani prodavac"'),
      findsOneWidget,
    );
    expect(find.text('Dodajte proizvode'), findsOneWidget);
    expect(find.text('Primajte porudžbine i upite'), findsOneWidget);
    expect(find.text('Pripremite, isporučite i naplatite direktno'), findsOneWidget);
  });

  testWidgets('SellerGuideScreen CTA buttons navigate to key routes',
      (tester) async {
    await pumpGuide(tester);

    expect(find.text('Postani prodavac'), findsOneWidget);
    expect(find.text('Pogledaj Pijacu'), findsNWidgets(2)); // sekcija + CTA kartica
    // Dugme „Mali oglasi" u CTA kartici + footer link.
    expect(find.text('Mali oglasi'), findsNWidgets(2));

    final ctaButton = find.text('Postani prodavac');
    await tester.ensureVisible(ctaButton);
    await tester.pumpAndSettle();
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();
    expect(find.text('Becoming Seller'), findsOneWidget);
  });
}
