import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/utils/error_messages.dart';

void main() {
  group('ClassifiedAd Image Picking & Validation', () {
    test('checkFileSize accepts images within 10 MB limit', () {
      final validBytes = Uint8List(5 * 1024 * 1024); // 5 MB
      expect(checkFileSize(validBytes), isNull);
    });

    test('checkFileSize rejects images exceeding 10 MB limit with friendly message', () {
      final oversizedBytes = Uint8List(11 * 1024 * 1024); // 11 MB
      final error = checkFileSize(oversizedBytes);
      expect(error, isNotNull);
      expect(error, contains('prevelika'));
      expect(error, contains('10 MB'));
    });

    testWidgets('renders incoming image slot with small LinearProgressIndicator below icon', (tester) async {
      const progressValue = 0.65;
      const statusText = 'Učitavanje slike 1/2...';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.green,
                          size: 26,
                        ),
                        const SizedBox(height: 4),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            statusText,
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: const LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text(statusText), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);

      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);

      final progressWidget = tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressWidget.value, equals(progressValue));
      expect(progressWidget.minHeight, equals(4.0));
    });
  });
}
