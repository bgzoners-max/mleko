import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState renders in a 240px card without overflow', (tester) async {
    bool ctaPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: AppEmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Još nema ponude u katalogu',
              subtitle: 'Proizvodite domaću hranu? Otvorite svoju online tezgu besplatno.',
              ctaLabel: 'Postani prodavac',
              ctaIcon: Icons.add_business_outlined,
              onCtaPressed: () => ctaPressed = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all contents are present
    expect(find.text('Još nema ponude u katalogu'), findsOneWidget);
    expect(find.text('Proizvodite domaću hranu? Otvorite svoju online tezgu besplatno.'), findsOneWidget);
    expect(find.text('Postani prodavac'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);

    // Verify CTA button is visible and tappable
    await tester.tap(find.text('Postani prodavac'));
    expect(ctaPressed, isTrue);

    // Verify there are no RenderFlex overflows
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppEmptyState explicit isCompact: true formats properly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 220,
            child: AppEmptyState(
              isCompact: true,
              icon: Icons.storefront_outlined,
              title: 'Kompaktni naslov',
              subtitle: 'Kompaktni podnaslov',
              ctaLabel: 'Dugme',
              onCtaPressed: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Kompaktni naslov'), findsOneWidget);
    expect(find.text('Kompaktni podnaslov'), findsOneWidget);
    expect(find.text('Dugme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
