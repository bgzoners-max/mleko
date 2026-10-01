import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/product/full_screen_image_viewer.dart';

void main() {
  group('FullScreenImageViewer', () {
    testWidgets(
        'renders navigation arrows and indicators when multiple images exist',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final images = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
        'https://example.com/img3.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            productId: 'test_product',
            imageUrls: images,
            initialIndex: 0,
          ),
        ),
      );
      await tester.pump();

      // Check for arrows
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      // Tap next arrow
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      // Counter should now show 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);

      // Tap previous arrow
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      // Counter should return to 1 / 3
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('supports keyboard arrow keys for navigation', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final images = [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            productId: 'test_kbd',
            imageUrls: images,
            initialIndex: 0,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('1 / 2'), findsOneWidget);

      // Send right arrow key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('2 / 2'), findsOneWidget);

      // Send left arrow key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('does not render navigation arrows when only single image exists',
        (tester) async {
      final images = ['https://example.com/img1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: FullScreenImageViewer(
            productId: 'test_product_single',
            imageUrls: images,
            initialIndex: 0,
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
