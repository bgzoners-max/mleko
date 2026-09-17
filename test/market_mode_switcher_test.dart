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
}
