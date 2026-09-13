import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/widgets/classifieds/classified_ad_card.dart';

void main() {
  group('ClassifiedAdModel Featured & Urgent', () {
    test('serializes and deserializes featured and urgent fields correctly', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 14));

      final ad = ClassifiedAdModel(
        id: 'ad-feat-1',
        userId: 'user-1',
        title: 'Mlin čekićar',
        price: 350,
        currency: 'EUR',
        categoryId: 'masine',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: now,
        updatedAt: now,
        isFeatured: true,
        featuredUntil: futureDate,
        isUrgent: true,
      );

      final json = ad.toJson();
      expect(json['is_featured'], isTrue);
      expect(json['featured_until'], futureDate.toIso8601String());
      expect(json['is_urgent'], isTrue);

      final parsed = ClassifiedAdModel.fromJson(json);
      expect(parsed.isFeatured, isTrue);
      expect(parsed.isUrgent, isTrue);
      expect(parsed.featuredUntil?.toIso8601String(), futureDate.toIso8601String());
      expect(parsed.isCurrentlyFeatured, isTrue);
    });

    test('isCurrentlyFeatured returns false when expired or not featured', () {
      final now = DateTime.now();

      final nonFeatured = ClassifiedAdModel(
        id: 'ad-non-feat',
        userId: 'user-1',
        title: 'Test',
        price: 100,
        currency: 'EUR',
        categoryId: 'masine',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: now,
        updatedAt: now,
        isFeatured: false,
      );
      expect(nonFeatured.isCurrentlyFeatured, isFalse);

      final expiredFeatured = ClassifiedAdModel(
        id: 'ad-exp',
        userId: 'user-1',
        title: 'Test',
        price: 100,
        currency: 'EUR',
        categoryId: 'masine',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: now,
        updatedAt: now,
        isFeatured: true,
        featuredUntil: now.subtract(const Duration(hours: 1)),
      );
      expect(expiredFeatured.isCurrentlyFeatured, isFalse);

      final indefinitelyFeatured = ClassifiedAdModel(
        id: 'ad-indef',
        userId: 'user-1',
        title: 'Test',
        price: 100,
        currency: 'EUR',
        categoryId: 'masine',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: now,
        updatedAt: now,
        isFeatured: true,
        featuredUntil: null,
      );
      expect(indefinitelyFeatured.isCurrentlyFeatured, isTrue);
    });

    test('copyWith updates promotional flags', () {
      final ad = ClassifiedAdModel(
        id: 'ad-copy',
        userId: 'user-1',
        title: 'Traktor',
        price: 5000,
        currency: 'EUR',
        categoryId: 'masine',
        condition: 'used',
        city: 'Novi Sad',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = ad.copyWith(
        isFeatured: true,
        isUrgent: true,
      );

      expect(updated.isFeatured, isTrue);
      expect(updated.isUrgent, isTrue);
      expect(updated.isCurrentlyFeatured, isTrue);
    });
  });

  group('ClassifiedAdCard Featured & Urgent Badges', () {
    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 420,
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders ISTAKNUTO and HITNO badges when active', (tester) async {
      final promoAd = ClassifiedAdModel(
        id: 'ad-promo',
        userId: 'user-2',
        title: 'Sadilica rasada',
        price: 1200,
        currency: 'EUR',
        categoryId: 'prikljucci',
        condition: 'new',
        city: 'Valjevo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: true,
        isUrgent: true,
      );

      await tester.pumpWidget(
        buildTestWidget(ClassifiedAdCard(ad: promoAd)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ISTAKNUTO'), findsOneWidget);
      expect(find.text('HITNO'), findsOneWidget);
      expect(find.text('Valjevo'), findsOneWidget);
      expect(find.text('Sadilica rasada'), findsOneWidget);
    });

    testWidgets('does not render promo badges when flags are false', (tester) async {
      final regularAd = ClassifiedAdModel(
        id: 'ad-reg',
        userId: 'user-2',
        title: 'Redovan oglas',
        price: 100,
        currency: 'EUR',
        categoryId: 'prikljucci',
        condition: 'new',
        city: 'Valjevo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        isUrgent: false,
      );

      await tester.pumpWidget(
        buildTestWidget(ClassifiedAdCard(ad: regularAd)),
      );
      await tester.pumpAndSettle();

      expect(find.text('ISTAKNUTO'), findsNothing);
      expect(find.text('HITNO'), findsNothing);
    });
  });
}
