import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/widgets/classifieds/detail/classified_detail_content.dart';
import 'package:mleko/widgets/classifieds/detail/classified_image_gallery.dart';
import 'package:mleko/widgets/classifieds/detail/classified_main_info_card.dart';

ClassifiedAdModel _sampleAd({
  String id = 'ad-1',
  double price = 999,
  String currency = 'EUR',
  String priceType = 'fixed',
  String sellerType = 'private',
  int viewsCount = 42,
  int favoritesCount = 5,
  List<String> images = const [],
}) {
  return ClassifiedAdModel(
    id: id,
    userId: 'seller-1',
    categoryId: 'traktori',
    categoryName: 'Traktori i priključci',
    title: '5x120 20 felne',
    description: 'Odlično očuvane felne, moguće lično preuzimanje.',
    price: price,
    currency: currency,
    priceType: priceType,
    condition: 'used',
    city: 'Šid',
    images: images,
    phonePublic: true,
    status: 'active',
    sellerType: sellerType,
    viewsCount: viewsCount,
    favoritesCount: favoritesCount,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    sellerName: 'Vlado',
  );
}

void main() {
  group('ClassifiedAdModel favorites & currency conversion', () {
    test('parses favorites_count from JSON and preserves it in copyWith', () {
      final ad = ClassifiedAdModel.fromJson({
        'id': 'ad-json',
        'user_id': 'u-1',
        'category_id': 'cat-1',
        'title': 'Test oglas',
        'description': 'Opis',
        'price': 1000,
        'currency': 'EUR',
        'price_type': 'fixed',
        'city': 'Šid',
        'status': 'active',
        'views_count': 15,
        'favorites_count': 7,
        'created_at': '2026-11-20T10:00:00Z',
        'updated_at': '2026-11-20T10:00:00Z',
      });

      expect(ad.favoritesCount, 7);
      expect(ad.copyWith(favoritesCount: 8).favoritesCount, 8);
      expect(ad.copyWith(title: 'Novi').favoritesCount, 7);
    });

    test('computes EUR ↔ RSD secondary currency estimate accurately', () {
      final eurAd = _sampleAd(price: 100, currency: 'EUR');
      expect(eurAd.secondaryCurrencyEstimate, '~11.720 RSD');

      final rsdAd = _sampleAd(price: 11720, currency: 'RSD');
      expect(rsdAd.secondaryCurrencyEstimate, '~100 €');

      final freeAd = _sampleAd(price: 0, priceType: 'free');
      expect(freeAd.secondaryCurrencyEstimate, isNull);

      final callAd = _sampleAd(price: 0, priceType: 'call');
      expect(callAd.secondaryCurrencyEstimate, isNull);
    });
  });

  group('ClassifiedMainInfoCard', () {
    testWidgets(
      'renders Prati toggle, EUR→RSD estimate, stats row and fires callback',
      (tester) async {
        final ad = _sampleAd(
          price: 999,
          currency: 'EUR',
          viewsCount: 19,
          favoritesCount: 4,
        );
        var toggled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  return ClassifiedMainInfoCard(
                    ad: ad,
                    theme: theme,
                    colorScheme: theme.colorScheme,
                    isDark: false,
                    isOwner: false,
                    hasPhone: true,
                    isWide: true,
                    isFavorited: false,
                    favoritesCount: 4,
                    onToggleFavorite: () => toggled = true,
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('5x120 20 felne'), findsOneWidget);
        expect(find.text('Prati'), findsOneWidget);
        expect(find.text('~117.083 RSD'), findsOneWidget);
        expect(find.text('19'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);

        await tester.tap(find.text('Prati'));
        await tester.pump();
        expect(toggled, isTrue);
      },
    );
  });

  group('ClassifiedImageGallery', () {
    testWidgets(
      'renders desktop left vertical thumbnail rail and 1 od N pill',
      (tester) async {
        final ad = _sampleAd(
          images: const [
            'https://example.com/1.jpg',
            'https://example.com/2.jpg',
            'https://example.com/3.jpg',
            'https://example.com/4.jpg',
            'https://example.com/5.jpg',
            'https://example.com/6.jpg',
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 720,
                child: Builder(
                  builder: (context) => ClassifiedImageGallery(
                    ad: ad,
                    colorScheme: Theme.of(context).colorScheme,
                    isDesktop: true,
                    onImageTap: (_, __) {},
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('1 od 6'), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      },
    );
  });

  group('ClassifiedDetailContent responsive 3-column & mobile layouts', () {
    testWidgets(
      'renders 3-column layout with left sidebar, central card, and right seller sidebar at 1366×900',
      (tester) async {
        tester.view.physicalSize = const Size(1366, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ad = _sampleAd(price: 999, currency: 'EUR');
        final otherAd = _sampleAd(id: 'ad-2', price: 250, currency: 'EUR');
        final sellerProfile = UserModel(
          id: 'seller-1',
          displayName: 'Vlado',
          city: 'Šid',
          isVerified: true,
          createdAt: DateTime(2015, 9, 3),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClassifiedDetailContent(
                ad: ad,
                isDesktop: false,
                isWide: true,
                isOwner: false,
                hasPhone: true,
                isLoadingPhone: false,
                currentPhone: null,
                onImageTap: (_, __) {},
                onEdit: () {},
                onMarkAsSold: () {},
                onPhoneReveal: () {},
                onPhoneTap: () {},
                onChatTap: () {},
                onShare: () {},
                sellerProfile: sellerProfile,
                sellerAvgRating: 4.9,
                sellerReviewCount: 3,
                sellerOtherAds: [otherAd],
                sellerActiveAdsCount: 2,
                isFollowingSeller: false,
                isFavorited: false,
                favoritesCount: 5,
                onToggleFavorite: () {},
                onToggleFollowSeller: () {},
                onViewAllSellerAds: () {},
              ),
            ),
          ),
        );

        // Levi sidebar (>= 1200 px)
        expect(find.text('Sačuvani oglasi'), findsOneWidget);
        expect(find.textContaining('Kurs evra'), findsOneWidget);

        // Centralna kartica
        expect(find.text('5x120 20 felne'), findsAtLeastNWidgets(1));
        expect(find.text('Prati'), findsOneWidget);
        expect(find.text('Podeli'), findsOneWidget);

        // Desni seller sidebar
        expect(find.text('Pošalji poruku'), findsOneWidget);
        expect(find.text('Član od 03.09.2015.'), findsOneWidget);
        expect(find.text('(3 ocene)'), findsOneWidget);
        expect(find.text('Svi oglasi (2)'), findsOneWidget);
        expect(find.text('Sačuvaj prodavca'), findsOneWidget);
        expect(find.text('Klik za broj telefona'), findsOneWidget);
        expect(find.text('Verifikovan'), findsOneWidget);
        expect(
          find.text('Korisnik je izjavio da nije trgovac.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders clean single-column mobile layout without left sidebar at 390×844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final ad = _sampleAd(price: 500, currency: 'EUR');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ClassifiedDetailContent(
                ad: ad,
                isDesktop: false,
                isWide: false,
                isOwner: false,
                hasPhone: true,
                isLoadingPhone: false,
                currentPhone: null,
                onImageTap: (_, __) {},
                onEdit: () {},
                onMarkAsSold: () {},
                onPhoneReveal: () {},
                onPhoneTap: () {},
                onChatTap: () {},
                onShare: () {},
                onToggleFavorite: () {},
              ),
            ),
          ),
        );

        // Levi sidebar se ne prikazuje na mobilnom
        expect(find.textContaining('Kurs evra'), findsNothing);
        // Primarno CTA dugme u seller kartici je sakriveno na mobilnom (jer je u donjoj traci)
        expect(find.text('Pošalji poruku'), findsNothing);
        // Naslov i Prati su prisutni
        expect(find.text('5x120 20 felne'), findsOneWidget);
        expect(find.text('Prati'), findsOneWidget);
      },
    );
  });
}
