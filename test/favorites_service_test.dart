import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/services/social/favorites_service.dart';

http.Response _jsonResponse(String body, [int status = 200]) =>
    http.Response(body, status,
        headers: {'content-type': 'application/json; charset=utf-8'});

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

void main() {
  FavoritesService serviceFor(MockHttpHandlerClient mock) => FavoritesService(
      client: SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mock));

  group('FavoritesService — čitanje omiljenih', () {
    test('getFavoriteProductIds mapira product_id iz favorites tabele',
        () async {
      http.BaseRequest? favReq;
      final mock = MockHttpHandlerClient((req, body) async {
        favReq = req;
        return _jsonResponse(jsonEncode([
          {'product_id': 'p1'},
          {'product_id': 'p2'},
        ]));
      });
      final service = serviceFor(mock);

      final ids = await service.getFavoriteProductIds('u1');

      expect(ids, ['p1', 'p2']);
      expect(favReq!.url.path, contains('/favorites'));
      expect(favReq!.url.query, contains('user_id=eq.u1'));
      expect(favReq!.url.query, contains('select=product_id'));
    });

    test(
        'getFavoriteProductIds vraća praznu listu kada tabela ne postoji (PGRST205)',
        () async {
      final mock = MockHttpHandlerClient((req, body) async => _jsonResponse(
          jsonEncode({'code': 'PGRST205', 'message': 'table not found'}), 404));
      final service = serviceFor(mock);

      expect(await service.getFavoriteProductIds('u1'), isEmpty);
    });

    test('getFavoriteProductIds propaguje neočekivane greške', () async {
      final mock = MockHttpHandlerClient((req, body) async =>
          _jsonResponse(jsonEncode({'message': 'server error'}), 500));
      final service = serviceFor(mock);

      await expectLater(
          service.getFavoriteProductIds('u1'), throwsA(isA<Exception>()));
    });

    test('isFavorite vraća true kada red postoji', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/favorites')) {
          return _jsonResponse(jsonEncode({'id': 'f1'}));
        }
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.isFavorite('u1', 'p1'), isTrue);
    });

    test('isFavorite vraća false kada red ne postoji', () async {
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/favorites')) return _jsonResponse('[]');
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      expect(await service.isFavorite('u1', 'p1'), isFalse);
    });

    test('isFavorite vraća false kada tabela ne postoji (PGRST205)', () async {
      final mock = MockHttpHandlerClient((req, body) async => _jsonResponse(
          jsonEncode({
            'code': 'PGRST205',
            'message': 'table not found',
            'details': 'schema cache miss',
            'hint': 'check the table name',
          }),
          404));
      final service = serviceFor(mock);

      expect(await service.isFavorite('u1', 'p1'), isFalse);
    });
  });

  group('FavoritesService — upis i brisanje', () {
    test('addFavorite upisuje user_id i product_id', () async {
      String? insertBody;
      String? insertPath;
      final mock = MockHttpHandlerClient((req, body) async {
        insertBody = body;
        insertPath = req.url.path;
        return _jsonResponse('[]', 201);
      });
      final service = serviceFor(mock);

      await service.addFavorite('u1', 'p1');

      expect(insertPath, contains('/favorites'));
      final json = jsonDecode(insertBody!) as Map<String, dynamic>;
      expect(json['user_id'], 'u1');
      expect(json['product_id'], 'p1');
    });

    test('removeFavorite briše po user_id i product_id filteru', () async {
      http.BaseRequest? deleteReq;
      final mock = MockHttpHandlerClient((req, body) async {
        deleteReq = req;
        return _jsonResponse('[]', 200);
      });
      final service = serviceFor(mock);

      await service.removeFavorite('u1', 'p1');

      expect(deleteReq!.method, 'DELETE');
      expect(deleteReq!.url.path, contains('/favorites'));
      expect(deleteReq!.url.query, contains('user_id=eq.u1'));
      expect(deleteReq!.url.query, contains('product_id=eq.p1'));
    });

    test('getFavoriteProducts ne poziva products kada nema omiljenih',
        () async {
      final requests = <http.BaseRequest>[];
      final mock = MockHttpHandlerClient((req, body) async {
        requests.add(req);
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      final products = await service.getFavoriteProducts('u1');

      expect(products, isEmpty);
      expect(requests.any((r) => r.url.path.contains('/products')), isFalse);
    });

    test('getFavoriteProducts povlači proizvode preko inFilter', () async {
      http.BaseRequest? productsReq;
      final mock = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/favorites')) {
          return _jsonResponse(jsonEncode([
            {'product_id': 'p1'},
            {'product_id': 'p2'},
          ]));
        }
        productsReq = req;
        return _jsonResponse('[]');
      });
      final service = serviceFor(mock);

      await service.getFavoriteProducts('u1');

      expect(productsReq, isNotNull);
      expect(productsReq!.url.path, contains('/products'));
      // Query je URL-enkodovan, pa proveravamo samo prefiks in. filtera.
      expect(productsReq!.url.query, contains('id=in.'));
    });
  });
}
