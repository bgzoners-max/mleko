import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/core/utils/error_messages.dart';
import 'package:mleko/models/product_model.dart';
import 'package:mleko/models/user_model.dart';
import 'package:mleko/services/auth/users_service.dart';
import 'package:mleko/services/catalog/product_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._handler);

  final Future<http.Response> Function(http.Request req) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    final res = await _handler(req);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([res.bodyBytes]),
      res.statusCode,
      headers: res.headers,
      request: req,
    );
  }
}

void main() {
  group('Paket 5: friendlyError() razlikuje RLS 42501 od foreign key greske', () {
    test('RLS 42501 ("violates row-level security") vraca poruku o dozvoli', () {
      const rlsErr = PostgrestException(
        message: 'new row violates row-level security policy for table "orders"',
        code: '42501',
      );
      expect(
        friendlyError(rlsErr),
        'Nemaš dozvolu za ovu akciju. Prijavi se ponovo.',
      );
    });

    test('Check constraint ("violates check constraint") ne tvrdi da je zapis vezan za drugi', () {
      const checkErr = PostgrestException(
        message: 'new row for relation "orders" violates check constraint "orders_total_check"',
        code: '23514',
      );
      expect(
        friendlyError(checkErr),
        'Greška pri radu sa podacima. Pokušaj ponovo.',
      );
    });

    test('Foreign key ("violates foreign key constraint") vraca poruku o vezanom zapisu', () {
      const fkErr = PostgrestException(
        message: 'update or delete on table "products" violates foreign key constraint',
        code: '23503',
      );
      expect(
        friendlyError(fkErr),
        'Podatak je vezan za drugi zapis i ne može se obrisati.',
      );
    });
  });

  group('Paket 5: Profili — zastita uloge prodavca i brisanje poslednje slike galerije', () {
    test('Seller UserModel.toDbMap ukljucuje prazne liste galerije/tagova pri brisanju poslednje stavke', () {
      const seller = UserModel(
        id: 'seller-1',
        role: UserRole.seller,
        farmName: 'Gazdinstvo',
        farmGalleryUrls: ['https://cdn.domacimarket.rs/farm-gallery/s1/a.jpg'],
        sellerTags: ['Organsko'],
        sellerQuickReplies: ['Pozdrav'],
      );

      final cleared = seller.copyWith(
        farmGalleryUrls: const [],
        sellerTags: const [],
        sellerQuickReplies: const [],
      );
      final dbMap = cleared.toDbMap();

      expect(dbMap.containsKey('farm_gallery_urls'), isTrue);
      expect(dbMap['farm_gallery_urls'], isEmpty);
      expect(dbMap.containsKey('seller_tags'), isTrue);
      expect(dbMap['seller_tags'], isEmpty);
      expect(dbMap.containsKey('seller_quick_replies'), isTrue);
      expect(dbMap['seller_quick_replies'], isEmpty);
    });

    test('UsersService.updateBuyerProfile ne salje role=buyer na PATCH i ne degradira prodavca', () async {
      Map<String, dynamic>? patchedBody;

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: _FakeHttpClient((req) async {
          if (req.method == 'PATCH' && req.url.path.contains('/profiles')) {
            patchedBody = jsonDecode(req.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({'id': 'seller-123'}),
              200,
              headers: {'content-type': 'application/vnd.pgrst.object+json'},
              request: req,
            );
          }
          return http.Response('Not Found', 404, request: req);
        }),
      );

      final usersService = UsersService(client: supabase);
      await usersService.updateBuyerProfile(
        const BuyerProfile(
          id: 'seller-123',
          displayName: 'Domacin Marko',
          city: 'Valjevo',
          address: 'Selo Popucke bb',
          postalCode: '14000',
        ),
      );

      expect(patchedBody, isNotNull);
      expect(patchedBody!.containsKey('role'), isFalse);
      expect(patchedBody!['display_name'], 'Domacin Marko');
      expect(patchedBody!['address'], 'Selo Popucke bb');
    });
  });

  group('Paket 5: ProductCacheService.invalidateProduct cisti i category/search keseve', () {
    test('invalidateProduct uklanja home, category, search, product i seller kljuceve', () async {
      SharedPreferences.setMockInitialValues({});
      ProductCacheService.clearMemoryCache();
      final cache = ProductCacheService();

      final sampleProduct = ProductModel(
        id: 'p-1',
        sellerId: 's-1',
        category: 'Sirevi',
        name: 'Kajmak',
        pricePerKg: 1200,
        minOrderKg: 1,
        availableKg: 10,
        description: 'Domaci kajmak',
        imageUrls: const [],
        pickupOptions: const ['Licno'],
        location: 'Zlatibor',
        createdAt: DateTime(2026, 1, 1),
      );

      await cache.cacheProduct(sampleProduct);
      await cache.cacheProducts(ProductCacheService.homeProductsKey, [sampleProduct]);
      await cache.cacheProducts('${ProductCacheService.homeProductsKey}_Zlatibor_cat_Sirevi', [sampleProduct]);
      await cache.cacheProducts(ProductCacheService.categoryKey('Sirevi'), [sampleProduct]);
      await cache.cacheProducts(ProductCacheService.searchKey('kajmak'), [sampleProduct]);
      await cache.cacheProducts(ProductCacheService.sellerKey('s-1'), [sampleProduct]);

      await cache.invalidateProduct('p-1', 's-1');

      expect(await cache.getCachedProduct('p-1'), isNull);
      expect(await cache.getCachedProducts(ProductCacheService.homeProductsKey), isNull);
      expect(
        await cache.getCachedProducts('${ProductCacheService.homeProductsKey}_Zlatibor_cat_Sirevi'),
        isNull,
      );
      expect(await cache.getCachedProducts(ProductCacheService.categoryKey('Sirevi')), isNull);
      expect(await cache.getCachedProducts(ProductCacheService.searchKey('kajmak')), isNull);
      expect(await cache.getCachedProducts(ProductCacheService.sellerKey('s-1')), isNull);
    });
  });
}
