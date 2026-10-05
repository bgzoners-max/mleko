import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/widgets/home/desktop_hero_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required Widget child,
    double screenWidth = 1440,
    double screenHeight = 900,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(screenWidth, screenHeight),
        ),
        child: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  testWidgets('DesktopHeroBanner renders headline, subtitle, eyebrow and trust badges',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        child: const DesktopHeroBanner(),
      ),
    );
    await tester.pumpAndSettle();

    // Eyebrow badge
    expect(
      find.text('100% PROVERENA DOMAĆA HRANA I GAZDINSTVA'),
      findsOneWidget,
    );

    // Headline & Subtitle
    expect(
      find.text('Direktno sa srpskih gazdinstava na vašu trpezu'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Pravi ukusi sela, bez industrijskih posrednika'),
      findsOneWidget,
    );

    // 3 Trust Pillars
    expect(find.text('100% Prirodno & Domaće'), findsOneWidget);
    expect(find.text('Direktno od Proizvođača'), findsOneWidget);
    expect(find.text('Dostava ili Lično Preuzimanje'), findsOneWidget);

    // CTA buttons
    expect(find.text('Istraži ponudu hrane'), findsOneWidget);
    expect(find.text('Mali oglasi & mehanizacija'), findsOneWidget);
    expect(find.text('Interaktivna mapa gazdinstava'), findsOneWidget);

    // Quick tags
    expect(find.text('Popularno:'), findsOneWidget);
    expect(find.text('Sir & Kajmak'), findsOneWidget);
    expect(find.text('Domaći med'), findsOneWidget);
  });

  testWidgets('DesktopHeroBanner triggers callbacks on buttons and tags',
      (tester) async {
    bool exploredFood = false;
    bool exploredClassifieds = false;
    String? selectedTag;

    await tester.pumpWidget(
      buildTestWidget(
        child: DesktopHeroBanner(
          onExploreFood: () => exploredFood = true,
          onExploreClassifieds: () => exploredClassifieds = true,
          onSearchTag: (tag) => selectedTag = tag,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap food button
    await tester.tap(find.text('Istraži ponudu hrane'));
    await tester.pumpAndSettle();
    expect(exploredFood, isTrue);

    // Tap classifieds button
    await tester.tap(find.text('Mali oglasi & mehanizacija'));
    await tester.pumpAndSettle();
    expect(exploredClassifieds, isTrue);

    // Tap a popular tag
    await tester.tap(find.text('Sir & Kajmak'));
    await tester.pumpAndSettle();
    expect(selectedTag, 'Sir & Kajmak');
  });

  testWidgets('DesktopHeroBanner adapts nicely on compact desktop (width 1100)',
      (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        screenWidth: 1100,
        child: const DesktopHeroBanner(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Direktno sa srpskih gazdinstava na vašu trpezu'),
      findsOneWidget,
    );
    expect(find.text('100% Prirodno & Domaće'), findsOneWidget);
  });
}
