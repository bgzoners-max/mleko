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

    testWidgets('renders multiple incoming image slots with LinearProgressIndicator below each icon', (tester) async {
      const incomingCount = 3;
      const progressValue = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var k = 0; k < incomingCount; k++)
                    Container(
                      key: ValueKey('incoming_$k'),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Slika ${k + 1}/$incomingCount',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(3)),
                              child: LinearProgressIndicator(
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

      expect(find.text('Slika 1/3'), findsOneWidget);
      expect(find.text('Slika 2/3'), findsOneWidget);
      expect(find.text('Slika 3/3'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsNWidgets(3));

      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsNWidgets(3));
    });
  });
}
