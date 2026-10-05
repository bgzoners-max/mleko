import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/screens/classifieds/classifieds_feed_screen.dart';
import 'package:mleko/services/classifieds/classified_subscriptions_service.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:mleko/widgets/classifieds/classifieds_desktop_sidebar.dart';
import 'package:provider/provider.dart';

class MockClassifiedsService implements ClassifiedsService {
  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories() async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories() async => [
        const ClassifiedCategoryModel(
          id: 'zivotinje',
          name: 'Domaće životinje',
          iconName: 'pets',
          adCount: 1,
        ),
      ];

  @override
  Future<Map<String, int>> getCategoryAdCounts() async => {'zivotinje': 1};

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
      [
        ClassifiedAdModel(
          id: 'ad-1',
          userId: 'user-1',
          categoryId: 'zivotinje',
          title: 'Domaća krava simentalka',
          description: 'Mirna i zdrava krava sa domaćeg gazdinstva.',
          price: 1500,
          currency: 'EUR',
          city: 'Čačak',
          images: const ['https://example.com/cow.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          phonePublic: true,
          sellerName: 'Milan Jovanović',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ClassifiedsFeedScreen renders desktop 2-column layout on desktop width (1280px)', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = ClassifiedsProvider(
      service: MockClassifiedsService(),
      subscriptionService: ClassifiedSubscriptionsService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ClassifiedsProvider>.value(value: provider),
          ChangeNotifierProvider<AppState>(create: (_) => AppState(ordersService: OrdersService())),
        ],
        child: const MaterialApp(
          home: ClassifiedsFeedScreen(isEmbedded: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify ClassifiedsDesktopSidebar is present in the tree
    expect(find.byType(ClassifiedsDesktopSidebar), findsOneWidget);

    // Verify ad card is rendered in the grid
    expect(find.text('Domaća krava simentalka'), findsOneWidget);

    // Verify result counter
    expect(find.text('Pronađeno 1 oglasa'), findsOneWidget);
  });
}
