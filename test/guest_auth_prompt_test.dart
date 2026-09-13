import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/guest_auth_prompt.dart';

void main() {
  group('GuestAuthPrompt', () {
    testWidgets('renders modal bottom sheet on mobile and dismisses on continue', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showGuestAuthPrompt(
                  context,
                  title: 'Potrebna prijava za oglase',
                  message: 'Prijavite se da biste postavili oglas.',
                ),
                child: const Text('Otvori prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otvori prompt'));
      await tester.pumpAndSettle();

      expect(find.text('Potrebna prijava za oglase'), findsOneWidget);
      expect(find.text('Prijavite se da biste postavili oglas.'), findsOneWidget);
      expect(find.text('Prijavi se na nalog'), findsOneWidget);
      expect(find.text('Besplatna registracija'), findsOneWidget);
      expect(find.text('Nastavi kao gost'), findsOneWidget);

      await tester.tap(find.text('Nastavi kao gost'));
      await tester.pumpAndSettle();

      expect(find.text('Potrebna prijava za oglase'), findsNothing);
    });

    testWidgets('renders dialog on desktop and dismisses on continue', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showGuestAuthPrompt(
                  context,
                  title: 'Desktop Prijava',
                ),
                child: const Text('Otvori desktop prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Otvori desktop prompt'));
      await tester.pumpAndSettle();

      expect(find.text('Desktop Prijava'), findsOneWidget);
      expect(find.text('Prijavi se'), findsOneWidget);
      expect(find.text('Registruj se'), findsOneWidget);
      expect(find.text('Nastavi kao gost'), findsOneWidget);

      await tester.tap(find.text('Nastavi kao gost'));
      await tester.pumpAndSettle();

      expect(find.text('Desktop Prijava'), findsNothing);
    });
  });
}
