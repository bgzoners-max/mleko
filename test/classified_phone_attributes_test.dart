import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/lucide_icons.dart';
import 'package:mleko/utils/classified_attributes_engine.dart';
import 'package:mleko/widgets/classifieds/add_edit/classified_attributes_section.dart';

void main() {
  group('Phone Attributes & Micro Flat Lucide Icons', () {
    test('phoneAttributes in ClassifiedAttributesEngine use Lucide icons', () {
      final simFree = ClassifiedAttributesEngine.findAttributeByKey('sim_free');
      expect(simFree, isNotNull);
      expect(simFree!.icon, equals(LucideIcons.unlock));

      final simSingle = ClassifiedAttributesEngine.findAttributeByKey('sim_single');
      expect(simSingle, isNotNull);
      expect(simSingle!.icon, equals(LucideIcons.smartphone));

      final net5g = ClassifiedAttributesEngine.findAttributeByKey('net_5g');
      expect(net5g, isNotNull);
      expect(net5g!.icon, equals(LucideIcons.signal));

      final warranty = ClassifiedAttributesEngine.findAttributeByKey('warranty_official');
      expect(warranty, isNotNull);
      expect(warranty!.icon, equals(LucideIcons.badgeCheck));

      final accBox = ClassifiedAttributesEngine.findAttributeByKey('acc_box');
      expect(accBox, isNotNull);
      expect(accBox!.icon, equals(LucideIcons.package));
    });

    testWidgets('ClassifiedAttributesSection renders phone checkbox chips with micro flat icons',
        (tester) async {
      final attributes = ClassifiedAttributesEngine.phoneAttributes;
      final currentAttributes = <String, dynamic>{
        'sim_free': true,
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClassifiedAttributesSection(
                theme: ThemeData.light(),
                colorScheme: const ColorScheme.light(primary: Colors.blue),
                attributes: attributes,
                currentAttributes: currentAttributes,
                onChanged: (key, value) {
                  currentAttributes[key] = value;
                },
              ),
            ),
          ),
        ),
      );

      // Verify section titles
      expect(find.text('Karakteristike predmeta'), findsOneWidget);
      expect(find.text('SIM kartica i povezivanje'), findsOneWidget);
      expect(find.text('Garancija'), findsOneWidget);
      expect(find.text('Prateća oprema'), findsOneWidget);

      // Verify micro flat Lucide icons are present in the widget tree
      expect(find.byIcon(LucideIcons.unlock), findsOneWidget);
      expect(find.byIcon(LucideIcons.smartphone), findsOneWidget);
      expect(find.byIcon(LucideIcons.layers), findsOneWidget);
      expect(find.byIcon(LucideIcons.nfc), findsOneWidget);
      expect(find.byIcon(LucideIcons.signal), findsOneWidget);
      expect(find.byIcon(LucideIcons.badgeCheck), findsOneWidget);
      expect(find.byIcon(LucideIcons.package), findsOneWidget);
      expect(find.byIcon(LucideIcons.plug), findsOneWidget);
      expect(find.byIcon(LucideIcons.usb), findsOneWidget);

      // Verify checkbox labels
      expect(find.text('SIM Free'), findsOneWidget);
      expect(find.text('1x SIM slot'), findsOneWidget);
      expect(find.text('eSIM'), findsOneWidget);
      expect(find.text('5G'), findsOneWidget);
      expect(find.text('Originalna kutija'), findsOneWidget);
      expect(find.text('Punjač'), findsOneWidget);

      // Tapping on a chip triggers onChanged callback
      await tester.tap(find.text('5G'));
      expect(currentAttributes['net_5g'], isTrue);
    });
  });
}
