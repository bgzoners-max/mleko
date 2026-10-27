import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/constants/serbian_postal_codes.dart';
import 'package:mleko/widgets/common/postal_code_autocomplete_field.dart';

void main() {
  group('SerbianPostalCodes', () {
    test('all contains 2043 entries with valid 5-digit codes and unique (code, city) pairs', () {
      expect(SerbianPostalCodes.all.length, 2043);
      final uniquePairs = <String>{};
      for (final entry in SerbianPostalCodes.all) {
        expect(RegExp(r'^\d{5}$').hasMatch(entry.code), isTrue);
        expect(entry.city.trim().isNotEmpty, isTrue);
        expect(
          uniquePairs.add('${entry.code}|${entry.city}'),
          isTrue,
          reason: 'Duplicate entry: ${entry.code} ${entry.city}',
        );
      }
    });

    test('has exactly 1248 unique primary post offices and one per postal code', () {
      final primaryCodes = <String>{};
      for (final entry in SerbianPostalCodes.all) {
        if (entry.isPrimary) {
          expect(
            primaryCodes.add(entry.code),
            isTrue,
            reason: 'Duplicate primary code: ${entry.code}',
          );
        }
      }
      expect(primaryCodes.length, 1248);
    });

    test('cityForCode resolves primary cities correctly and handles invalid codes', () {
      expect(SerbianPostalCodes.cityForCode('11000'), 'Beograd');
      expect(SerbianPostalCodes.cityForCode('11010'), 'Beograd Voždovac');
      expect(SerbianPostalCodes.cityForCode('11040'), 'Beograd (Savski Venac)');
      expect(SerbianPostalCodes.cityForCode('11102'), 'Beograd (Stari Grad)');
      expect(SerbianPostalCodes.cityForCode('11104'), 'Beograd (Vračar)');
      expect(SerbianPostalCodes.cityForCode('11215'), 'Slanci');
      expect(SerbianPostalCodes.cityForCode('21000'), 'Novi Sad');
      expect(SerbianPostalCodes.cityForCode('18000'), 'Niš');
      expect(SerbianPostalCodes.cityForCode('11300'), 'Smederevo');
      expect(SerbianPostalCodes.cityForCode('32000'), 'Čačak');
      expect(SerbianPostalCodes.cityForCode('34000'), 'Kragujevac');
      expect(SerbianPostalCodes.cityForCode('31250'), 'Bajina Bašta');
      expect(SerbianPostalCodes.cityForCode('11460'), 'Barajevo');
      expect(SerbianPostalCodes.cityForCode('17541'), 'Vranjska Banja');
      expect(SerbianPostalCodes.cityForCode('15214'), 'Debrc');
      expect(SerbianPostalCodes.cityForCode('22244'), 'Adaševci');
      expect(SerbianPostalCodes.cityForCode('38227'), 'Zvečan');
      expect(SerbianPostalCodes.cityForCode('99999'), isNull);
      expect(SerbianPostalCodes.cityForCode(''), isNull);
    });

    test('codeForCity resolves known cities and settlements diacritic-tolerantly', () {
      expect(SerbianPostalCodes.codeForCity('Beograd'), '11000');
      expect(SerbianPostalCodes.codeForCity('beograd'), '11000');
      expect(SerbianPostalCodes.codeForCity('Čačak'), '32000');
      expect(SerbianPostalCodes.codeForCity('cacak'), '32000');
      expect(SerbianPostalCodes.codeForCity('Niš'), '18000');
      expect(SerbianPostalCodes.codeForCity('nis'), '18000');
      expect(SerbianPostalCodes.codeForCity('Novi Sad'), '21000');
      expect(SerbianPostalCodes.codeForCity('Petrijevo'), '11300');
      expect(SerbianPostalCodes.codeForCity('petrijevo'), '11300');
      expect(SerbianPostalCodes.codeForCity('Berbatovo'), '18000');
      expect(SerbianPostalCodes.codeForCity('berbatovo'), '18000');
      expect(SerbianPostalCodes.codeForCity('Nepoznato Mesto'), isNull);
      expect(SerbianPostalCodes.codeForCity(''), isNull);
    });

    test('suggestions returns matches for numeric and text queries including villages', () {
      final numMatches = SerbianPostalCodes.suggestions('320');
      expect(numMatches.any((e) => e.code == '32000' && e.city == 'Čačak'), isTrue);

      final textMatches = SerbianPostalCodes.suggestions('cacak');
      expect(textMatches.any((e) => e.code == '32000' && e.city == 'Čačak'), isTrue);

      final diacriticMatches = SerbianPostalCodes.suggestions('čač');
      expect(diacriticMatches.any((e) => e.code == '32000' && e.city == 'Čačak'), isTrue);

      final villageMatches = SerbianPostalCodes.suggestions('petrijevo');
      expect(
        villageMatches.any((e) => e.code == '11300' && e.settlement == 'Petrijevo'),
        isTrue,
      );

      final nisVillageMatches = SerbianPostalCodes.suggestions('berbatovo');
      expect(
        nisVillageMatches.any((e) => e.code == '18000' && e.settlement == 'Berbatovo'),
        isTrue,
      );

      final savskiVenacMatches = SerbianPostalCodes.suggestions('savski venac');
      expect(
        savskiVenacMatches.any((e) => e.code == '11040'),
        isTrue,
      );

      expect(SerbianPostalCodes.suggestions(''), isEmpty);
      expect(SerbianPostalCodes.suggestions('   '), isEmpty);
    });
  });

  group('PostalCodeAutocompleteField', () {
    testWidgets('renders input and syncs with controller', (tester) async {
      final postalCtrl = TextEditingController(text: '11000');
      final cityCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeAutocompleteField(
              controller: postalCtrl,
              cityController: cityCtrl,
            ),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(postalCtrl.text, '11000');
      expect(find.byIcon(Icons.markunread_mailbox_outlined), findsOneWidget);
    });

    testWidgets('auto-fills city when 5 matching digits are typed', (tester) async {
      final postalCtrl = TextEditingController();
      final cityCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeAutocompleteField(
              controller: postalCtrl,
              cityController: cityCtrl,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '32000');
      await tester.pump();

      expect(postalCtrl.text, '32000');
      expect(cityCtrl.text, 'Čačak');
    });

    testWidgets('shows suggestions dropdown and updates on selection', (tester) async {
      final postalCtrl = TextEditingController();
      final cityCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostalCodeAutocompleteField(
              controller: postalCtrl,
              cityController: cityCtrl,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '320');
      await tester.pumpAndSettle();

      expect(find.text('Čačak'), findsOneWidget);

      await tester.tap(find.text('Čačak'));
      await tester.pumpAndSettle();

      expect(postalCtrl.text, '32000');
      expect(cityCtrl.text, 'Čačak');
    });

    testWidgets('dropdown options expand to at least 300px even in a narrow (120px) input container', (tester) async {
      final postalCtrl = TextEditingController();
      final cityCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 120,
                child: PostalCodeAutocompleteField(
                  controller: postalCtrl,
                  cityController: cityCtrl,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '11030');
      await tester.pumpAndSettle();

      // Find all options
      expect(find.text('Beograd Čukarica'), findsOneWidget);
      expect(find.text('Pećani (Beograd Čukarica)'), findsOneWidget);

      // Verify the ListView inside Material has width 300
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final dropdownContainer = sizedBoxes.firstWhere((w) => w.width == 300.0);
      expect(dropdownContainer.width, 300.0);

      // Tap on Pećani
      await tester.tap(find.text('Pećani (Beograd Čukarica)'));
      await tester.pumpAndSettle();

      expect(postalCtrl.text, '11030');
      expect(cityCtrl.text, 'Pećani (Beograd Čukarica)');
    });
  });
}
