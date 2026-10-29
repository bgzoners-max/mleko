import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_seller_type_section.dart';

void main() {
  Widget buildSection({
    String sellerType = 'individual',
    ValueChanged<String>? onChanged,
    bool initialExpanded = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ClassifiedSellerTypeSection(
            theme: ThemeData.light(),
            colorScheme: const ColorScheme.light(),
            sellerType: sellerType,
            onChanged: onChanged ?? (_) {},
            initialExpanded: initialExpanded,
          ),
        ),
      ),
    );
  }

  group('ClassifiedSellerTypeSection shrink and expand mode', () {
    testWidgets('Starts in shrink mode by default with arrow down and no subtitles', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      // Titles are visible
      expect(find.text('Fizičko lice'), findsOneWidget);
      expect(find.text('Pravno lice / Trgovac'), findsOneWidget);

      // Arrow down is in the center, arrow up is not
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
      expect(find.text('Objašnjenje'), findsOneWidget);

      // Subtitles and legal disclaimer are shrunk / hidden
      expect(find.textContaining('Prodaja ličnih i polovnih stvari'), findsNothing);
      expect(find.textContaining('Preduzetnik, firma, registrovana radnja'), findsNothing);
      expect(find.textContaining('Na kupovinu od fizičkog lica ne primenjuju se'), findsNothing);
    });

    testWidgets('Expands when centered arrow toggle is tapped, showing subtitles and disclaimer', (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pumpAndSettle();

      // Tap centered toggle
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();

      // Arrow up is now displayed
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.text('Sakrij objašnjenje'), findsOneWidget);

      // Subtitles and legal disclaimer are visible
      expect(find.textContaining('Prodaja ličnih i polovnih stvari'), findsOneWidget);
      expect(find.textContaining('Preduzetnik, firma, registrovana radnja'), findsOneWidget);
      expect(find.textContaining('Na kupovinu od fizičkog lica ne primenjuju se'), findsOneWidget);

      // Tap again to shrink
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();

      // Returns to shrink mode
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNothing);
      expect(find.textContaining('Prodaja ličnih i polovnih stvari'), findsNothing);
      expect(find.textContaining('Na kupovinu od fizičkog lica ne primenjuju se'), findsNothing);
    });

    testWidgets('Allows selecting seller type in both shrink and expanded modes', (tester) async {
      String? selected;
      await tester.pumpWidget(buildSection(
        onChanged: (val) => selected = val,
      ));
      await tester.pumpAndSettle();

      // Select business in shrink mode
      await tester.tap(find.text('Pravno lice / Trgovac'));
      await tester.pumpAndSettle();
      expect(selected, equals('business'));

      // Expand
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();

      // Select individual in expanded mode
      await tester.tap(find.text('Fizičko lice'));
      await tester.pumpAndSettle();
      expect(selected, equals('individual'));
    });
  });
}
