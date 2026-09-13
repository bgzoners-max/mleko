import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_seller_stats_model.dart';
import 'package:mleko/widgets/classifieds/seller_analytics_summary_card.dart';

void main() {
  group('ClassifiedSellerStatsModel', () {
    test('correctly parses from JSON with all fields populated', () {
      final json = {
        'total_ads': 15,
        'active_ads': 10,
        'sold_ads': 5,
        'total_views': 350,
        'total_call_clicks': 42,
        'total_shares': 18,
        'featured_count': 3,
        'top_ad_id': 'ad-123-abc',
        'top_ad_title': 'Traktor Ferguson IMT 539',
        'top_ad_views': 120,
        'top_ad_call_clicks': 25,
        'top_ad_price': 5500.0,
        'top_ad_currency': 'EUR',
        'top_ad_image': 'https://example.com/tractor.jpg',
      };

      final stats = ClassifiedSellerStatsModel.fromJson(json);

      expect(stats.totalAds, 15);
      expect(stats.activeAds, 10);
      expect(stats.soldAds, 5);
      expect(stats.totalViews, 350);
      expect(stats.totalCallClicks, 42);
      expect(stats.totalShares, 18);
      expect(stats.featuredCount, 3);
      expect(stats.topAdId, 'ad-123-abc');
      expect(stats.topAdTitle, 'Traktor Ferguson IMT 539');
      expect(stats.topAdViews, 120);
      expect(stats.topAdCallClicks, 25);
      expect(stats.topAdPrice, 5500.0);
      expect(stats.topAdCurrency, 'EUR');
      expect(stats.topAdImage, 'https://example.com/tractor.jpg');
      expect(stats.hasAds, isTrue);
      expect(stats.hasTopAd, isTrue);
    });

    test('handles null and missing fields gracefully with defaults', () {
      final stats = ClassifiedSellerStatsModel.fromJson({});

      expect(stats.totalAds, 0);
      expect(stats.activeAds, 0);
      expect(stats.soldAds, 0);
      expect(stats.totalViews, 0);
      expect(stats.totalCallClicks, 0);
      expect(stats.totalShares, 0);
      expect(stats.featuredCount, 0);
      expect(stats.topAdId, isNull);
      expect(stats.topAdTitle, isNull);
      expect(stats.topAdViews, 0);
      expect(stats.topAdCallClicks, 0);
      expect(stats.topAdPrice, 0.0);
      expect(stats.topAdCurrency, 'RSD');
      expect(stats.topAdImage, isNull);
      expect(stats.hasAds, isFalse);
      expect(stats.hasTopAd, isFalse);
    });

    test('serializes to JSON correctly', () {
      const stats = ClassifiedSellerStatsModel(
        totalAds: 3,
        activeAds: 2,
        soldAds: 1,
        totalViews: 80,
        totalCallClicks: 12,
        totalShares: 4,
        featuredCount: 1,
        topAdId: 'ad-99',
        topAdTitle: 'Kombajn Zmaj',
        topAdViews: 50,
        topAdCallClicks: 8,
        topAdPrice: 12000.0,
        topAdCurrency: 'EUR',
      );

      final json = stats.toJson();

      expect(json['total_ads'], 3);
      expect(json['active_ads'], 2);
      expect(json['sold_ads'], 1);
      expect(json['total_views'], 80);
      expect(json['total_call_clicks'], 12);
      expect(json['total_shares'], 4);
      expect(json['top_ad']['id'], 'ad-99');
      expect(json['top_ad']['title'], 'Kombajn Zmaj');
    });
  });

  group('ClassifiedAdModel Analytics Fields', () {
    test('parses and persists call_clicks_count and shares_count', () {
      final json = {
        'id': 'ad-1',
        'seller_id': 'user-1',
        'title': 'Test oglas',
        'description': 'Opis',
        'price': 1000.0,
        'currency': 'RSD',
        'category_id': 'oprema',
        'city': 'Beograd',
        'created_at': '2026-09-10T12:00:00Z',
        'views_count': 45,
        'call_clicks_count': 9,
        'shares_count': 3,
      };

      final ad = ClassifiedAdModel.fromJson(json);

      expect(ad.viewsCount, 45);
      expect(ad.callClicksCount, 9);
      expect(ad.sharesCount, 3);

      final serialized = ad.toJson();
      expect(serialized['call_clicks_count'], 9);
      expect(serialized['shares_count'], 3);

      final copied = ad.copyWith(
        callClicksCount: 15,
        sharesCount: 7,
      );
      expect(copied.callClicksCount, 15);
      expect(copied.sharesCount, 7);
      expect(copied.viewsCount, 45);
    });
  });

  group('SellerAnalyticsSummaryCard Widget', () {
    testWidgets('renders all KPI counters and top ad information', (tester) async {
      const stats = ClassifiedSellerStatsModel(
        totalAds: 8,
        activeAds: 6,
        soldAds: 2,
        totalViews: 342,
        totalCallClicks: 56,
        totalShares: 19,
        featuredCount: 2,
        topAdId: 'top-1',
        topAdTitle: 'Balirka John Deere',
        topAdViews: 180,
        topAdCallClicks: 30,
        topAdPrice: 4200.0,
        topAdCurrency: 'EUR',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SellerAnalyticsSummaryCard(
                stats: stats,
              ),
            ),
          ),
        ),
      );

      // Provera naslova
      expect(find.text('Učinak vaših oglasa'), findsOneWidget);

      // Provera brojača (KPI pills)
      expect(find.text('342'), findsOneWidget); // Pregledi
      expect(find.text('56'), findsOneWidget); // Pozivi
      expect(find.text('19'), findsOneWidget); // Deljenja
      expect(find.text('6 / 2'), findsOneWidget); // Aktivni / Prodati

      // Provera oznaka
      expect(find.text('Pregledi'), findsOneWidget);
      expect(find.text('Pozivi kupaca'), findsOneWidget);
      expect(find.text('Deljenja'), findsOneWidget);
      expect(find.text('Aktivno / Prodato'), findsOneWidget);

      // Provera najpopularnijeg oglasa
      expect(find.text('Najgledaniji: '), findsOneWidget);
      expect(find.text('Balirka John Deere'), findsOneWidget);
      expect(find.text('180 pregleda'), findsOneWidget);
    });

    testWidgets('renders without top ad strip when top ad is absent', (tester) async {
      const stats = ClassifiedSellerStatsModel(
        totalAds: 2,
        activeAds: 2,
        soldAds: 0,
        totalViews: 10,
        totalCallClicks: 1,
        totalShares: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: const Scaffold(
            body: SellerAnalyticsSummaryCard(
              stats: stats,
            ),
          ),
        ),
      );

      expect(find.text('Učinak vaših oglasa'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Najgledaniji: '), findsNothing);
    });
  });
}
