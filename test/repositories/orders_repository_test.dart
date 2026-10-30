import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/app_error.dart';
import 'package:mleko/models/order_item_model.dart';
import 'package:mleko/models/order_model.dart';
import 'package:mleko/repositories/orders/orders_repository.dart';

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
      'product_name': 'Domaci sir',
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

Map<String, dynamic> auditLogJson(String id) => {
      'id': id,
      'order_id': 'o1',
      'old_status': 'sent',
      'new_status': 'accepted',
      'changed_by_role': 'seller',
      'changed_by_user_id': 's1',
      'changed_at': '2026-01-03T12:00:00Z',
    };

Map<String, dynamic> productRow(String id, {String sellerId = 's1'}) => {
      'id': id,
      'seller_id': sellerId,
      'name': 'Domaci sir',
      'category': 'mlecni',
      'unit_type': 'kg',
      'min_order_kg': 1,
      'order_step': 1,
      'price_per_kg': 1200,
    };

SupabaseOrdersRepository repoFor(
  Future<http.Response> Function(http.BaseRequest, String) handler,
) =>
    SupabaseOrdersRepository(
      client: SupabaseClient(
        'https://fake.supabase.co',
        'fake-key',
        httpClient: MockHttpHandlerClient(handler),
      ),
    );

void main() {
  group('SupabaseOrdersRepository — citanje podataka', () {
    test('getOrderById vraca null kada red ne postoji', () async {
      final repo = repoFor((req, body) async => _jsonResponse('[]', 200));
      expect(await repo.getOrderById('ne-postoji'), isNull);
    });

    test('getOrderById vraca porudzbinu kada red postoji', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('/orders')) {
          return _jsonResponse(jsonEncode(orderJson('o9')), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final order = await repo.getOrderById('o9');
      expect(order, isNotNull);
      expect(order!.id, 'o9');
      expect(order.status, OrderStatus.sent);
    });

    test('getOrderItems mapira stavke porudzbine iz order_items', () async {
      http.BaseRequest? itemsReq;
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('order_items')) {
          itemsReq = req;
          return _jsonResponse(
            jsonEncode([
              {
                'product_id': 'p1',
                'product_name': 'Domaci sir',
                'quantity_kg': 2,
                'unit_type': 'kg',
                'unit_price': 1200,
              },
              {
                'product_id': 'p2',
                'product_name': 'Med bagrem',
                'quantity_kg': 0.5,
                'unit_type': 'kg',
                'unit_price': 1500,
              },
            ]),
            200,
          );
        }
        return _jsonResponse('[]', 200);
      });

      final items = await repo.getOrderItems('o1');

      expect(items.length, 2);
      expect(items.first.productId, 'p1');
      expect(items.first.quantityKg, 2);
      expect(items.first.totalPrice, 2400);
      expect(items.last.productName, 'Med bagrem');
      expect(itemsReq!.url.query, contains('order_id=eq.o1'));
    });

    test('getOrderStatusAuditLogs mapira audit log redove', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('order_status_audit_logs')) {
          return _jsonResponse(
              jsonEncode([auditLogJson('a1'), auditLogJson('a2')]), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final logs = await repo.getOrderStatusAuditLogs('o1');

      expect(logs.length, 2);
      expect(logs.first.oldStatus, 'sent');
      expect(logs.first.newStatus, 'accepted');
      expect(logs.first.changedByRole, 'seller');
    });
  });

  group('SupabaseOrdersRepository — statistika', () {
    test('getSellerStats vraca nule kada RPC vrati null', () async {
      final repo = repoFor((req, body) async => _jsonResponse('null', 200));

      final stats = await repo.getSellerStats('s1');

      expect(stats.pendingCount, 0);
      expect(stats.totalCount, 0);
      expect(stats.revenue, 0);
    });

    test('getBuyerStats parsira RPC odgovor', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse(
            jsonEncode({
              'pending_count': 2,
              'total_success_count': 7,
              'total_spent': 12800.5,
            }),
            200,
          );
        }
        return _jsonResponse('[]', 200);
      });

      final stats = await repo.getBuyerStats('b1');

      expect(stats.pendingCount, 2);
      expect(stats.totalSuccessCount, 7);
      expect(stats.totalSpent, 12800.5);
    });
  });

  group('SupabaseOrdersRepository — createOrderWithItems validacije', () {
    test('prazna lista stavki baca validation gresku bez ijednog poziva',
        () async {
      final requests = <http.BaseRequest>[];
      final repo = repoFor((req, body) async {
        requests.add(req);
        return _jsonResponse('[]', 200);
      });

      await expectLater(
        repo.createOrderWithItems(
          buyerId: 'b1',
          sellerId: 's1',
          items: const [],
          note: '',
          buyerCity: 'Beograd',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          ErrorType.validation,
        )),
      );
      expect(requests, isEmpty);
    });

    test('nepostojeci proizvod baca notFound gresku', () async {
      final repo = repoFor((req, body) async => _jsonResponse('[]', 200));

      await expectLater(
        repo.createOrderWithItems(
          buyerId: 'b1',
          sellerId: 's1',
          items: [
            const OrderItemModel(
                productId: 'p-ne',
                productName: 'Nepostojeci',
                quantityKg: 2),
          ],
          note: '',
          buyerCity: 'Beograd',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          ErrorType.notFound,
        )),
      );
    });

    test('stavka drugog prodavca baca validation gresku (seller mismatch)',
        () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          return _jsonResponse(
              jsonEncode([productRow('p1', sellerId: 's2')]), 200);
        }
        return _jsonResponse('[]', 200);
      });

      await expectLater(
        repo.createOrderWithItems(
          buyerId: 'b1',
          sellerId: 's1',
          items: [
            const OrderItemModel(
                productId: 'p1', productName: 'Domaci sir', quantityKg: 2),
          ],
          note: '',
          buyerCity: 'Beograd',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          ErrorType.validation,
        )),
      );
    });

    test('kolicina van koraka order_step baca validation gresku', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          return _jsonResponse(jsonEncode([productRow('p1')]), 200);
        }
        return _jsonResponse('[]', 200);
      });

      // min_order_kg=1, order_step=1 -> 1.5 nije validna kolicina.
      await expectLater(
        repo.createOrderWithItems(
          buyerId: 'b1',
          sellerId: 's1',
          items: [
            const OrderItemModel(
                productId: 'p1', productName: 'Domaci sir', quantityKg: 1.5),
          ],
          note: '',
          buyerCity: 'Beograd',
          buyerPhone: '0601234567',
        ),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          ErrorType.validation,
        )),
      );
    });

    test('srecan put poziva create_order_with_items RPC i vraca ID',
        () async {
      String? rpcBody;
      String? rpcPath;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          return _jsonResponse(jsonEncode([productRow('p1')]), 200);
        }
        if (req.url.path.contains('/rpc/')) {
          rpcPath = req.url.path;
          rpcBody = body;
          return _jsonResponse(jsonEncode('o-nova'), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final orderId = await repo.createOrderWithItems(
        buyerId: 'b1',
        sellerId: 's1',
        items: [
          const OrderItemModel(
            productId: 'p1',
            productName: 'Domaci sir',
            quantityKg: 2,
            unitPrice: 1200,
          ),
        ],
        note: 'Molim dostavu u subotu',
        buyerCity: 'Beograd',
        buyerPhone: '0601234567',
        buyerAddress: 'Ulica 1',
        buyerPostalCode: '11000',
      );

      expect(orderId, 'o-nova');
      expect(rpcPath, contains('create_order_with_items'));
      final params = jsonDecode(rpcBody!) as Map<String, dynamic>;
      expect(params['p_buyer_id'], 'b1');
      expect(params['p_seller_id'], 's1');
      expect(params['p_buyer_city'], 'Beograd');
      expect(params['p_delivery_method'], 'agreement');
      final itemsJson = params['p_items'] as List;
      expect(itemsJson.first['product_id'], 'p1');
      expect(itemsJson.first['quantity_kg'], 2);
    });

    test('createSingleProductOrder delegira na createOrderWithItems', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          return _jsonResponse(jsonEncode([productRow('p1')]), 200);
        }
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse(jsonEncode('o-single'), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final orderId = await repo.createSingleProductOrder(
        buyerId: 'b1',
        sellerId: 's1',
        productId: 'p1',
        productName: 'Domaci sir',
        quantityKg: 3,
        unitType: 'kg',
        note: '',
        buyerCity: 'Beograd',
        buyerPhone: '0601234567',
      );

      expect(orderId, 'o-single');
    });
  });

  group('SupabaseOrdersRepository — statusi i arhiviranje', () {
    test('updateOrderStatus baca notFound kada porudzbina ne postoji',
        () async {
      final repo = repoFor((req, body) async => _jsonResponse('[]', 200));

      await expectLater(
        repo.updateOrderStatus('ne-postoji', OrderStatus.accepted),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          ErrorType.notFound,
        )),
      );
    });

    test('archiveOrderByBuyer salje PATCH sa buyer_id filterom', () async {
      http.BaseRequest? patchReq;
      String? patchBody;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/orders')) {
          patchReq = req;
          patchBody = body;
          return _jsonResponse('[]', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await repo.archiveOrderByBuyer('b1', 'o1');

      expect(patchReq!.method, 'PATCH');
      expect(patchReq!.url.query, contains('id=eq.o1'));
      expect(patchReq!.url.query, contains('buyer_id=eq.b1'));
      expect(jsonDecode(patchBody!)['status'], 'archived');
    });

    test('archiveOrderBySeller salje PATCH sa seller_id filterom', () async {
      http.BaseRequest? patchReq;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/orders')) {
          patchReq = req;
          return _jsonResponse('[]', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await repo.archiveOrderBySeller('s1', 'o1');

      expect(patchReq!.method, 'PATCH');
      expect(patchReq!.url.query, contains('seller_id=eq.s1'));
    });

    test('archiveOrder poziva archive_order RPC', () async {
      String? rpcPath;
      String? rpcBody;
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          rpcPath = req.url.path;
          rpcBody = body;
          return _jsonResponse('null', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await repo.archiveOrder('o1');

      expect(rpcPath, contains('archive_order'));
      expect((jsonDecode(rpcBody!) as Map)['p_order_id'], 'o1');
    });

    test('confirmOrderReceivedByBuyer prolazi kada RPC vrati true', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse('true', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await repo.confirmOrderReceivedByBuyer('o1');
    });

    test('confirmOrderReceivedByBuyer baca gresku kada RPC ne vrati true',
        () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('/rpc/')) {
          return _jsonResponse('false', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await expectLater(
        repo.confirmOrderReceivedByBuyer('o1'),
        throwsA(isA<AppError>()),
      );
    });
  });
}
