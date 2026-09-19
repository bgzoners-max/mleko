import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_autoflag.dart';
import 'package:mleko/models/message_reaction_model.dart';
import 'package:mleko/models/seller_stats_model.dart';

void main() {
  group('ProductListingAutoflag', () {
    test('parses full json with issues', () {
      final json = {
        'product_id': 'p1',
        'seller_id': 's1',
        'name': 'Sir',
        'category': 'Sir',
        'same_category_duplicates': 2,
        'cross_category_duplicates': 1,
        'missing_image': true,
        'missing_origin': false,
        'missing_shelf_life': true,
        'missing_pickup': false,
        'issues': ['x', 'y'],
        'has_issues': true,
      };
      final flag = ProductListingAutoflag.fromJson(json);
      expect(flag.productId, 'p1');
      expect(flag.sellerId, 's1');
      expect(flag.sameCategoryDuplicates, 2);
      expect(flag.crossCategoryDuplicates, 1);
      expect(flag.missingImage, isTrue);
      expect(flag.missingOrigin, isFalse);
      expect(flag.missingShelfLife, isTrue);
      expect(flag.missingPickup, isFalse);
      expect(flag.issues, ['x', 'y']);
      expect(flag.hasIssues, isTrue);
    });

    test('parses minimal json with defaults', () {
      final flag = ProductListingAutoflag.fromJson(const {});
      expect(flag.issues, isEmpty);
      expect(flag.missingImage, isFalse);
      expect(flag.sameCategoryDuplicates, 0);
      expect(flag.hasIssues, isFalse);
    });
  });

  group('ProductListingAutoflagSummary', () {
    test('parses full json', () {
      final summary = ProductListingAutoflagSummary.fromJson({
        'total_products': 100,
        'clean_products': 90,
        'problem_products': 10,
        'problem_rate_percent': 10.0,
      });
      expect(summary.totalProducts, 100);
      expect(summary.cleanProducts, 90);
      expect(summary.problemProducts, 10);
      expect(summary.problemRatePercent, 10.0);
    });

    test('parses missing fields with defaults', () {
      final summary = ProductListingAutoflagSummary.fromJson(const {});
      expect(summary.totalProducts, 0);
      expect(summary.problemRatePercent, 0.0);
    });
  });

  group('SellerStatsModel', () {
    test('parses json and computes responseLabel', () {
      final stats = SellerStatsModel.fromJson({
        'orders_count': 12,
        'avg_rating': 4.7,
        'review_count': 8,
        'avg_response_hours': 2.0,
      });
      expect(stats.ordersCount, 12);
      expect(stats.avgRating, 4.7);
      expect(stats.reviewCount, 8);
      expect(stats.avgResponseHours, 2.0);
      expect(stats.responseLabel, 'odgovara za 2h');
      expect(stats.hasAnyData, isTrue);
    });

    test('responseLabel varijante', () {
      expect(
        const SellerStatsModel(
          ordersCount: 0,
          reviewCount: 0,
          avgResponseHours: 0.5,
        ).responseLabel,
        'odgovara za <1h',
      );
      expect(
        const SellerStatsModel(
          ordersCount: 0,
          reviewCount: 0,
          avgResponseHours: 48,
        ).responseLabel,
        'odgovara za 2d',
      );
      expect(
        const SellerStatsModel(ordersCount: 0, reviewCount: 0).responseLabel,
        isNull,
      );
    });
  });

  group('SellerResponseStats', () {
    test('hasData je tačan samo sa podacima', () {
      const withData = SellerResponseStats(
        sampleCount: 1,
        avgResponseMinutes: 10,
        medianResponseMinutes: 5,
        lastResponseMinutes: 2,
      );
      expect(withData.hasData, isTrue);

      const noData = SellerResponseStats(
        sampleCount: 0,
        avgResponseMinutes: null,
        medianResponseMinutes: null,
        lastResponseMinutes: null,
      );
      expect(noData.hasData, isFalse);
    });

    test('medianLabel formatira sekunde, minute, sate i dane', () {
      const seconds = SellerResponseStats(
        sampleCount: 3,
        avgResponseMinutes: 0.5,
        medianResponseMinutes: 0.5,
        lastResponseMinutes: 0.2,
      );
      expect(seconds.medianLabel, 'par sekundi');

      const minutes = SellerResponseStats(
        sampleCount: 3,
        avgResponseMinutes: 5,
        medianResponseMinutes: 5,
        lastResponseMinutes: 5,
      );
      expect(minutes.medianLabel, '5 min');

      const hours = SellerResponseStats(
        sampleCount: 3,
        avgResponseMinutes: 120,
        medianResponseMinutes: 120,
        lastResponseMinutes: 120,
      );
      expect(hours.medianLabel, '2h');

      const days = SellerResponseStats(
        sampleCount: 3,
        avgResponseMinutes: 2880,
        medianResponseMinutes: 2880,
        lastResponseMinutes: 2880,
      );
      expect(days.medianLabel, '2 dana');

      const none = SellerResponseStats(
        sampleCount: 0,
        avgResponseMinutes: null,
        medianResponseMinutes: null,
        lastResponseMinutes: null,
      );
      expect(none.medianLabel, '...');
    });

    test('fromJson parses brojeve, stringove i null', () {
      final stats = SellerResponseStats.fromJson({
        'sample_count': 4,
        'avg_response_minutes': 12,
        'median_response_minutes': '8',
        'last_response_minutes': null,
      });
      expect(stats.sampleCount, 4);
      expect(stats.avgResponseMinutes, 12);
      expect(stats.medianResponseMinutes, 8);
      expect(stats.lastResponseMinutes, isNull);
    });
  });
}
