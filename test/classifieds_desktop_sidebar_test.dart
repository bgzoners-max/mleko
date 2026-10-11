import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/services/classifieds/classified_subscriptions_service.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';
import 'package:mleko/widgets/classifieds/classifieds_desktop_sidebar.dart';
import 'package:provider/provider.dart';

class MockClassifiedsService implements ClassifiedsService {
  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories({bool allowExpired = true}) async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories({bool forceRefresh = false}) async => [
        const ClassifiedCategoryModel(
          id: 'zivotinje',
          name: 'Domaće životinje',
          iconName: 'pets',
          adCount: 42,
          subcategories: [
            ClassifiedCategoryModel(
              id: 'krave',
              name: 'Krave i junad',
              iconName: 'pets',
              adCount: 15,
            ),
          ],
        ),
        const ClassifiedCategoryModel(
          id: 'mehanizacija',
          name: 'Mehanizacija',
          iconName: 'agriculture',
          adCount: 20,
        ),
      ];

  @override
  Future<Map<String, int>> getCategoryAdCounts() async => {'zivotinje': 42, 'mehanizacija': 20};

  @override
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    List<String>? cities,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    Map<String, dynamic>? attributeFilters,
    bool? onlyFeatured,
    bool? onlyUrgent,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
  }) async =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClassifiedsProvider provider;

  setUp(() {
    provider = ClassifiedsProvider(
      service: MockClassifiedsService(),
      subscriptionService: ClassifiedSubscriptionsService(),
    );
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider<ClassifiedsProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 300,
              child: ClassifiedsDesktopSidebar(
                classifieds: provider,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ClassifiedsDesktopSidebar renders header, price and filter sections', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Filteri'), findsOneWidget);
    expect(find.text('KATEGORIJE'), findsOneWidget);
    expect(find.text('CENA (€)'), findsOneWidget);
    expect(find.text('LOKACIJA'), findsOneWidget);
    expect(find.text('STANJE PREDMETA'), findsOneWidget);
    expect(find.text('OGLAŠIVAČ'), findsOneWidget);
    expect(find.text('SPECIJALNO'), findsOneWidget);
  });

  testWidgets('ClassifiedsDesktopSidebar quick price pill updates provider price range', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Tap quick price pill '< 50 €'
    final quickPill = find.text('< 50 €');
    expect(quickPill, findsOneWidget);
    await tester.tap(quickPill);
    await tester.pumpAndSettle();

    expect(provider.minPrice, isNull);
    expect(provider.maxPrice, equals(50.0));
  });

  testWidgets('ClassifiedsDesktopSidebar seller type selection updates provider', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final individualOption = find.text('Fizičko lice');
    expect(individualOption, findsOneWidget);
    await tester.ensureVisible(individualOption);
    await tester.pumpAndSettle();
    await tester.tap(individualOption);
    await tester.pumpAndSettle();

    expect(provider.selectedSellerType, equals('individual'));
  });

  testWidgets('ClassifiedsDesktopSidebar condition selection and reset all works', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final novoOption = find.text('Novo nekorišćeno');
    expect(novoOption, findsOneWidget);
    await tester.ensureVisible(novoOption);
    await tester.pumpAndSettle();
    await tester.tap(novoOption);
    await tester.pumpAndSettle();

    expect(provider.selectedCondition, equals('new'));

    // When filtered, 'Poništi sve' appears in the header
    final resetAll = find.text('Poništi sve');
    expect(resetAll, findsOneWidget);
    await tester.ensureVisible(resetAll);
    await tester.pumpAndSettle();
    await tester.tap(resetAll);
    await tester.pumpAndSettle();

    expect(provider.selectedCondition, isNull);
    expect(provider.minPrice, isNull);
    expect(provider.maxPrice, isNull);
  });

  testWidgets('ClassifiedsSidebarCategoryTree displays icons for all categories in sidebar', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Verify categories header exists
    expect(find.text('KATEGORIJE'), findsOneWidget);

    // Initial fallback categories include Poljoprivreda and Vozila with their respective icons
    expect(find.text('Poljoprivreda'), findsOneWidget);
    expect(find.text('Vozila'), findsOneWidget);
    expect(find.byIcon(Icons.agriculture), findsOneWidget);
    expect(find.byIcon(Icons.directions_car), findsOneWidget);

    // Load categories from service
    await provider.loadCategories();
    await tester.pumpAndSettle();

    expect(find.text('Domaće životinje'), findsOneWidget);
    expect(find.text('Mehanizacija'), findsOneWidget);
    expect(find.byIcon(Icons.pets), findsOneWidget);
    expect(find.byIcon(Icons.agriculture), findsOneWidget);

    // Tap on category with subcategories to check active category icon rendering
    final zivotinjeTile = find.text('Domaće životinje');
    await tester.tap(zivotinjeTile);
    await tester.pumpAndSettle();

    expect(provider.selectedCategoryId, equals('zivotinje'));
    expect(find.text('Sve kategorije'), findsOneWidget);
    expect(find.text('Krave i junad'), findsOneWidget);

    // Active category container renders with category icon
    expect(find.byIcon(Icons.pets), findsWidgets);
  });
}
