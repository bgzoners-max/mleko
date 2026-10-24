import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_price_section.dart';

void main() {
  group('ClassifiedPriceSection currency SegmentedButton', () {
    testWidgets('renders RSD and EUR segments and selects current currency',
        (tester) async {
      String? selectedCurrency = 'RSD';
      final priceController = TextEditingController(text: '1500');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ClassifiedPriceSection(
                  priceType: 'fixed',
                  currency: selectedCurrency ?? 'RSD',
                  priceController: priceController,
                  onPriceTypeChanged: (_) {},
                  onCurrencyChanged: (val) {
                    setState(() => selectedCurrency = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify SegmentedButton exists
      final segmentedButtonFinder =
          find.byType(SegmentedButton<String>);
      expect(segmentedButtonFinder, findsOneWidget);

      // Verify RSD and EUR labels exist
      expect(find.text('RSD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);

      // Verify initial selected value is RSD
      final segmentedButton =
          tester.widget<SegmentedButton<String>>(segmentedButtonFinder);
      expect(segmentedButton.selected, contains('RSD'));

      // Tap EUR segment to switch
      await tester.tap(find.text('EUR'));
      await tester.pumpAndSettle();

      expect(selectedCurrency, 'EUR');
    });

    testWidgets('initializes with EUR when currency is set to EUR',
        (tester) async {
      final priceController = TextEditingController(text: '500');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedPriceSection(
              priceType: 'fixed',
              currency: 'EUR',
              priceController: priceController,
              onPriceTypeChanged: (_) {},
              onCurrencyChanged: (_) {},
            ),
          ),
        ),
      );

      final segmentedButtonFinder =
          find.byType(SegmentedButton<String>);
      final segmentedButton =
          tester.widget<SegmentedButton<String>>(segmentedButtonFinder);
      expect(segmentedButton.selected, contains('EUR'));
    });
  });
}
