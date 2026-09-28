import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/providers/app_settings_provider.dart';
import 'package:mleko/widgets/theme_toggle_switch.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required Widget child,
    required AppSettingsProvider settings,
    Brightness brightness = Brightness.light,
  }) {
    return ChangeNotifierProvider<AppSettingsProvider>.value(
      value: settings,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
  }

  testWidgets('ThemeToggleSwitch renders light colors and white thumb in dark mode',
      (tester) async {
    final settings = AppSettingsProvider();
    await settings.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        brightness: Brightness.dark,
        child: const ThemeToggleSwitch(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify track container has light color (0xFFE2E8F0)
    final animatedContainerFinder = find.byType(AnimatedContainer);
    expect(animatedContainerFinder, findsOneWidget);
    final container = tester.widget<AnimatedContainer>(animatedContainerFinder);
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFE2E8F0));

    // Verify thumb is white
    final thumbFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.decoration as BoxDecoration).color == Colors.white,
    );
    expect(thumbFinder, findsOneWidget);

    // Verify icons exist (sun and moon)
    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
    expect(find.byIcon(Icons.nightlight_round), findsWidgets);
  });

  testWidgets('ThemeToggleSwitch toggles theme on tap', (tester) async {
    final settings = AppSettingsProvider();
    await settings.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        brightness: Brightness.dark,
        child: const ThemeToggleSwitch(),
      ),
    );
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.dark);

    await tester.tap(find.byType(ThemeToggleSwitch));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.light);
  });

  testWidgets('ThemeToggleSwitch icon-only mode toggles theme on tap',
      (tester) async {
    final settings = AppSettingsProvider();
    await settings.setThemeMode(ThemeMode.dark);

    await tester.pumpWidget(
      buildTestWidget(
        settings: settings,
        brightness: Brightness.dark,
        child: const ThemeToggleSwitch(isIconOnly: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(settings.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
