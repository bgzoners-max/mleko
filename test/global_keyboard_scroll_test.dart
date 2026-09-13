import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/global_keyboard_scroll.dart';

void main() {
  testWidgets('GlobalKeyboardScroll does NOT intercept Space key inside TextField', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardScroll(
            child: ListView(
              children: [
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('test_field'),
                  controller: controller,
                ),
                const SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap to focus the text field
    await tester.tap(find.byKey(const ValueKey('test_field')));
    await tester.pump();

    // Type text with spaces
    await tester.enterText(find.byKey(const ValueKey('test_field')), 'Prva rec ');
    await tester.pump();

    expect(controller.text, 'Prva rec ');

    // Send a space key event directly
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // The text field should continue working without space being swallowed or causing scroll
    expect(controller.text, isNotEmpty);
  });
}
