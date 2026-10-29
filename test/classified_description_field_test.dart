import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_description_field.dart';

void main() {
  group('ClassifiedDescriptionField Toolbar & Actions', () {
    testWidgets('renders all toolbar buttons (B, I, Undo, Redo, 1., •)',
        (tester) async {
      final controller = TextEditingController(text: 'Početni tekst');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedDescriptionField(controller: controller),
          ),
        ),
      );

      // Verify header and buttons
      expect(find.text('Detaljan opis proizvoda'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
    });

    testWidgets('bold button wraps selected text with **', (tester) async {
      final controller = TextEditingController(text: 'Ovo je odličan traktor');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedDescriptionField(controller: controller),
          ),
        ),
      );

      // Select "odličan" (index 7 to 14)
      controller.selection =
          const TextSelection(baseOffset: 7, extentOffset: 14);
      await tester.pump();

      // Tap 'B'
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Ovo je **odličan** traktor');

      // Tap Undo to revert
      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, 'Ovo je odličan traktor');

      // Tap Redo to re-apply
      await tester.tap(find.byIcon(Icons.redo_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, 'Ovo je **odličan** traktor');
    });

    testWidgets('italic button wraps selected text with *', (tester) async {
      final controller = TextEditingController(text: 'Uvoz iz Nemačke');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedDescriptionField(controller: controller),
          ),
        ),
      );

      // Select "Nemačke" (index 8 to 15)
      controller.selection =
          const TextSelection(baseOffset: 8, extentOffset: 15);
      await tester.pump();

      // Tap 'I'
      await tester.tap(find.text('I'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Uvoz iz *Nemačke*');
    });

    testWidgets('numbered list button formats lines', (tester) async {
      final controller = TextEditingController(text: 'Prva stavka\nDruga stavka');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedDescriptionField(controller: controller),
          ),
        ),
      );

      // Select all
      controller.selection =
          TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      await tester.pump();

      // Tap Numbered List icon
      await tester.tap(find.byIcon(Icons.format_list_numbered_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, '1. Prva stavka\n2. Druga stavka');
    });

    testWidgets('bullet list button formats lines', (tester) async {
      final controller = TextEditingController(text: 'Prva tačka\nDruga tačka');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedDescriptionField(controller: controller),
          ),
        ),
      );

      // Select all
      controller.selection =
          TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      await tester.pump();

      // Tap Bullet List icon
      await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, '• Prva tačka\n• Druga tačka');
    });
  });
}
