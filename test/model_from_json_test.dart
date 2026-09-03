import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/models/notification_model.dart';
import 'package:mleko/utils/product_helpers.dart';

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

  group('ProductModel.toDbMap', () {
    test('omits view-only and collection fields to prevent PostgREST column errors', () {
      final product = ProductModel(
        id: 'prod-123',
        sellerId: 'seller-456',
        category: 'Sir',
        name: 'Zlatiborski sir',
        pricePerKg: 1200,
        minOrderKg: 0.5,
        orderStep: 0.5,
        availableKg: 20,
        unitType: 'kg',
        description: 'Odličan sir',
        imageUrls: ['https://example.com/pic.jpg'],
        pickupOptions: ['Lično preuzimanje'],
        location: 'Zlatibor',
        isDomestic: true,
        availableNow: true,
        deliveryMode: ProductDeliveryMode.selectedPoints,
        selectedDeliveryPointIds: ['point-1', 'point-2'],
        sellerIsVerified: true,
        avgRating: 4.8,
        reviewCount: 25,
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      final dbMap = product.toDbMap();

      expect(dbMap['id'], 'prod-123');
      expect(dbMap['seller_id'], 'seller-456');
      expect(dbMap['category'], 'Sir');
      expect(dbMap['name'], 'Zlatiborski sir');
      expect(dbMap['order_step'], 0.5);
      expect(dbMap.containsKey('seller_is_verified'), isFalse);
      expect(dbMap.containsKey('avg_rating'), isFalse);
      expect(dbMap.containsKey('review_count'), isFalse);
      expect(dbMap.containsKey('selected_delivery_point_ids'), isFalse);
    });

    test('omits id when includeId is false', () {
      final product = ProductModel(
        id: 'prod-new',
        sellerId: 'seller-1',
        category: 'Mleko',
        name: 'Kozje mleko',
        pricePerKg: 250,
        minOrderKg: 1,
        availableKg: 10,
        description: 'Sveže kozje mleko',
        imageUrls: const [],
        pickupOptions: const ['Lično'],
        location: 'Beograd',
        createdAt: DateTime.now(),
      );

      final dbMap = product.toDbMap(includeId: false);
      expect(dbMap.containsKey('id'), isFalse);
    });
  });

  group('NotificationModel.fromJson', () {
    test('parses conversation_id correctly', () {
      final json = {
        'id': 'notif-1',
        'user_id': 'user-1',
        'type': 'new_message',
        'title': 'Nova poruka',
        'body': 'Zdravo, kada stiže isporuka?',
        'conversation_id': 'conv-123-abc',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.conversationId, 'conv-123-abc');
      expect(notif.type, 'new_message');
    });
  });

  group('isVolumeCategory & REPO_BIBLE rules', () {
    test('strictly enforces kg for honey and preserves liquids for volume', () {
      expect(isVolumeCategory('Med'), isFalse);
      expect(isVolumeCategory('Livadski med'), isFalse);
      expect(isVolumeCategory('Džem od šljiva'), isFalse);
      expect(isVolumeCategory('Zimnica i tegle'), isFalse);

      expect(isVolumeCategory('Kravlje mleko'), isTrue);
      expect(isVolumeCategory('Prirodni sok'), isTrue);
      expect(isVolumeCategory('Domaći sirup'), isTrue);
      expect(isVolumeCategory('Hladno ceđeno ulje'), isTrue);
      expect(isVolumeCategory('Jabukovo sirće'), isTrue);
      expect(isVolumeCategory('Domaća rakija'), isTrue);
    });
  });
}
