import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/widgets/classifieds/add_edit/category_selection_modal.dart';

void main() {
  test('ClassifiedCategoryModel.fallbackCategories has full rich tree', () {
    final categories = ClassifiedCategoryModel.fallbackCategories;
    expect(categories.length, greaterThanOrEqualTo(16));

    final telefoni = categories.firstWhere((c) => c.id == 'telefoni');
    expect(telefoni.name, 'Mobilni telefoni i oprema');
    expect(telefoni.subcategories, isNotEmpty);

    final smartfoni = telefoni.subcategories.firstWhere((s) => s.id == 'smartfoni');
    expect(smartfoni.name, 'Mobilni telefoni (Smartfoni)');
    expect(smartfoni.subcategories, isNotEmpty);

    final brands = smartfoni.subcategories.map((b) => b.id).toList();
    expect(brands, containsAll(['iphone', 'samsung', 'xiaomi', 'smartfoni_ostalo']));

    final poljoprivreda = categories.firstWhere((c) => c.id == 'poljoprivreda');
    expect(poljoprivreda.name, 'Poljoprivreda i mehanizacija');
    expect(poljoprivreda.subcategories, isNotEmpty);

    final vozila = categories.firstWhere((c) => c.id == 'vozila');
    expect(vozila.name, 'Vozila i auto-moto');
    expect(vozila.subcategories, isNotEmpty);
  });

  testWidgets('CategorySelectionModal displays full tree and drills down into subcategories', (tester) async {
    CategorySelectionResult? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () async {
                  selectedResult = await CategorySelectionModal.show(
                    ctx,
                    ClassifiedCategoryModel.fallbackCategories,
                  );
                },
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // 1. Verify modal title and top level categories
    expect(find.text('Izaberi kategoriju'), findsOneWidget);
    expect(find.text('Poljoprivreda i mehanizacija'), findsOneWidget);
    expect(find.text('Vozila i auto-moto'), findsOneWidget);
    expect(find.text('Mobilni telefoni i oprema'), findsOneWidget);

    // Chevron is rendered because subcategories is not empty
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    // 2. Click on 'Mobilni telefoni i oprema'
    await tester.tap(find.text('Mobilni telefoni i oprema'));
    await tester.pumpAndSettle();

    // Verify drill-down into subcategories
    expect(find.text('Mobilni telefoni (Smartfoni)'), findsOneWidget);
    expect(find.text('Maske, futrole i zaštitna stakla'), findsOneWidget);
    expect(find.text('Punjači, kablovi i powerbank'), findsOneWidget);

    // 3. Click on 'Mobilni telefoni (Smartfoni)'
    await tester.tap(find.text('Mobilni telefoni (Smartfoni)'));
    await tester.pumpAndSettle();

    // Verify brands appear
    expect(find.text('Apple iPhone'), findsOneWidget);
    expect(find.text('Samsung Galaxy'), findsOneWidget);
    expect(find.text('Xiaomi i Redmi'), findsOneWidget);

    // 4. Select Apple iPhone
    await tester.tap(find.text('Apple iPhone'));
    await tester.pumpAndSettle();

    // Verify result
    expect(selectedResult, isNotNull);
    expect(selectedResult!.id, 'iphone');
    expect(selectedResult!.name, contains('iPhone'));
    expect(selectedResult!.breadcrumbs.length, 3);
    expect(selectedResult!.breadcrumbs[0].id, 'telefoni');
    expect(selectedResult!.breadcrumbs[1].id, 'smartfoni');
    expect(selectedResult!.breadcrumbs[2].id, 'iphone');
  });
}
