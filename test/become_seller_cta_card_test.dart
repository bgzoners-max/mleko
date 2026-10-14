import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/profile/become_seller_cta_card.dart';

void main() {
  testWidgets('BecomeSellerCtaCard renders title, subtitle and responds to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BecomeSellerCtaCard(
            isSelected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Prodaješ domaću hranu?'), findsOneWidget);
    expect(find.text('Otvori profil gazdinstva i prodaj direktno'), findsOneWidget);
    expect(find.text('Otvori gazdinstvo'), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);

    await tester.tap(find.byType(BecomeSellerCtaCard));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('BecomeSellerCtaCard renders selected state without error in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: BecomeSellerCtaCard(
            isSelected: true,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Prodaješ domaću hranu?'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });
}
