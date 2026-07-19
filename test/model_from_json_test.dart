import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';

void main() {
  group('ProductModel.fromJson', () {
    test('parses valid json with all fields', () {
      final json = {
        'id': 'prod-1',
        'seller_id': 'seller-1',
        'category': 'mleko',
        'name': 'Sveže mleko',
        'price_per_kg': 120,
        'min_order_kg': 1,
        'order_step': 0.5,
        'available_kg': 50,
        'unit_type': 'L',
        'description': 'Domaće mleko sa planine',
        'image_urls': ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
        'pickup_options': ['Dostava', 'Lično'],
        'location': 'Zlatibor',
        'is_domestic': true,
        'available_now': true,
        'delivery_mode': 'all_seller_points',
        'selected_delivery_point_ids': ['pt-1', 'pt-2'],
        'created_at': '2025-01-15T10:30:00Z',
        'seller_is_verified': true,
        'avg_rating': 4.5,
        'review_count': 12,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod-1');
      expect(product.sellerId, 'seller-1');
      expect(product.category, 'mleko');
      expect(product.name, 'Sveže mleko');
      expect(product.pricePerKg, 120);
      expect(product.minOrderKg, 1);
      expect(product.orderStep, 0.5);
      expect(product.availableKg, 50);
      expect(product.unitType, 'L');
      expect(product.description, 'Domaće mleko sa planine');
      expect(product.imageUrls, ['https://example.com/img1.jpg', 'https://example.com/img2.jpg']);
      expect(product.pickupOptions, ['Dostava', 'Lično']);
      expect(product.location, 'Zlatibor');
      expect(product.isDomestic, true);
      expect(product.availableNow, true);
      expect(product.deliveryMode, ProductDeliveryMode.allSellerPoints);
      expect(product.selectedDeliveryPointIds, ['pt-1', 'pt-2']);
      expect(product.sellerIsVerified, true);
      expect(product.avgRating, 4.5);
      expect(product.reviewCount, 12);
    });

    test('parses minimal json with defaults', () {
      final json = {
        'id': 'prod-min',
        'seller_id': 'seller-min',
        'category': 'med',
        'name': 'Med',
        'price_per_kg': 800,
        'min_order_kg': 0.5,
        'available_kg': 10,
        'description': '',
        'image_urls': [],
        'pickup_options': [],
        'location': '',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod-min');
      expect(product.unitType, 'kg'); // default
      expect(product.description, '');
      expect(product.imageUrls, isEmpty);
      expect(product.avgRating, isNull);
      expect(product.reviewCount, 0);
      expect(product.sellerIsVerified, false);
      expect(product.isDomestic, true);
    });

    test('handles null and missing fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'prod-fallback',
        'seller_id': null,
        'category': null,
        'name': null,
        'min_order_kg': null,
        'available_kg': null,
        'description': null,
        'image_urls': null,
        'pickup_options': null,
        'location': null,
        'created_at': null,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod-fallback');
      expect(product.sellerId, '');
      expect(product.category, '');
      expect(product.name, '');
      expect(product.pricePerKg, 0);
      expect(product.minOrderKg, 1);
      expect(product.availableKg, 0);
      expect(product.description, '');
      expect(product.imageUrls, isEmpty);
      expect(product.location, '');
    });
  });

  group('OrderModel.fromJson', () {
    test('parses valid json with known status', () {
      final json = {
        'id': 'order-1',
        'buyer_id': 'buyer-1',
        'seller_id': 'seller-1',
        'product_id': 'prod-1',
        'product_name': 'Mleko',
        'quantity_kg': 2.5,
        'unit_type': 'L',
        'note': 'Bez plastike',
        'buyer_city': 'Beograd',
        'buyer_phone': '+38164123456',
        'buyer_address': 'Ulica 123',
        'buyer_postal_code': '11000',
        'status': 'accepted',
        'created_at': '2025-01-15T10:30:00Z',
        'cancellation_reason': null,
        'archived_at': null,
        'expires_at': null,
        'delivery_method': 'seller_delivery',
        'delivery_city': 'Beograd',
        'delivery_point_id': 'pt-1',
        'delivery_point_label': 'Centar',
        'delivery_address': 'Trg 1',
        'delivery_weekday': 3,
        'delivery_time_from': '10:00',
        'delivery_time_to': '12:00',
        'delivery_fee_rsd': 300,
        'total_amount': 500,
        'is_reviewed': false,
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'order-1');
      expect(order.status, OrderStatus.accepted);
      expect(order.statusLabel, 'Prihvaćeno');
      expect(order.buyerCity, 'Beograd');
      expect(order.deliveryMethod, DeliveryMethod.sellerDelivery);
      expect(order.totalAmount, 500);
    });

    test('parses archived status correctly', () {
      final json = {
        'id': 'order-arch',
        'buyer_id': 'b-1',
        'seller_id': 's-1',
        'note': '',
        'buyer_city': 'NS',
        'buyer_phone': '123',
        'status': 'archived',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final order = OrderModel.fromJson(json);

      expect(order.status, OrderStatus.archived);
      expect(order.isArchived, true);
    });
  });
}
