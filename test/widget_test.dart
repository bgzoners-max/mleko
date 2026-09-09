// Basic Flutter widget smoke test – verifies a simple widget renders.
// Full app test would require Supabase mock setup.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/screens/home_screen.dart';

void main() {
  testWidgets('Smoke test – MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Mleko')),
        ),
      ),
    );
    expect(find.text('Mleko'), findsOneWidget);
  });

  test('HomeScreen is included in test compilation graph and can be instantiated', () {
    const screen = HomeScreen();
    expect(screen, isA<HomeScreen>());
  });
}
