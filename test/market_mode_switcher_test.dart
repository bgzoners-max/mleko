import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/home/market_mode_switcher.dart';

void main() {
  testWidgets('MarketModeSwitcher renders without layout errors', (tester) async {
    MarketMode mode = MarketMode.classifieds;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarketModeSwitcher(
            currentMode: mode,
            onModeChanged: (m) => mode = m,
          ),
        ),
      ),
    );
    expect(find.text('Mali Oglasi'), findsOneWidget);
    expect(find.text('Pijaca Hrane'), findsOneWidget);

    await tester.tap(find.text('Pijaca Hrane'));
    await tester.pumpAndSettle();
    expect(mode, MarketMode.foodMarket);
  });

  testWidgets('MarketModeSwitcher has high-contrast text in dark theme',
      (tester) async {
    MarketMode mode = MarketMode.classifieds;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: MarketModeSwitcher(
            currentMode: mode,
            onModeChanged: (m) => mode = m,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify both titles are rendered
    final maliOglasiFinder = find.text('Mali Oglasi');
    final pijacaFinder = find.text('Pijaca Hrane');
    expect(maliOglasiFinder, findsOneWidget);
    expect(pijacaFinder, findsOneWidget);

    // Verify icons
    expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);

    // Tap to switch to food market in dark mode
    await tester.tap(pijacaFinder);
    await tester.pumpAndSettle();
    expect(mode, MarketMode.foodMarket);
  });
}
