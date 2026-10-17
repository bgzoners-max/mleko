import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/models/app_error.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/models/seller_delivery_models.dart';
import 'package:mleko/services/orders/mixins/order_management_mixin.dart';

class MockHttpHandlerClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request, String body) handler;
  MockHttpHandlerClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String body = '';
    if (request is http.Request) {
      body = request.body;
    }
    final res = await handler(request, body);
    return http.StreamedResponse(
      Stream.value(utf8.encode(res.body)),
      res.statusCode,
      request: request,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...res.headers,
      },
    );
  }
}

class _TestOrderManagementService with OrderManagementMixin {
  @override
  final SupabaseClient client;

  OrderModel? stubOrder;

  _TestOrderManagementService({required this.client, this.stubOrder});

  @override
  Future<OrderModel?> getOrderById(String orderId) async {
    return stubOrder;
  }
}

void main() {
  group('OrderManagementMixin Validation & Flow Tests', () {
    test('createOrderWithItems throws validation error when items are empty', () async {
      final mockClient = MockHttpHandlerClient((req, body) async => http.Response('[]', 200));
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      expect(
        () => service.createOrderWithItems(
          buyerId: 'buyer-1',
          sellerId: 'seller-1',
          items: [],
          note: '',
          buyerCity: 'Valjevo',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.userMessage,
          'userMessage',
          contains('Porudžbina mora imati barem jednu stavku'),
        )),
      );
    });

    test('createOrderWithItems throws notFound error when product does not exist in DB', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          return http.Response('[]', 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      expect(
        () => service.createOrderWithItems(
          buyerId: 'buyer-1',
          sellerId: 'seller-1',
          items: [
            const OrderItemModel(
              productId: 'missing-prod',
              productName: 'Mleko',
              quantityKg: 2,
              unitType: 'L',
            ),
          ],
          note: '',
          buyerCity: 'Valjevo',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          equals(ErrorType.notFound),
        )),
      );
    });

    test('createOrderWithItems throws validation error when product seller does not match sellerId', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          final jsonResp = jsonEncode([
            {
              'id': 'prod-1',
              'seller_id': 'other-seller',
              'name': 'Mleko',
              'category': 'Mlecni proizvodi',
              'unit_type': 'L',
              'min_order_kg': 1,
              'order_step': 1,
              'price_per_kg': 150,
            }
          ]);
          return http.Response(jsonResp, 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      expect(
        () => service.createOrderWithItems(
          buyerId: 'buyer-1',
          sellerId: 'target-seller',
          items: [
            const OrderItemModel(
              productId: 'prod-1',
              productName: 'Mleko',
              quantityKg: 2,
              unitType: 'L',
            ),
          ],
          note: '',
          buyerCity: 'Valjevo',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.userMessage,
          'userMessage',
          contains('Stavke moraju pripadati istom prodavcu'),
        )),
      );
    });

    test('createOrderWithItems throws validation error when quantity violates min or step', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          final jsonResp = jsonEncode([
            {
              'id': 'prod-1',
              'seller_id': 'seller-1',
              'name': 'Sir',
              'category': 'Mlecni proizvodi',
              'unit_type': 'kg',
              'min_order_kg': 2,
              'order_step': 1,
              'price_per_kg': 800,
            }
          ]);
          return http.Response(jsonResp, 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      // Količina 1 je manja od min_order_kg (2)
      expect(
        () => service.createOrderWithItems(
          buyerId: 'buyer-1',
          sellerId: 'seller-1',
          items: [
            const OrderItemModel(
              productId: 'prod-1',
              productName: 'Sir',
              quantityKg: 1,
              unitType: 'kg',
            ),
          ],
          note: '',
          buyerCity: 'Valjevo',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          equals(ErrorType.validation),
        )),
      );
    });

    test('createOrderWithItems throws validation error when deliverySelection is missing for sellerDelivery', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          final jsonResp = jsonEncode([
            {
              'id': 'prod-1',
              'seller_id': 'seller-1',
              'name': 'Med',
              'category': 'Med',
              'unit_type': 'kg',
              'min_order_kg': 1,
              'order_step': 1,
              'price_per_kg': 1200,
            }
          ]);
          return http.Response(jsonResp, 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      expect(
        () => service.createOrderWithItems(
          buyerId: 'buyer-1',
          sellerId: 'seller-1',
          items: [
            const OrderItemModel(
              productId: 'prod-1',
              productName: 'Med',
              quantityKg: 1,
              unitType: 'kg',
            ),
          ],
          note: '',
          buyerCity: 'Valjevo',
          buyerPhone: '0601234567',
          deliveryMethod: DeliveryMethod.sellerDelivery,
          deliverySelection: null,
        ),
        throwsA(isA<AppError>().having(
          (e) => e.userMessage,
          'userMessage',
          contains('Izaberite grad, lokaciju i termin'),
        )),
      );
    });

    test('createOrderWithItems does not block order when total is below legacy slot delivery minimum', () async {
      bool rpcCalled = false;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          final jsonResp = jsonEncode([
            {
              'id': 'prod-1',
              'seller_id': 'seller-1',
              'name': 'Med',
              'category': 'Med',
              'unit_type': 'kg',
              'min_order_kg': 1,
              'order_step': 1,
              'price_per_kg': 1000,
            }
          ]);
          return http.Response(jsonResp, 200);
        }
        if (req.url.path.contains('/rpc/create_order_with_items')) {
          rpcCalled = true;
          return http.Response(jsonEncode('order-no-minimum-block'), 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      final selection = const DeliverySelectionModel(
        method: DeliveryMethod.sellerDelivery,
        city: 'Beograd',
        pointId: 'point-1',
        slotId: 'slot-1',
        pointLabel: 'Centar',
        address: 'Terazije 1',
        weekday: 1,
        timeFrom: '10:00',
        timeTo: '12:00',
        minOrderAmountRsd: 2500, // Legacy slot polje (2500), dok je poručeno 1000
      );

      final orderId = await service.createOrderWithItems(
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        items: [
          const OrderItemModel(
            productId: 'prod-1',
            productName: 'Med',
            quantityKg: 1,
            unitType: 'kg',
          ),
        ],
        note: '',
        buyerCity: 'Beograd',
        buyerPhone: '0601234567',
        deliveryMethod: DeliveryMethod.sellerDelivery,
        deliverySelection: selection,
      );

      expect(orderId, equals('order-no-minimum-block'));
      expect(rpcCalled, isTrue);
    });

    test('createOrderWithItems calls RPC and returns order ID when valid', () async {
      bool rpcCalled = false;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/products')) {
          final jsonResp = jsonEncode([
            {
              'id': 'prod-1',
              'seller_id': 'seller-1',
              'name': 'Sir',
              'category': 'Mlecni proizvodi',
              'unit_type': 'kg',
              'min_order_kg': 1,
              'order_step': 0.5,
              'price_per_kg': 800,
            }
          ]);
          return http.Response(jsonResp, 200);
        }
        if (req.url.path.contains('/rest/v1/rpc/create_order_with_items')) {
          rpcCalled = true;
          return http.Response('"order-uuid-created-123"', 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase);

      final orderId = await service.createSingleProductOrder(
        buyerId: 'buyer-1',
        sellerId: 'seller-1',
        productId: 'prod-1',
        productName: 'Sir',
        quantityKg: 2.5,
        unitType: 'kg',
        note: 'Molim lepo pakovanje',
        buyerCity: 'Valjevo',
        buyerPhone: '0601234567',
      );

      expect(rpcCalled, isTrue);
      expect(orderId, equals('order-uuid-created-123'));
    });

    test('updateOrderStatus throws notFound when order does not exist', () async {
      final mockClient = MockHttpHandlerClient((req, body) async => http.Response('[]', 200));
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = _TestOrderManagementService(client: supabase, stubOrder: null);

      expect(
        () => service.updateOrderStatus('non-existing', OrderStatus.accepted),
        throwsA(isA<AppError>().having((e) => e.type, 'type', equals(ErrorType.notFound))),
      );
    });

    test('cancelOrderBySeller validates authorization and cancellation transitions', () async {
      final mockClient = MockHttpHandlerClient((req, body) async => http.Response('[]', 200));
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);

      final order = OrderModel(
        id: 'order-1',
        buyerId: 'buyer-1',
        sellerId: 'actual-seller',
        note: '',
        buyerCity: 'Valjevo',
        buyerPhone: '0601234567',
        status: OrderStatus.delivered, // Isporučena porudžbina se ne može otkazati
        createdAt: DateTime.now(),
      );

      final service = _TestOrderManagementService(client: supabase, stubOrder: order);

      // Kad korisnik nije ulogovan kao seller (ili je null), baca forbidden
      expect(
        () => service.cancelOrderBySeller('order-1', 'Nema na stanju'),
        throwsA(isA<AppError>().having((e) => e.type, 'type', equals(ErrorType.forbidden))),
      );
    });
  });
}
