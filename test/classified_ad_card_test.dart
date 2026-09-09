import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/widgets/classifieds/classified_ad_card.dart';

void main() {
  final testAd = ClassifiedAdModel(
    id: 'ad-123',
    userId: 'user-456',
    title: 'Traktor IMT 539 u odličnom stanju',
    description: 'Generalno sređen, spreman za rad.',
    price: 4500,
    currency: 'EUR',
    priceType: 'negotiable',
    categoryId: 'masine',
    categoryName: 'Poljoprivredne mašine',
    condition: 'used',
    city: 'Kraljevo',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now(),
    sellerName: 'Gazdinstvo Petrović',
  );

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 400,
          child: child,
        ),
      ),
    );
  }

  testWidgets('ClassifiedAdCard displays price, title, city, condition and seller',
      (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      buildTestWidget(
        ClassifiedAdCard(
          ad: testAd,
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikacija cene i valute
    expect(find.text('4.500'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('· dogovor'), findsOneWidget);

    // Verifikacija naslova
    expect(find.text('Traktor IMT 539 u odličnom stanju'), findsOneWidget);

    // Verifikacija lokacije i prodavca
    expect(find.text('Kraljevo'), findsOneWidget);
    expect(find.text('Gazdinstvo Petrović'), findsOneWidget);

    // Verifikacija stanja
    expect(find.text('POLOVNO'), findsOneWidget);

    // Tap akcija
    await tester.tap(find.byType(ClassifiedAdCard));
    expect(tapped, isTrue);
  });

  testWidgets('ClassifiedAdCard renders sold overlay and free price correctly',
      (tester) async {
    final soldAd = ClassifiedAdModel(
      id: 'ad-sold',
      userId: 'user-789',
      title: 'Besplatne sadnice oraha',
      price: 0,
      currency: 'RSD',
      priceType: 'free',
      categoryId: 'sadnice',
      condition: 'not_applicable',
      city: 'Čačak',
      status: 'sold',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      buildTestWidget(
        ClassifiedAdCard(ad: soldAd),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BESPLATNO'), findsOneWidget);
    expect(find.text('PRODATO'), findsOneWidget);
    expect(find.text('Čačak'), findsOneWidget);
  });
}
