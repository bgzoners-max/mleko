import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mleko/models/seller_stats_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/services/services.dart';
import 'package:mleko/widgets/seller_profile/seller_farm_gallery_section.dart';
import 'package:mleko/widgets/seller_profile/seller_profile_header.dart';

class _MockAppState extends ChangeNotifier implements AppState {
  @override
  UserModel? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockReviewsService extends Fake implements ReviewsService {
  @override
  Future<SellerStatsModel> getSellerStats(String sellerId) async {
    return const SellerStatsModel(
      ordersCount: 8,
      avgRating: 4.9,
      reviewCount: 15,
    );
  }
}

void main() {
  const testSeller = UserModel(
    id: 'seller-1',
    role: UserRole.seller,
    displayName: 'Branislava Vuksa',
    farmName: 'Gazdinstvo Vuksa',
    location: 'Glogonj',
    isVerified: true,
    bpgMasked: '1234****',
  );

  group('SellerFarmGallerySection Tests', () {
    testWidgets('renders compact photo cards and count on mobile', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SellerFarmGallerySection(
                urls: [
                  'https://example.com/photo1.jpg',
                  'https://example.com/photo2.jpg',
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Galerija gazdinstva'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on desktop without overflow', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SellerFarmGallerySection(
                urls: [
                  'https://example.com/photo1.jpg',
                  'https://example.com/photo2.jpg',
                  'https://example.com/photo3.jpg',
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Galerija gazdinstva'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('SellerProfileHeader Tests', () {
    testWidgets('renders compact profile header on mobile', (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = _MockAppState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            Provider<ReviewsService>(create: (_) => _MockReviewsService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SellerProfileHeader(seller: testSeller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gazdinstvo Vuksa'), findsOneWidget);
      expect(find.text('Glogonj'), findsOneWidget);
      expect(find.text('BPG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders compact profile header on desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final appState = _MockAppState();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            Provider<ReviewsService>(create: (_) => _MockReviewsService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SellerProfileHeader(seller: testSeller),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gazdinstvo Vuksa'), findsOneWidget);
      expect(find.text('Glogonj'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
