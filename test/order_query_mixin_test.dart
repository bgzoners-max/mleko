import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/order_model.dart';
import 'package:mleko/services/orders/mixins/order_query_mixin.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status,
        headers: {'content-type': 'application/json; charset=utf-8'});

/// HTTP klijent koji presreće sve zahteve ka (lažnom) Supabase REST API-ju i
/// vraća odgovore iz handler funkcije — konvencija iz postojećih testova.
class MockHttpHandlerClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request, String body)
      handler;
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

class _TestOrderQueryService with OrderQueryMixin {
  @override
  final SupabaseClient client;

  _TestOrderQueryService({required this.client});
}

Map<String, dynamic> orderJson(
  String id, {
  String status = 'sent',
  String buyerId = 'b1',
  String sellerId = 's1',
  double? totalAmount,
  String createdAt = '2026-01-02T10:00:00Z',
}) =>
    {
      'id': id,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'product_id': 'p1',
      'product_name': 'Domaći sir',
      'quantity_kg': 2.5,
      'unit_type': 'kg',
      'note': '',
      'buyer_city': 'Beograd',
      'buyer_phone': '0601234567',
      'status': status,
      'created_at': createdAt,
      'delivery_method': null,
      'total_amount': totalAmount,
    };

void main() {
  group('OrderQueryMixin — upiti nad orders tabelom', () {
    test(
        'fetchOrdersByBuyer mapira redove i obogaćuje ime prodavca + recenzije',
        () async {
      final requests = <http.BaseRequest>[];
      final mockClient = MockHttpHandlerClient((req, body) async {
        requests.add(req);
        final path = req.url.path;
        if (path.contains('public_profiles')) {
          return _jsonResponse(
              jsonEncode([
                {'id': 's1', 'farm_name': 'Farma Petrović'}
              ]),
              200);
        }
        if (path.contains('reviews')) {
          return _jsonResponse(
              jsonEncode([
                {'order_id': 'o1'}
              ]),
              200);
        }
        return _jsonResponse(
            jsonEncode([orderJson('o1'), orderJson('o2', status: 'delivered')]),
            200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final orders = await service.fetchOrdersByBuyer('b1');

      expect(orders.length, 2);
      expect(orders.first.id, 'o1');
      expect(orders.first.counterpartyName, 'Farma Petrović');
      expect(orders.first.isReviewed, isTrue);
      expect(orders.last.isReviewed, isFalse);

      // Upit filtrira po kupcu i sortira opadajuće po datumu kreiranja.
      final ordersReq =
          requests.firstWhere((r) => r.url.path.endsWith('/orders'));
      expect(ordersReq.url.query, contains('buyer_id=eq.b1'));
      expect(ordersReq.url.query, contains('order=created_at.desc'));
    });

    test('fetchOrdersByBuyer sa statusFilter "active" koristi neq archived',
        () async {
      http.BaseRequest? ordersReq;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('public_profiles')) {
          return _jsonResponse('[]', 200);
        }
        if (req.url.path.contains('reviews')) {
          return _jsonResponse('[]', 200);
        }
        ordersReq = req;
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      await service.fetchOrdersByBuyer('b1', statusFilter: 'active');

      expect(ordersReq!.url.query, contains('status=neq.archived'));
    });
    test('fetchOrdersBySeller sa eksplicitnim statusom koristi eq', () async {
      http.BaseRequest? ordersReq;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('public_profiles')) {
          return _jsonResponse('[]', 200);
        }
        if (req.url.path.contains('reviews')) {
          return _jsonResponse('[]', 200);
        }
        ordersReq = req;
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      await service.fetchOrdersBySeller('s1', statusFilter: 'delivered');

      expect(ordersReq!.url.query, contains('seller_id=eq.s1'));
      expect(ordersReq!.url.query, contains('status=eq.delivered'));
    });

    test('fetchOrdersBySeller obogaćuje ime kupca (loadSeller: false)',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        final path = req.url.path;
        if (path.contains('public_profiles')) {
          return _jsonResponse(
              jsonEncode([
                {'id': 'b1', 'display_name': 'Nikola Kupac'}
              ]),
              200);
        }
        if (path.contains('reviews')) return _jsonResponse('[]', 200);
        return _jsonResponse(jsonEncode([orderJson('o1', buyerId: 'b1')]), 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final orders = await service.fetchOrdersBySeller('s1');

      expect(orders.first.counterpartyName, 'Nikola Kupac');
      // Kupčevi podaci ne nose isReviewed flag (samo prodavačevi).
      expect(orders.first.isReviewed, isNull);
    });

    test('getOrderById vraća null kada red ne postoji', () async {
      final mockClient =
          MockHttpHandlerClient((req, body) async => _jsonResponse('[]', 200));
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      expect(await service.getOrderById('ne-postoji'), isNull);
    });

    test('getOrderById vraća porudžbinu kada red postoji', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/orders')) {
          return _jsonResponse(jsonEncode(orderJson('o9')), 200);
        }
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final order = await service.getOrderById('o9');
      expect(order, isNotNull);
      expect(order!.id, 'o9');
      expect(order.status, OrderStatus.sent);
    });

    test('getOrderItems parsira stavke porudžbine', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('order_items')) {
          return _jsonResponse(
              jsonEncode([
                {
                  'product_id': 'p1',
                  'product_name': 'Domaći sir',
                  'quantity_kg': 2.5,
                  'unit_type': 'kg',
                  'unit_price': 1200,
                }
              ]),
              200);
        }
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final items = await service.getOrderItems('o1');

      expect(items.length, 1);
      expect(items.first.productName, 'Domaći sir');
      expect(items.first.quantityKg, 2.5);
      expect(items.first.totalPrice, 3000);
    });
  });

  group('OrderQueryMixin — RPC statistike', () {
    test('getSellerStats parsira RPC odgovor', () async {
      String? rpcBody;
      String? rpcFn;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          rpcFn = req.url.path.split('/rpc/').last;
          rpcBody = body;
          return _jsonResponse(
              jsonEncode(
                  {'pending_count': 2, 'total_count': 7, 'revenue': 15400.5}),
              200);
        }
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final stats = await service.getSellerStats('s1');

      expect(rpcFn, 'get_seller_stats_dashboard');
      expect(rpcBody, contains('"p_seller_id":"s1"'));
      expect(stats.pendingCount, 2);
      expect(stats.totalCount, 7);
      expect(stats.revenue, 15400.5);
    });

    test('getSellerStats vraća nule kada RPC vrati null', () async {
      final mockClient = MockHttpHandlerClient(
          (req, body) async => _jsonResponse('null', 200));
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final stats = await service.getSellerStats('s1');

      expect(stats.pendingCount, 0);
      expect(stats.totalCount, 0);
      expect(stats.revenue, 0);
    });

    test('getBuyerStats parsira RPC odgovor', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse(
              jsonEncode({
                'pending_count': 1,
                'total_success_count': 4,
                'total_spent': 9900.25
              }),
              200);
        }
        return _jsonResponse('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final stats = await service.getBuyerStats('b1');

      expect(stats.pendingCount, 1);
      expect(stats.totalSuccessCount, 4);
      expect(stats.totalSpent, 9900.25);
    });
  });

  group('OrderQueryMixin — statistika po prodavcima', () {
    test(
        'BuyerSellerStats.averageOrder računa prosek i štiti od deljenja nulom',
        () {
      const stats = BuyerSellerStats(
        sellerId: 's1',
        sellerName: 'Farma',
        orderCount: 4,
        totalSpent: 1000,
        lastOrderId: 'o1',
      );
      expect(stats.averageOrder, 250);

      const empty = BuyerSellerStats(
        sellerId: 's2',
        sellerName: 'Farma',
        orderCount: 0,
        totalSpent: 0,
        lastOrderId: 'o2',
      );
      expect(empty.averageOrder, 0);
    });

    test(
        'getOrdersByBuyerForSellerStats grupiše po prodavcu i sumira potrošnju',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        final path = req.url.path;
        if (path.contains('public_profiles')) return _jsonResponse('[]', 200);
        if (path.contains('reviews')) return _jsonResponse('[]', 200);
        return _jsonResponse(
            jsonEncode([
              orderJson('o1',
                  sellerId: 's1',
                  totalAmount: 500,
                  createdAt: '2026-01-01T10:00:00Z'),
              orderJson('o2',
                  sellerId: 's1',
                  totalAmount: 300,
                  createdAt: '2026-01-05T10:00:00Z'),
              orderJson('o3',
                  sellerId: 's2',
                  totalAmount: 750,
                  createdAt: '2026-01-03T10:00:00Z'),
            ]),
            200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestOrderQueryService(client: supabase);

      final stats = await service.getOrdersByBuyerForSellerStats('b1');

      expect(stats.length, 2);
      final s1 = stats.firstWhere((s) => s.sellerId == 's1');
      expect(s1.orderCount, 2);
      expect(s1.totalSpent, 800);
      // lastOrderId dolazi iz najnovije porudžbine (sortiranje po createdAt desc).
      expect(s1.lastOrderId, 'o2');
      // Profil nije vraćen — fallback ime.
      expect(s1.sellerName, 'Prodavac');
    });
  });
}
