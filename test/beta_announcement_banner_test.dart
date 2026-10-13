import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/widgets/beta_announcement_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required Widget child,
    required AppSettingsProvider settings,
  }) {
    return ChangeNotifierProvider<AppSettingsProvider>.value(
      value: settings,
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  testWidgets('BetaAnnouncementBanner is visible by default and opens dialog',
      (tester) async {
    final settings = AppSettingsProvider();
    await tester.pump();

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        child: const BetaAnnouncementBanner(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikacija prisustva banera
    expect(find.textContaining('Domaći Market je u fazi testiranja i izrade.'),
        findsOneWidget);
    expect(find.text('Saznaj više'), findsOneWidget);

    // Klik na 'Saznaj više' otvara modal
    await tester.tap(find.text('Saznaj više'));
    await tester.pumpAndSettle();

    expect(find.byType(BetaInfoDialog), findsOneWidget);
    expect(find.text('Domaći Market'), findsOneWidget);
    expect(find.text('Šta već možete da koristite:'), findsOneWidget);
    expect(find.text('Razumem, nastavi ka sajtu'), findsOneWidget);

    // Zatvaranje modala
    await tester.ensureVisible(find.text('Razumem, nastavi ka sajtu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Razumem, nastavi ka sajtu'));
    await tester.pumpAndSettle();

    expect(find.byType(BetaInfoDialog), findsNothing);
  });

  testWidgets('BetaAnnouncementBanner dismiss button hides banner and persists state',
      (tester) async {
    final settings = AppSettingsProvider();
    await tester.pump();

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        child: const BetaAnnouncementBanner(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BetaAnnouncementBanner), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Klik na [✕] zatvara baner
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(settings.betaNoticeDismissed, isTrue);
    expect(find.textContaining('Domaći Market je u fazi testiranja i izrade.'),
        findsNothing);
  });

  testWidgets('BetaBadge opens BetaInfoDialog on tap', (tester) async {
    final settings = AppSettingsProvider();
    await tester.pump();

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        child: const Center(child: BetaBadge()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NOVO'), findsOneWidget);

    await tester.tap(find.text('NOVO'));
    await tester.pumpAndSettle();

    expect(find.byType(BetaInfoDialog), findsOneWidget);
    expect(find.text('Platforma u fazi testiranja i izrade'), findsOneWidget);
  });
}
