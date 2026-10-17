import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mleko/models/category.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/categories_provider.dart';
import 'package:mleko/providers/favorites_provider.dart';
import 'package:mleko/providers/location_provider.dart';
import 'package:mleko/screens/search_screen.dart';
import 'package:mleko/services/services.dart';

/// Snapshot jednog poziva getProductsPage radi provere prosleđenih filtera.
class _SearchPageCall {
  final String? category;
  final String? region;
  final bool? availableNow;
  final String? searchQuery;
  final ProductSort sort;
  final int limit;
  final int offset;

  _SearchPageCall({
    required this.category,
    required this.region,
    required this.availableNow,
    required this.searchQuery,
    required this.sort,
    required this.limit,
    required this.offset,
  });
}

class _MockProductsService implements ProductsService {
  /// Funkcija koja mapira (offset, filteri) -> (items, hasMore).
  final List<ProductModel> Function(_SearchPageCall call) onPage;

  final List<_SearchPageCall> calls = [];

  _MockProductsService({required this.onPage});

  @override
  Future<
      ({
        List<ProductModel> items,
        bool hasMore,
        Map<String, int> salesCounts,
        Map<String, ({double avg, int count})> ratings
      })> getProductsPage({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    String? searchQuery,
    String? excludeSellerId,
    ProductSort sort = ProductSort.dateDesc,
    int limit = 20,
    int offset = 0,
  }) async {
    final call = _SearchPageCall(
      category: category,
      region: region,
      availableNow: availableNow,
      searchQuery: searchQuery,
      sort: sort,
      limit: limit,
      offset: offset,
    );
    calls.add(call);
    final items = onPage(call);
    final hasMore = items.length > limit;
    return (
      items: items.length > limit ? items.sublist(0, limit) : items,
      hasMore: hasMore,
      salesCounts: <String, int>{},
      ratings: <String, ({double avg, int count})>{},
    );
  }

  @override
  Future<Map<String, int>> getCategoryCounts({
    required List<String> categoryNames,
    double? minPrice,
    double? maxPrice,
    String? region,
    bool? availableNow,
    String? searchQuery,
    String? excludeSellerId,
  }) async =>
      const {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockOrdersService implements OrdersService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSupabaseService implements SupabaseService {
  @override
  Future<List<Category>> getAllCategories() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductModel _product(int i) => ProductModel(
      id: 'prod-$i',
      sellerId: 'seller-1',
      category: 'Mlečni proizvodi',
      name: 'Testni Sir $i',
      pricePerKg: 800 + i.toDouble(),
      unitType: ProductModel.unitKg,
      minOrderKg: 1,
      orderStep: 0.5,
      availableKg: 20,
      availableNow: true,
      description: 'Testni proizvod $i',
      imageUrls: const [],
      pickupOptions: const [],
      location: 'Valjevo',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchScreen', () {
    late _MockProductsService mockProductsService;
    late AppState appState;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'mleko_search_history': ['med', 'sir'],
      });
      ProductCacheService.clearMemoryCache();
      mockProductsService = _MockProductsService(onPage: (call) {
        // Podrazumevano: prva stranica sa dva proizvoda, bez više stranica.
        return call.offset == 0 ? [_product(1), _product(2)] : const [];
      });
      appState = AppState(
        ordersService: _MockOrdersService(),
        connectivityService: ConnectivityService(initialOnline: true),
      );
    });

    Widget createTestApp({SearchScreen? screen}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<CategoriesProvider>.value(
            value: CategoriesProvider(service: _MockSupabaseService()),
          ),
          ChangeNotifierProvider<FavoritesProvider>.value(
            value: FavoritesProvider(),
          ),
          ChangeNotifierProvider<LocationProvider>.value(
            value: LocationProvider(),
          ),
          Provider<ProductsService>.value(value: mockProductsService),
        ],
        child: MaterialApp(home: screen ?? const SearchScreen()),
      );
    }

    testWidgets('renders products from first page load', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());

      // Prva stranica se učitava u post-frame callback-u; ispumpaj frame-ove.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Testni Sir 1'), findsOneWidget);
      expect(find.text('Testni Sir 2'), findsOneWidget);

      // Prvi poziv: bez filtera, offset 0, limit = productsPageSize (20)
      expect(mockProductsService.calls.length, greaterThanOrEqualTo(1));
      final first = mockProductsService.calls.first;
      expect(first.offset, equals(0));
      expect(first.limit, equals(20));
      expect(first.category, isNull);
      expect(first.searchQuery, isNull);
      expect(first.sort, equals(ProductSort.dateDesc));
    });

    testWidgets('initialCategory is forwarded to the products service',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(
        screen: const SearchScreen(initialCategory: 'Mlečni proizvodi'),
      ));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final first = mockProductsService.calls.first;
      expect(first.category, equals('Mlečni proizvodi'));
    });

    testWidgets('typing a query debounces and searches the service',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final callsBefore = mockProductsService.calls.length;

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'sir');
      await tester.pump(const Duration(milliseconds: 100));

      // Pre debounce isteka ne sme biti novog upita
      expect(mockProductsService.calls.length, equals(callsBefore));

      // Debounce od 300ms -> novi upit sa pretrazivanim pojmom
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(mockProductsService.calls.length, greaterThan(callsBefore));
      final last = mockProductsService.calls.last;
      expect(last.searchQuery, equals('sir'));
    });

    testWidgets('shows empty state when the search returns no products',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockProductsService = _MockProductsService(onPage: (call) => const []);

      await tester.pumpWidget(createTestApp());
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Ništa nismo pronašli'), findsOneWidget);
      expect(find.text('Pogledaj sve proizvode'), findsOneWidget);
    });

  });
}
