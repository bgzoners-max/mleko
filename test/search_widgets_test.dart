import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/search/search_widgets.dart';

void main() {
  testWidgets('SearchEmptyState renders properly and calls onResetFilters', (tester) async {
    var resetCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchEmptyState(
            hasFilters: true,
            onResetFilters: () => resetCalled = true,
          ),
        ),
      ),
    );

    expect(find.text('Ništa nismo pronašli'), findsOneWidget);
    expect(find.textContaining('Probaj da ukloniš aktivne filtere'), findsOneWidget);

    final cta = find.text('Pogledaj sve proizvode');
    expect(cta, findsOneWidget);
    await tester.tap(cta);
    await tester.pump();

    expect(resetCalled, isTrue);
  });

  testWidgets('SearchEmptyState subtitle changes when hasFilters is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchEmptyState(
            hasFilters: false,
            onResetFilters: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ništa nismo pronašli'), findsOneWidget);
    expect(find.textContaining('Probaj drugi naziv ili pogledaj celu ponudu.'), findsOneWidget);
  });
}
