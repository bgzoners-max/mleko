import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/product_model.dart';

void main() {
  group('ProductModel.copyWith', () {
    final original = ProductModel(
      id: 'p-1',
      sellerId: 's-1',
      category: 'Mlečni proizvodi',
      name: 'Domaći sir',
      pricePerKg: 850.0,
      minOrderKg: 1.0,
      orderStep: 0.5,
      availableKg: 10.0,
      unitType: 'kg',
      description: 'Odličan planinski sir',
      imageUrls: ['https://example.com/cheese.jpg'],
      pickupOptions: ['farm'],
      location: 'Valjevo',
      isDomestic: true,
      availableNow: true,
      deliveryMode: ProductDeliveryMode.allSellerPoints,
      selectedDeliveryPointIds: ['dp-1'],
      createdAt: DateTime(2026, 1, 1),
      sellerIsVerified: true,
      avgRating: 4.8,
      reviewCount: 15,
    );

    test('copyWith preserves all unmodified fields', () {
      final modified = original.copyWith(
        name: 'Ekstra domaći sir',
        pricePerKg: 950.0,
      );

      expect(modified.id, equals('p-1'));
      expect(modified.sellerId, equals('s-1'));
      expect(modified.category, equals('Mlečni proizvodi'));
      expect(modified.name, equals('Ekstra domaći sir'));
      expect(modified.pricePerKg, equals(950.0));
      expect(modified.minOrderKg, equals(1.0));
      expect(modified.orderStep, equals(0.5));
      expect(modified.availableKg, equals(10.0));
      expect(modified.unitType, equals('kg'));
      expect(modified.description, equals('Odličan planinski sir'));
      expect(modified.imageUrls, equals(['https://example.com/cheese.jpg']));
      expect(modified.pickupOptions, equals(['farm']));
      expect(modified.location, equals('Valjevo'));
      expect(modified.isDomestic, isTrue);
      expect(modified.availableNow, isTrue);
      expect(modified.deliveryMode, equals(ProductDeliveryMode.allSellerPoints));
      expect(modified.selectedDeliveryPointIds, equals(['dp-1']));
      expect(modified.createdAt, equals(DateTime(2026, 1, 1)));
      // Crucial fields that must not be lost
      expect(modified.sellerIsVerified, isTrue);
      expect(modified.avgRating, equals(4.8));
      expect(modified.reviewCount, equals(15));
    });

    test('copyWith updates selectedDeliveryPointIds while preserving sellerIsVerified, avgRating and reviewCount', () {
      final updated = original.copyWith(selectedDeliveryPointIds: ['dp-2', 'dp-3']);

      expect(updated.selectedDeliveryPointIds, equals(['dp-2', 'dp-3']));
      expect(updated.sellerIsVerified, isTrue);
      expect(updated.avgRating, equals(4.8));
      expect(updated.reviewCount, equals(15));
      expect(updated.name, equals('Domaći sir'));
      expect(updated.id, equals('p-1'));
    });
  });
}
