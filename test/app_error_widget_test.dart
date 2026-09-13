import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/common/app_error_widget.dart';

void main() {
  group('AppErrorWidget Tests', () {
    testWidgets('renders standard error view with title and actions', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: AppErrorWidget(
            details: const FlutterErrorDetails(exception: 'Simulated build failure'),
            onRetry: () => retryPressed = true,
          ),
        ),
      );

      expect(find.text('Došlo je do greške u prikazu'), findsOneWidget);
      expect(find.text('Pokušaj ponovo'), findsOneWidget);
      expect(find.text('Početna strana'), findsOneWidget);

      await tester.tap(find.text('Pokušaj ponovo'));
      await tester.pump();
      expect(retryPressed, isTrue);
    });

    testWidgets('renders compact error view when tightly constrained', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 60,
              child: AppErrorWidget(
                details: FlutterErrorDetails(exception: 'Overflow'),
                customMessage: 'Problem sa stavkom',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Problem sa stavkom'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      // U kompaktnom režimu ne prikazujemo veliki naslov celog ekrana
      expect(find.text('Došlo je do greške u prikazu'), findsNothing);
    });

    testWidgets('toggles technical details on button tap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppErrorWidget(
            details: FlutterErrorDetails(exception: 'UniqueTestException123'),
          ),
        ),
      );

      expect(find.text('Prikaži tehničke detalje'), findsOneWidget);
      expect(find.textContaining('UniqueTestException123'), findsNothing);

      await tester.tap(find.text('Prikaži tehničke detalje'));
      await tester.pump();

      expect(find.text('Sakrij tehničke detalje'), findsOneWidget);
      expect(find.textContaining('UniqueTestException123'), findsOneWidget);
    });
  });
}
