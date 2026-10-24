import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/providers/categories_provider.dart';
import 'package:mleko/screens/categories_screen.dart';
import 'package:mleko/widgets/category_icon.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CategoriesScreen renders accessible CategoryIcon for section headers instead of raw emoji', (tester) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final catProvider = CategoriesProvider()
      ..setCategoriesForTesting([
      const Category(
        id: 'cat-1',
        name: 'Mlečni proizvodi',
        slug: 'mlecni-proizvodi',
        section: 'hrana',
        icon: 'restaurant',
        order: 1,
      ),
      const Category(
        id: 'cat-2',
        name: 'Brašno i žitarice',
        slug: 'brasno-zitarice',
        section: 'osnove',
        icon: 'agriculture',
        order: 2,
      ),
      const Category(
        id: 'cat-3',
        name: 'Suhomesnato i čvarci',
        slug: 'suhomesnato',
        section: 'specijaliteti',
        icon: 'sunka',
        order: 3,
      ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoriesProvider>.value(value: catProvider),
        ],
        child: const MaterialApp(
          home: CategoriesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify CategoryIcon is used for section headers
    expect(find.byType(CategoryIcon), findsWidgets);
    expect(find.text('Hrana'), findsOneWidget);
    expect(find.text('Osnove za kuhinju'), findsOneWidget);
    expect(find.text('Specijaliteti'), findsOneWidget);

    // Verify raw emojis are not used in section headers
    expect(find.text('🥛'), findsNothing);
    expect(find.text('🌾'), findsNothing);
    expect(find.text('🍲'), findsNothing);
  });
}
