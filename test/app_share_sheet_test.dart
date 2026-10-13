import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/app_share_sheet.dart';

void main() {
  testWidgets('showAppShareSheet renders share options on mobile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showAppShareSheet(
                  context,
                  title: 'Domaći kravlji sir',
                  url: 'https://www.domacimarket.rs/p/12345',
                  shareText: 'Domaći sir sa Zlatibora',
                );
              },
              child: const Text('Podeli'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Podeli'));
    await tester.pumpAndSettle();

    expect(find.text('Podeli ponudu'), findsOneWidget);
    expect(find.text('Domaći kravlji sir'), findsOneWidget);
    expect(find.text('Kopiraj link'), findsOneWidget);
    expect(find.text('Viber'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Više opcija'), findsOneWidget);
  });
}
