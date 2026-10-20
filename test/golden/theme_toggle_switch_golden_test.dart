import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/widgets/theme_toggle_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Golden testovi fiksiraju vizuelni izgled ključnih widgeta u svetloj i
/// tamnoj temi. Regeneracija: `flutter test --update-goldens test/golden/`.
///
/// Napomena: widget koristi isključivo Material ikone (Ahem/softverski
/// rasterizer u test okruženju), pa su goldeni deterministički.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Windows i Linux renderer daju AA šum od ~0.01% piksela na ivicama ikona.
  // Prag od 0.5% propušta taj šum, ali hvata prave regresije (promena ikona,
  // boja ili layouta menja redove piksela daleko iznad praga).
  goldenFileComparator = TolerantGoldenFileComparator(
    Uri.parse('test/golden/theme_toggle_switch_golden_test.dart'),
    maxDiffRatio: 0.005,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAndMatch(
    WidgetTester tester, {
    required ThemeMode mode,
    required Brightness brightness,
    required String goldenName,
    bool isIconOnly = false,
  }) async {
    final settings = AppSettingsProvider();
    await settings.setThemeMode(mode);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: ThemeToggleSwitch(isIconOnly: isIconOnly),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ThemeToggleSwitch),
      matchesGoldenFile('goldens/$goldenName.png'),
    );
  }

  testWidgets('Golden: ThemeToggleSwitch — svetla tema', (tester) async {
    await pumpAndMatch(
      tester,
      mode: ThemeMode.light,
      brightness: Brightness.light,
      goldenName: 'theme_toggle_light',
    );
  });

  testWidgets('Golden: ThemeToggleSwitch — tamna tema (thumb desno)',
      (tester) async {
    await pumpAndMatch(
      tester,
      mode: ThemeMode.dark,
      brightness: Brightness.dark,
      goldenName: 'theme_toggle_dark',
    );
  });

  testWidgets('Golden: ThemeToggleSwitch — ikonična varijanta u tamnoj temi',
      (tester) async {
    await pumpAndMatch(
      tester,
      mode: ThemeMode.dark,
      brightness: Brightness.dark,
      isIconOnly: true,
      goldenName: 'theme_toggle_icon_only_dark',
    );
  });
}

/// Golden komparator koji toleriše mali pixel diff (do [maxDiffRatio]) kako
/// golden testovi ne bi pali zbog razlika u rasterizaciji između platformi
/// (Windows/Linux). Iza praga se i dalje loguje kao failure.
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile, {required this.maxDiffRatio});

  final double maxDiffRatio;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) return true;

    final diffPercent = result.diffPercent;
    if (diffPercent <= maxDiffRatio) {
      debugPrint(
          'Golden (tolerisano): ${golden.path} — diff ${(diffPercent * 100).toStringAsFixed(3)}% <= ${(maxDiffRatio * 100).toStringAsFixed(2)}%');
      return true;
    }
    return super.compare(imageBytes, golden);
  }
}
