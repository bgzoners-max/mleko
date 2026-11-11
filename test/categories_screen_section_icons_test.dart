import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/category.dart';
import 'package:mleko/providers/categories_provider.dart';
import 'package:mleko/screens/categories_screen.dart';
import 'package:mleko/screens/child_categories_screen.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/category_icon.dart';
import 'package:mleko/widgets/not_found_screen.dart';
import 'package:provider/provider.dart';

class _MockSupabaseService implements SupabaseService {
  @override
  Future<List<Category>> getAllCategories() async => const [];

  @override
  Future<List<Category>> getChildCategories(String parentId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockProductsService implements ProductsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CategoriesScreen renders accessible CategoryIcon for section headers instead of raw emoji', (tester) async {
    tester.view.physicalSize = const Size(1000, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final catProvider = CategoriesProvider(service: _MockSupabaseService())
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

  testWidgets('CategoriesScreen opens ChildCategoriesScreen for initialCategorySlug deep-link',
      (tester) async {
    final catProvider = CategoriesProvider(service: _MockSupabaseService())
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
          id: 'cat-child-1',
          name: 'Beli sir',
          slug: 'beli-sir',
          section: 'hrana',
          parentId: 'cat-1',
          order: 10,
        ),
      ]);

    expect(catProvider.findBySlugOrId('mlecni-proizvodi')?.id, equals('cat-1'));
    expect(catProvider.findBySlugOrId('cat-1')?.slug, equals('mlecni-proizvodi'));
    expect(catProvider.findBySlugOrId('nepostojeca'), isNull);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CategoriesProvider>.value(value: catProvider),
          Provider<ProductsService>.value(value: _MockProductsService()),
        ],
        child: const MaterialApp(
          home: CategoriesScreen(initialCategorySlug: 'mlecni-proizvodi'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ChildCategoriesScreen), findsOneWidget);
    expect(find.text('Mlečni proizvodi'), findsWidgets);
  });

  testWidgets('NotFoundScreen renders clear 404 UI and home CTA', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotFoundScreen(requestedPath: '/nepostojeca-strana'),
      ),
    );

    expect(find.text('Stranica nije pronađena'), findsOneWidget);
    expect(find.text('Početna stranica'), findsOneWidget);
  });
}
