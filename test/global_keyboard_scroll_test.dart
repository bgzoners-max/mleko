import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/global_keyboard_scroll.dart';

void main() {
  testWidgets('GlobalKeyboardScroll does NOT intercept keys inside TextField', (tester) async {
    final controller = TextEditingController();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardScroll(
            child: ListView(
              controller: scrollController,
              children: [
                const SizedBox(height: 20),
                TextField(
                  key: const ValueKey('test_field'),
                  controller: controller,
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap to focus the text field
    await tester.tap(find.byKey(const ValueKey('test_field')));
    await tester.pump();

    // Type text with spaces
    await tester.enterText(find.byKey(const ValueKey('test_field')), 'Prva rec ');
    await tester.pump();
    expect(controller.text, 'Prva rec ');

    // Send Space key
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.text, isNotEmpty);

    // Send PageDown key while text field is focused -> should NOT scroll
    final offsetBefore = scrollController.offset;
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(scrollController.offset, offsetBefore);
  });

  testWidgets('GlobalKeyboardScroll scrolls ListView WITH controller on Desktop (Windows)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Scaffold(
            body: GlobalKeyboardScroll(
              child: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemBuilder: (context, index) => SizedBox(
                  height: 100,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(scrollController.offset, 0.0);

      // 1. PageDown -> should scroll down ~80% of viewport
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(scrollController.offset, greaterThan(200.0));
      final scrolledOffset = scrollController.offset;

      // 2. PageUp -> should scroll back up
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(scrollController.offset, lessThan(scrolledOffset));

      // 3. End -> should scroll to bottom
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(scrollController.offset, scrollController.position.maxScrollExtent);

      // 4. Home -> should scroll back to top (0.0)
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(scrollController.offset, 0.0);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('GlobalKeyboardScroll scrolls ListView WITHOUT controller on Desktop (Windows)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: Scaffold(
            body: GlobalKeyboardScroll(
              child: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) => SizedBox(
                  height: 100,
                  child: Text('Item $index'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.pixels, 0.0);

      // PageDown
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(200.0));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('GlobalKeyboardScroll scrolls when focus is shifted or unfocused', (tester) async {
    final focusNode = FocusNode();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardScroll(
            child: Column(
              children: [
                ElevatedButton(
                  focusNode: focusNode,
                  onPressed: () {},
                  child: const Text('Button'),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (context, index) => SizedBox(
                      height: 100,
                      child: Text('Item $index'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Focus the button and press PageDown
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(200.0));

    // 2. Unfocus and press PageDown again
    focusNode.unfocus();
    await tester.pump();

    final prevOffset = scrollController.offset;
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(prevOffset));
  });
}
