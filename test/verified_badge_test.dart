import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/common/verified_badge.dart';

void main() {
  testWidgets('VerifiedBadge renders standalone icon-only badge with custom size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            size: 32,
            shimmer: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('VerifiedBadge renders text and default icon in pill mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            text: 'VERIFIKOVANO GAZDINSTVO',
            shimmer: false,
          ),
        ),
      ),
    );

    expect(find.text('VERIFIKOVANO GAZDINSTVO'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets('VerifiedBadge renders in compact mode without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            compact: true,
            shimmer: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets('VerifiedBadge displays tooltip message when provided on standalone badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VerifiedBadge(
            tooltip: 'Registrovano gazdinstvo 123456',
            shimmer: false,
          ),
        ),
      ),
    );

    expect(find.byType(Tooltip), findsOneWidget);
  });
}

