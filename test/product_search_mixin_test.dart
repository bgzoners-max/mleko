import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/product_sort.dart';
import 'package:mleko/services/catalog/mixins/product_search_mixin.dart';
import 'package:mleko/services/catalog/product_cache_service.dart';

/// HTTP-level mock (isti obrazac kao order_management_mixin_test.dart).
class MockHttpHandlerClient extends http.BaseClient {
  final Future<http.Response> Function(
      http.BaseRequest request, String body) handler;
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

class _TestSearchService with ProductSearchMixin {
  @override
  final SupabaseClient client;

  _TestSearchService({required this.client});

  @override
  int compareProducts(ProductModel a, ProductModel b, ProductSort sort) {
    switch (sort) {
      case ProductSort.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case ProductSort.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case ProductSort.priceAsc:
        return a.pricePerKg.compareTo(b.pricePerKg);
      case ProductSort.priceDesc:
        return b.pricePerKg.compareTo(a.pricePerKg);
      case ProductSort.location:
        return a.location.compareTo(b.location);
      case ProductSort.ratingDesc:
        return 0;
    }
  }
}

Map<String, dynamic> _row(
  String id, {
  String name = 'Proizvod',
  String category = 'med',
  String unitType = 'kg',
  double price = 500,
  double minOrder = 0.5,
  String location = 'Valjevo',
  int? orderCount,
  double? avgRating,
  int? reviewCount,
}) =>
    {
      'id': id,
      'seller_id': 'seller-1',
      'category': category,
      'name': name,
      'price_per_kg': price,
      'min_order_kg': minOrder,
      'available_kg': 10,
      'unit_type': unitType,
      'location': location,
      if (orderCount != null) 'order_count': orderCount,
      if (avgRating != null) 'avg_rating': avgRating,
      if (reviewCount != null) 'review_count': reviewCount,
    };

/// JSON odgovor sa UTF-8 enkodiranjem (podržava srpske dijakritike u nazivima).
http.Response _jsonResponse(Object data) => http.Response.bytes(
      utf8.encode(jsonEncode(data)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getProductsPage — FTS RPC putanja (sa upitom)', () {
    test(
        'šalje search_products_fts RPC sa sanitizovanim parametrima i parsira redove',
        () async {
      SharedPreferences.setMockInitialValues({});
      String? rpcPath;
      String? rpcBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/search_products_fts')) {
          rpcPath = req.url.path;
          rpcBody = body;
          return _jsonResponse([
            _row('p-1',
                name: 'Domaći Sir',
                orderCount: 7,
                avgRating: 4.5,
                reviewCount: 10),
            _row('p-2',
                name: 'Kozji Sir Stari', avgRating: 5.0, reviewCount: 0),
            _row('p-3', name: 'Livadski Med'),
          ]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestSearchService(client: supabase);

      final page = await service.getProductsPage(
        searchQuery: 'sir',
        limit: 2,
        offset: 0,
      );

      // RPC je pozvan sa ocekivanim parametrima
      expect(rpcPath, isNotNull);
      expect(rpcBody, contains('"p_query":"sir"'));
      expect(rpcBody, contains('"p_limit":3')); // limit + 1 za hasMore
      expect(rpcBody, contains('"p_offset":0'));

      // 3 reda vracena, limit 2 => hasMore true i poslednji red odbacen
      expect(page.items.length, equals(2));
      expect(page.hasMore, isTrue);
      expect(page.items.first.id, equals('p-1'));
      expect(page.items.first.name, equals('Domaći Sir'));

      // salesCounts se popunjava za sve redove (default 0)
      expect(page.salesCounts['p-1'], equals(7));
      expect(page.salesCounts['p-2'], equals(0));

      // rating se beleži samo uz bar jednu recenziju
      expect(page.ratings['p-1'], isNotNull);
      expect(page.ratings['p-1']!.avg, equals(4.5));
      expect(page.ratings['p-1']!.count, equals(10));
      expect(page.ratings.containsKey('p-2'), isFalse);
      expect(page.ratings.containsKey('p-3'), isFalse);
    });

    test('prosleđuje kategoriju i region kao opciona RPC parametre', () async {
      SharedPreferences.setMockInitialValues({});
      String? rpcBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/search_products_fts')) {
          rpcBody = body;
          return http.Response('[]', 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestSearchService(client: supabase);

      await service.getProductsPage(
        searchQuery: 'sir',
        category: 'Mlecni proizvodi',
        region: 'Valjevo',
        availableNow: true,
        excludeSellerId: 'seller-x',
      );

      expect(rpcBody, contains('"p_category":"Mlecni proizvodi"'));
      expect(rpcBody, contains('"p_region":"Valjevo"'));
      expect(rpcBody, contains('"p_available_now":true'));
      expect(rpcBody, contains('"p_exclude_seller_id":"seller-x"'));
    });
  });

  group('getProductsPage — tabelarna upitna putanja (bez upita)', () {
    test('gradi filtrirani PostgREST upit sa sortiranjem i paginacijom',
        () async {
      SharedPreferences.setMockInitialValues({});
      http.BaseRequest? captured;
      String? capturedQuery;

      final mockClient = MockHttpHandlerClient((req, body) async {
        captured = req;
        capturedQuery = req.url.query;
        return _jsonResponse([
          _row('p-1', category: 'med', price: 500),
          _row('p-2', category: 'med', price: 700),
        ]);
      });
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = _TestSearchService(client: supabase);

      final page = await service.getProductsPage(
        searchQuery: null, // bez upita -> tabela products_with_ratings
        category: 'med',
        region: 'Valjevo',
        availableNow: true,
        minPrice: 100,
        maxPrice: 2000,
        sort: ProductSort.priceAsc,
        limit: 2,
        offset: 0,
      );

      // Upit ide na products_with_ratings sa svim filterima
      expect(captured!.url.path, contains('/rest/v1/products_with_ratings'));
      expect(capturedQuery, contains('category=eq.med'));
      expect(capturedQuery, contains('location=eq.Valjevo'));
      expect(capturedQuery, contains('available_now=eq.true'));
      expect(capturedQuery, contains('price_per_kg=gte.100'));
      expect(capturedQuery, contains('price_per_kg=lte.2000'));
      expect(capturedQuery, contains('order=price_per_kg.asc'));

      // Paginacija kroz query parametre offset/limit (postgrest v2 range())
      expect(capturedQuery, contains('offset=0'));
      expect(capturedQuery, contains('limit=3')); // limit + 1 za hasMore

      // 2 reda <= limit 2 => hasMore false
      expect(page.items.length, equals(2));
      expect(page.hasMore, isFalse);
      expect(page.items.map((p) => p.id).toList(), equals(['p-1', 'p-2']));
    });
  });

  group('searchCachedProductsPage — lokalna offline pretraga', () {
    late ProductModel pSirNovi;
    late ProductModel pSirStari;
    late ProductModel pMed;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // Statički memorijski keš mora biti izolovan između testova.
      ProductCacheService.clearMemoryCache();

      ProductModel cachedProduct({
        required String id,
        required String name,
        required String category,
        required String location,
        required double price,
        required DateTime createdAt,
      }) =>
          ProductModel(
            id: id,
            sellerId: 'seller-1',
            category: category,
            name: name,
            pricePerKg: price,
            unitType: ProductModel.unitKg,
            minOrderKg: 0.5,
            orderStep: 0.5,
            availableKg: 10,
            availableNow: true,
            description: '',
            imageUrls: const [],
            pickupOptions: const [],
            location: location,
            createdAt: createdAt,
          );

      pSirNovi = cachedProduct(
        id: 'p-sir-novi',
        name: 'Domaći Sir',
        category: 'sir',
        location: 'Valjevo',
        price: 1200,
        createdAt: DateTime(2026, 1, 2),
      );
      pSirStari = cachedProduct(
        id: 'p-sir-stari',
        name: 'Kozji Sir Stari',
        category: 'sir',
        location: 'Novi Sad',
        price: 900,
        createdAt: DateTime(2026, 1, 1),
      );
      pMed = cachedProduct(
        id: 'p-med',
        name: 'Livadski Med',
        category: 'med',
        location: 'Valjevo',
        price: 1500,
        createdAt: DateTime(2026, 1, 3),
      );

      final cache = ProductCacheService();
      // Ključevi moraju nositi prefiks "mleko_cache_" — getAllCachedProducts()
      // čita isključivo ključeve sa ovim prefiksom.
      await cache.cacheProducts(ProductCacheService.homeProductsKey, [pSirNovi, pSirStari]);
      await cache.cacheProducts(ProductCacheService.categoryKey('med'), [pMed]);
    });

    test(
        'token pretraga "sir" pronalazi obe vrste sira, paginira i postavlja hasMore',
        () async {
      final service =
          _TestSearchService(client: _offlineSupabase());

      final page1 = await service.searchCachedProductsPage(
        searchQuery: 'sir',
        limit: 1,
        offset: 0,
      );
      // dateDesc: Domaći Sir (2. jan) je noviji od Kozjeg (1. jan)
      expect(page1.items.length, equals(1));
      expect(page1.items.first.id, equals('p-sir-novi'));
      expect(page1.hasMore, isTrue);

      final page2 = await service.searchCachedProductsPage(
        searchQuery: 'sir',
        limit: 1,
        offset: 1,
      );
      expect(page2.items.length, equals(1));
      expect(page2.items.first.id, equals('p-sir-stari'));
      expect(page2.hasMore, isFalse);
    });

    test('dijakritici u upitu (domaci sir) se normalizuju prilikom pretrage',
        () async {
      final service = _TestSearchService(client: _offlineSupabase());

      // Tokeni ['domaci', 'sir'] moraju poklopiti "Domaći Sir" (obe reči),
      // a "Kozji Sir Stari" ispadaju jer nema "domaci" token.
      final page = await service.searchCachedProductsPage(
        searchQuery: 'domaci sir',
        limit: 10,
      );
      expect(page.items.length, equals(1));
      expect(page.items.first.id, equals('p-sir-novi'));
    });

    test('filtri kategorije, regiona i cene sužeuju lokalne rezultate',
        () async {
      final service = _TestSearchService(client: _offlineSupabase());

      // Kategorija + region: samo sir iz Valjeva
      final byRegion = await service.searchCachedProductsPage(
        category: 'sir',
        region: 'Valjevo',
        limit: 10,
      );
      expect(byRegion.items.map((p) => p.id).toList(), equals(['p-sir-novi']));

      // Cenovni raspon: sir skuplji od 1000 RSD
      final byPrice = await service.searchCachedProductsPage(
        category: 'sir',
        minPrice: 1000,
        limit: 10,
      );
      expect(byPrice.items.map((p) => p.id).toList(), equals(['p-sir-novi']));
    });

    test('sortiranje priceAsc sortira keširane rezultate po ceni', () async {
      final service = _TestSearchService(client: _offlineSupabase());

      final page = await service.searchCachedProductsPage(
        searchQuery: 'sir',
        sort: ProductSort.priceAsc,
        limit: 10,
      );
      // 900 (Kozji) < 1200 (Domaći)
      expect(page.items.map((p) => p.id).toList(),
          equals(['p-sir-stari', 'p-sir-novi']));
    });
  });
}

/// SupabaseClient koji nikada ne treba biti pozvan — keš pretraga je čisto
/// lokalna. Ako se ipak pošalje HTTP zahtev, vraća 500 da test padne glasno.
SupabaseClient _offlineSupabase() {
  final mockClient = MockHttpHandlerClient((req, body) async {
    return http.Response('{"error":"offline cache search must not hit network"}', 500);
  });
  return SupabaseClient('https://fake.supabase.co', 'fake-key',
      httpClient: mockClient);
}
