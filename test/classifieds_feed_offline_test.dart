import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/screens/classifieds/classifieds_feed_screen.dart';
import 'package:mleko/services/classifieds/classified_subscriptions_service.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';
import 'package:mleko/services/core/connectivity_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:provider/provider.dart';

class _OfflineMockClassifiedsService implements ClassifiedsService {
  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories({bool allowExpired = true}) async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories({bool forceRefresh = false}) async => [];

  @override
  Future<Map<String, int>> getCategoryAdCounts() async => {};

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
  }) async {
    throw Exception('SocketException: Failed host lookup: api.supabase.co');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ClassifiedsFeedScreen renders offline empty state with wifi_off icon on mobile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final connectivity = ConnectivityService(
      reachabilityChecker: () async => false,
      initialOnline: false,
    );

    final appState = AppState(
      ordersService: OrdersService(),
      connectivityService: connectivity,
    );

    final classifiedsProvider = ClassifiedsProvider(
      service: _OfflineMockClassifiedsService(),
      subscriptionService: ClassifiedSubscriptionsService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ClassifiedsProvider>.value(value: classifiedsProvider),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: const MaterialApp(
          home: ClassifiedsFeedScreen(isEmbedded: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify offline empty state is rendered
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Nema internet veze'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    connectivity.dispose();
  });

  testWidgets('ClassifiedsFeedScreen renders offline empty state with wifi_off icon on desktop', (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final connectivity = ConnectivityService(
      reachabilityChecker: () async => false,
      initialOnline: false,
    );

    final appState = AppState(
      ordersService: OrdersService(),
      connectivityService: connectivity,
    );

    final classifiedsProvider = ClassifiedsProvider(
      service: _OfflineMockClassifiedsService(),
      subscriptionService: ClassifiedSubscriptionsService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ClassifiedsProvider>.value(value: classifiedsProvider),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: const MaterialApp(
          home: ClassifiedsFeedScreen(isEmbedded: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify offline empty state is rendered on desktop view
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Nema internet veze'), findsOneWidget);
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    connectivity.dispose();
  });
}
