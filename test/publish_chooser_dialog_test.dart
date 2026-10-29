import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/widgets/navigation/desktop_header_actions.dart';
import 'package:mleko/widgets/navigation/publish_chooser_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester, {
    required bool isGuest,
    bool isSeller = false,
  }) async {
    // DesktopHeaderActions je širok klaster — podrazumevani 800x600 test
    // viewport ga sažme pa CTA dugme ispadne van ekrana. Simuliramo desktop.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: DesktopHeaderActions(
                isDark: false,
                isGuest: isGuest,
                user: null,
                cartCount: 0,
                unreadCount: 0,
                onNavigateTo: (_, {required String route}) {},
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/becoming-seller',
          builder: (context, state) => const Scaffold(body: Text('Becoming Seller')),
        ),
        GoRoute(
          path: '/add-product',
          builder: (context, state) => const Scaffold(body: Text('Add Product')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
        GoRoute(
          path: '/vodic-za-proizvodjace',
          builder: (context, state) => const Scaffold(body: Text('Guide')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsProvider>.value(
        value: AppSettingsProvider(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Header CTA is neutral "Objavi" and opens the chooser', (tester) async {
    await pumpApp(tester, isGuest: true);

    // Dugme više ne nosi naziv "Postavi oglas" koji proizvođače hrane
    // uvodi u formu za male oglase.
    expect(find.text('Postavi oglas'), findsNothing);
    expect(find.text('Objavi'), findsOneWidget);

    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();

    expect(find.text('Šta želite da objavite?'), findsOneWidget);
  });

  testWidgets('Chooser shows both clearly labelled paths with examples',
      (tester) async {
    await pumpApp(tester, isGuest: true);
    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();

    expect(find.text('Domaća hrana sa gazdinstva'), findsOneWidget);
    expect(find.text('Sve ostalo — besplatan mali oglas'), findsOneWidget);
    // Primeri proizvoda u opisima — proizvođac sira odmah prepoznaje sebe.
    expect(find.textContaining('Sir, kajmak, mleko, med, meso'), findsOneWidget);
    expect(find.textContaining('Traktori, mašine, vozila, alati'), findsOneWidget);
    // Link ka vodiču je dostupan direktno iz dijaloga.
    expect(
      find.text('Ne znate gde šta ide? Pročitajte kratki vodič'),
      findsOneWidget,
    );
  });

  testWidgets('Choosing food (seller) navigates to add-product', (tester) async {
    await pumpApp(tester, isGuest: false);
    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();

    // Proizvođac hrane klikce prvu opciju — Pijaca.
    await tester.tap(find.text('Domaća hrana sa gazdinstva'));
    await tester.pumpAndSettle();

    // Nije gost i nije prodavac → vodi ga na otvaranje prodavničkog profila,
    // a NE na formu za male oglase.
    expect(find.text('Becoming Seller'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('Choosing classifieds navigates to new-classified form',
      (tester) async {
    await pumpApp(tester, isGuest: false);
    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sve ostalo — besplatan mali oglas'));
    await tester.pumpAndSettle();

    // Klasican oglas i dalje radi kao do sada.
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Guide link in chooser navigates to /vodic-za-proizvodjace',
      (tester) async {
    await pumpApp(tester, isGuest: true);
    await tester.tap(find.text('Objavi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ne znate gde šta ide? Pročitajte kratki vodič'));
    await tester.pumpAndSettle();

    expect(find.text('Guide'), findsOneWidget);
  });

  testWidgets('PublishChooserContent renders as plain widget too', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PublishChooserContent(isGuest: false, isSeller: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Šta želite da objavite?'), findsOneWidget);
    expect(find.text('PIJACA'), findsOneWidget);
    expect(find.text('MALI OGLASI'), findsOneWidget);
  });
}
