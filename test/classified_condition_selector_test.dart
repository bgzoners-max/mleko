import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_condition_selector.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_price_section.dart';

void main() {
  group('ClassifiedConditionSelector', () {
    testWidgets('renders SizedBox.shrink when isConditionApplicable is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedConditionSelector(
              isConditionApplicable: false,
              condition: 'used',
              sellerType: 'individual',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SegmentedButton<String>), findsNothing);
      expect(find.text('Stanje predmeta *'), findsNothing);
    });

    testWidgets('renders individual segments when sellerType is individual',
        (tester) async {
      String? selectedCondition = 'used';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ClassifiedConditionSelector(
                  isConditionApplicable: true,
                  condition: selectedCondition ?? 'used',
                  sellerType: 'individual',
                  onChanged: (val) {
                    setState(() => selectedCondition = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Stanje predmeta *'), findsOneWidget);
      expect(find.text('Korišćeno (polovno)'), findsOneWidget);
      expect(find.text('Nekorišćeno / Kao novo'), findsOneWidget);

      final selectorFinder = find.byType(SegmentedButton<String>);
      expect(selectorFinder, findsOneWidget);
      final selectorWidget =
          tester.widget<SegmentedButton<String>>(selectorFinder);
      expect(selectorWidget.selected, contains('used'));

      // Tap 'Nekorišćeno / Kao novo' to switch to 'new'
      await tester.tap(find.text('Nekorišćeno / Kao novo'));
      await tester.pumpAndSettle();

      expect(selectedCondition, 'new');
    });

    testWidgets('renders business segments when sellerType is business',
        (tester) async {
      String? selectedCondition = 'new';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ClassifiedConditionSelector(
                  isConditionApplicable: true,
                  condition: selectedCondition ?? 'new',
                  sellerType: 'business',
                  onChanged: (val) {
                    setState(() => selectedCondition = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Stanje predmeta *'), findsOneWidget);
      expect(find.text('Novo (sa garancijom / računom)'), findsOneWidget);
      expect(find.text('Polovno / Kao novo'), findsOneWidget);

      final selectorFinder = find.byType(SegmentedButton<String>);
      expect(selectorFinder, findsOneWidget);
      final selectorWidget =
          tester.widget<SegmentedButton<String>>(selectorFinder);
      expect(selectorWidget.selected, contains('new'));

      // Tap 'Polovno / Kao novo' to switch to 'used'
      await tester.tap(find.text('Polovno / Kao novo'));
      await tester.pumpAndSettle();

      expect(selectedCondition, 'used');
    });
  });

  group('ClassifiedPriceSection with condition row', () {
    testWidgets(
        'renders condition in its own row and price inputs below on desktop',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final priceController = TextEditingController(text: '3000');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassifiedPriceSection(
              isConditionApplicable: true,
              condition: 'used',
              sellerType: 'individual',
              priceType: 'fixed',
              currency: 'RSD',
              priceController: priceController,
              onPriceTypeChanged: (_) {},
              onCurrencyChanged: (_) {},
              onConditionChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ClassifiedConditionSelector), findsOneWidget);
      expect(find.text('Stanje predmeta *'), findsOneWidget);
      expect(find.text('Način formiranja cene'), findsOneWidget);
      expect(find.text('Cena *'), findsOneWidget);
      expect(find.text('RSD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);

      // Verify two SegmentedButton widgets exist (one for condition, one for currency)
      expect(find.byType(SegmentedButton<String>), findsNWidgets(2));
    });
  });
}
