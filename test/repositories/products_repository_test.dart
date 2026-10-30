import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/repositories/catalog/products_repository.dart';

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

Map<String, dynamic> productJson(String id, {String sellerId = 's1'}) => {
      'id': id,
      'seller_id': sellerId,
      'category': 'mlecni',
      'name': 'Domaci sir',
      'price_per_kg': 1200,
      'min_order_kg': 0.5,
      'order_step': 0.5,
      'available_kg': 10,
      'unit_type': 'kg',
      'description': 'Prirodno domaci.',
      'image_urls': <String>[],
      'pickup_options': <String>[],
      'location': 'Beograd',
      'is_domestic': true,
      'available_now': true,
      'delivery_mode': null,
      'created_at': '2026-01-02T10:00:00Z',
    };

SupabaseProductsRepository repoFor(
  Future<http.Response> Function(http.BaseRequest, String) handler,
) =>
    SupabaseProductsRepository(
      client: SupabaseClient(
        'https://fake.supabase.co',
        'fake-key',
        httpClient: MockHttpHandlerClient(handler),
      ),
    );

void main() {
  group('SupabaseProductsRepository — citanje', () {
    test('getProduct ucitava proizvod iz products_with_ratings view-a',
        () async {
      final requests = <String>[];
      final repo = repoFor((req, body) async {
        requests.add(req.url.path);
        return _jsonResponse(jsonEncode(productJson('p1')), 200);
      });

      final product = await repo.getProduct('p1');

      expect(product, isNotNull);
      expect(product!.id, 'p1');
      expect(product.name, 'Domaci sir');
      // Odgovor je stigao iz view-a — products tabela nije ni dotaknuta.
      expect(requests.single, contains('products_with_ratings'));
    });

    test('getProduct pada nazad na products tabelu kada view pukne',
        () async {
      final requests = <String>[];
      final repo = repoFor((req, body) async {
        requests.add(req.url.path);
        if (req.url.path.contains('products_with_ratings')) {
          return _jsonResponse(
            jsonEncode({'message': 'view does not exist'}),
            500,
          );
        }
        return _jsonResponse(jsonEncode(productJson('p1')), 200);
      });

      final product = await repo.getProduct('p1');

      expect(product, isNotNull);
      expect(product!.id, 'p1');
      // Prvo view, pa fallback na products tabelu.
      expect(requests.length, 2);
      expect(requests.first, contains('products_with_ratings'));
      expect(requests.last, endsWith('/products'));
    });

    test(
        'getProduct vraca null kada proizvod ne postoji ni u view-u ni u tabeli',
        () async {
      final repo = repoFor((req, body) async => _jsonResponse('[]', 200));

      expect(await repo.getProduct('ne-postoji'), isNull);
    });

    test('getProductById je alias za getProduct', () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('products_with_ratings')) {
          return _jsonResponse(jsonEncode(productJson('p7')), 200);
        }
        return _jsonResponse('[]', 200);
      });

      expect((await repo.getProductById('p7'))?.id, 'p7');
    });

    test('getProductsByIds sa praznom listom ne salje ni jedan zahtev',
        () async {
      final requests = <http.BaseRequest>[];
      final repo = repoFor((req, body) async {
        requests.add(req);
        return _jsonResponse('[]', 200);
      });

      final products = await repo.getProductsByIds(const []);

      expect(products, isEmpty);
      expect(requests, isEmpty);
    });

    test('getProductsByIds mapira redove iz products tabele', () async {
      http.BaseRequest? productsReq;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          productsReq = req;
          return _jsonResponse(
            jsonEncode([productJson('p1'), productJson('p2')]),
            200,
          );
        }
        return _jsonResponse('[]', 200);
      });

      final products = await repo.getProductsByIds(['p1', 'p2']);

      expect(products.length, 2);
      expect(products.map((p) => p.id), containsAll(['p1', 'p2']));
      expect(productsReq!.url.query, contains('id=in.'));
    });
  });

  group('SupabaseProductsRepository — kategorije i prodavci', () {
    test(
        'getProductsByCategories sa praznim kategorijama vraca praznu listu bez poziva',
        () async {
      final requests = <http.BaseRequest>[];
      final repo = repoFor((req, body) async {
        requests.add(req);
        return _jsonResponse('[]', 200);
      });

      final result = await repo.getProductsByCategories(categoryNames: const []);

      expect(result.items, isEmpty);
      expect(result.hasMore, isFalse);
      expect(requests, isEmpty);
    });

    test('getProductsByCategories postavlja hasMore=true kada je strana puna',
        () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('products_with_ratings')) {
          return _jsonResponse(
            jsonEncode([productJson('p1'), productJson('p2')]),
            200,
          );
        }
        return _jsonResponse('[]', 200);
      });

      final result = await repo.getProductsByCategories(
        categoryNames: ['mlecni'],
        limit: 2,
      );

      expect(result.items.length, 2);
      expect(result.hasMore, isTrue);
    });

    test(
        'getProductsByCategories postavlja hasMore=false kada ima manje od limita',
        () async {
      final repo = repoFor((req, body) async {
        if (req.url.path.contains('products_with_ratings')) {
          return _jsonResponse(jsonEncode([productJson('p1')]), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final result = await repo.getProductsByCategories(
        categoryNames: ['mlecni'],
        limit: 2,
      );

      expect(result.items.length, 1);
      expect(result.hasMore, isFalse);
    });

    test('getProductsBySeller filtrira po seller_id', () async {
      http.BaseRequest? productsReq;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          productsReq = req;
          return _jsonResponse(
              jsonEncode([productJson('p1', sellerId: 's9')]), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final products = await repo.getProductsBySeller('s9');

      expect(products.single.sellerId, 's9');
      expect(productsReq!.url.query, contains('seller_id=eq.s9'));
    });
  });

  group('SupabaseProductsRepository — perzistencija', () {
    ProductModel modelFor(String id) => ProductModel(
          id: id,
          sellerId: 's1',
          category: 'mlecni',
          name: 'Domaci sir',
          pricePerKg: 1200,
          minOrderKg: 0.5,
          orderStep: 0.5,
          availableKg: 10,
          unitType: 'kg',
          description: 'Prirodno domaci.',
          imageUrls: const [],
          pickupOptions: const [],
          location: 'Beograd',
          createdAt: DateTime(2026, 1, 2),
        );

    test('createProduct salje INSERT sa toDbMap i vraca kreirani model',
        () async {
      http.BaseRequest? insertReq;
      String? insertBody;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          insertReq = req;
          insertBody = body;
          return _jsonResponse(jsonEncode(productJson('p-new')), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final created = await repo.createProduct(modelFor('p-new'));

      expect(created.id, 'p-new');
      expect(created.name, 'Domaci sir');
      expect(insertReq!.method, 'POST');
      final sent = jsonDecode(insertBody!) as Map<String, dynamic>;
      expect(sent['seller_id'], 's1');
      expect(sent['order_step'], 0.5);
      expect(sent['unit_type'], 'kg');
    });

    test('updateProduct salje PATCH bez id i created_at polja', () async {
      http.BaseRequest? updateReq;
      String? updateBody;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          updateReq = req;
          updateBody = body;
          return _jsonResponse(jsonEncode(productJson('p1')), 200);
        }
        return _jsonResponse('[]', 200);
      });

      final updated = await repo.updateProduct(modelFor('p1'));

      expect(updated.id, 'p1');
      expect(updateReq!.method, 'PATCH');
      expect(updateReq!.url.query, contains('id=eq.p1'));
      final sent = jsonDecode(updateBody!) as Map<String, dynamic>;
      expect(sent.containsKey('id'), isFalse);
      expect(sent.containsKey('created_at'), isFalse);
      expect(sent['name'], 'Domaci sir');
    });

    test('deleteProduct salje DELETE sa id filterom', () async {
      http.BaseRequest? deleteReq;
      final repo = repoFor((req, body) async {
        if (req.url.path.endsWith('/products')) {
          deleteReq = req;
          return _jsonResponse('[]', 200);
        }
        return _jsonResponse('[]', 200);
      });

      await repo.deleteProduct('p1');

      expect(deleteReq!.method, 'DELETE');
      expect(deleteReq!.url.query, contains('id=eq.p1'));
    });
  });
}
