import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/common/verified_badge.dart';

void main() {
  testWidgets('VerifiedBadge renders standalone badge with default leaf emoji', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            size: 32,
          ),
        ),
      ),
    );

    expect(find.text('🌿'), findsOneWidget);
  });

  testWidgets('VerifiedBadge renders with custom icon when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            icon: Icons.eco,
            size: 28,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.eco), findsOneWidget);
  });

  testWidgets('VerifiedBadge renders text and leaf emoji in pill mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            text: 'VERIFIKOVANO GAZDINSTVO',
          ),
        ),
      ),
    );

    expect(find.text('VERIFIKOVANO GAZDINSTVO'), findsOneWidget);
    expect(find.text('🌿'), findsOneWidget);
  });

  testWidgets('VerifiedBadge renders in compact mode without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text('🌿'), findsOneWidget);
  });

  testWidgets('VerifiedBadge displays tooltip message when provided on standalone badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            tooltip: 'Registrovano gazdinstvo 123456',
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
  });
}

