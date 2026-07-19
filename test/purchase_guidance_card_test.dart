import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/purchase_guidance_card.dart';

void main() {
  testWidgets('renders guidance title and body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PurchaseGuidanceCard(
            icon: Icons.info_outline,
            title: 'Sledeći korak',
            body: 'Nakon slanja upita, prodavac će dobiti obaveštenje.',
          ),
        ),
      ),
    );

    expect(find.text('Sledeći korak'), findsOneWidget);
    expect(find.text('Nakon slanja upita, prodavac će dobiti obaveštenje.'),
        findsOneWidget);
  });
}
