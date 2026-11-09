import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/services/core/analytics_service.dart';

void main() {
  group('AnalyticsService tests', () {
    test('singleton instance initializes safely', () {
      final service = AnalyticsService();
      expect(service, isNotNull);
    });

    test('logging events completes gracefully without throwing when Firebase is uninitialized', () async {
      final service = AnalyticsService();

      final now = DateTime(2026, 1, 1);
      final product = ProductModel(
        id: 'prod-1',
        sellerId: 'seller-1',
        name: 'Domaci sir',
        category: 'Mlecni proizvodi',
        pricePerKg: 850.0,
        minOrderKg: 1.0,
        availableKg: 10.0,
        description: 'Kvalitetan domaci sir',
        imageUrls: const [],
        pickupOptions: const [],
        location: 'Valjevo',
        createdAt: now,
      );

      final ad = ClassifiedAdModel(
        id: 'ad-1',
        title: 'IMT 539 traktor',
        userId: 'user-1',
        categoryId: 'traktori',
        price: 4500.0,
        currency: 'EUR',
        city: 'Cacak',
        phone: '0601234567',
        createdAt: now,
        updatedAt: now,
      );

      await expectLater(service.logViewProduct(product), completes);
      await expectLater(service.logViewClassifiedAd(ad), completes);
      await expectLater(service.logAddToCart(product, 2.5), completes);
      await expectLater(service.logBeginCheckout(3, 2100.0), completes);
      await expectLater(
        service.logPurchase(
          transactionId: 'tx-123',
          value: 2100.0,
          itemCount: 3,
          shipping: 350.0,
        ),
        completes,
      );
    });
  });
}
