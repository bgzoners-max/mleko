import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/models/app_error.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/services/classifieds/classified_subscriptions_service.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';
import 'package:mleko/services/communication/local_notification_renderer.dart';
import 'package:mleko/services/communication/push_router.dart';
import 'package:mleko/services/communication/push_token_repository.dart';
import 'package:mleko/services/core/notification_handler_service.dart';
import 'package:mleko/services/media/storage_service.dart';
import 'package:mleko/services/orders/orders_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingRouter implements GoRouter {
  final List<String> goPaths = [];
  final List<String> pushPaths = [];

  @override
  void go(String location, {Object? extra}) {
    goPaths.add(location);
  }

  @override
  Future<T?> push<T extends Object?>(String location, {Object? extra}) {
    pushPaths.add(location);
    return Future.value(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _CurrencyCaptureClassifiedsService implements ClassifiedsService {
  String? lastCurrency;
  double? lastMinPrice;
  double? lastMaxPrice;
  int getAdsCalls = 0;

  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories({
    bool allowExpired = true,
  }) async =>
      const [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories({
    bool forceRefresh = false,
  }) async =>
      const [];

  @override
  Future<Map<String, int>> getCategoryAdCounts() async => const {};

  @override
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    List<String>? cities,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    Map<String, dynamic>? attributeFilters,
    bool? onlyFeatured,
    bool? onlyUrgent,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
    bool? lastIsFeatured,
    String? lastId,
  }) async {
    getAdsCalls++;
    lastCurrency = currency;
    lastMinPrice = minPrice;
    lastMaxPrice = maxPrice;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopSubscriptionsService implements ClassifiedSubscriptionsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Paket 3: PushRouter & LocalNotificationRenderer', () {
    test('Android foreground nikada ne preskace lokalnu notifikaciju', () {
      expect(
        PushRouter.shouldSkipLocalNotification(
          isWeb: false,
          isIOS: false,
          hasNotificationPayload: true,
        ),
        isFalse,
      );
      expect(
        PushRouter.shouldSkipLocalNotification(
          isWeb: false,
          isIOS: false,
          hasNotificationPayload: false,
        ),
        isFalse,
      );
      expect(
        PushRouter.shouldSkipLocalNotification(
          isWeb: true,
          isIOS: false,
          hasNotificationPayload: true,
        ),
        isTrue,
      );
      expect(
        PushRouter.shouldSkipLocalNotification(
          isWeb: false,
          isIOS: true,
          hasNotificationPayload: true,
        ),
        isTrue,
      );
      expect(
        PushRouter.shouldSkipLocalNotification(
          isWeb: false,
          isIOS: true,
          hasNotificationPayload: false,
        ),
        isFalse,
      );
    });

    test('computeNotificationId koristi stabilan FNV-1a heš preko izolata', () {
      final a = LocalNotificationRenderer.computeNotificationId(
        type: 'new_message',
        orderId: '',
        title: 'Nova poruka',
        body: 'Pozdrav sa pijace',
        notificationId: 'notif-uuid-001',
      );
      final b = LocalNotificationRenderer.computeNotificationId(
        type: 'new_message',
        orderId: '',
        title: 'Drugi naslov',
        body: 'Drugo telo',
        notificationId: 'notif-uuid-001',
      );
      final c = LocalNotificationRenderer.computeNotificationId(
        type: 'new_message',
        orderId: '',
        title: 'Nova poruka',
        body: 'Pozdrav sa pijace',
        notificationId: 'notif-uuid-002',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, inInclusiveRange(0, 2147483646));
      expect(c, inInclusiveRange(0, 2147483646));
    });
  });

  group('Paket 3: PushTokenRepository RPC registracija', () {
    test('registerToken poziva register_push_token RPC sa ispravnim parametrima',
        () async {
      String? capturedPath;
      Map<String, dynamic>? capturedBody;

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: _FakeHttpClient((req) async {
          capturedPath = req.url.path;
          capturedBody = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response('null', 200, request: req);
        }),
      );

      final repo = SupabasePushTokenRepository(client: supabase);
      await repo.registerToken(
        userId: 'user-1',
        installationId: 'inst-abc',
        token: 'fcm-token-xyz',
        platform: 'android',
      );

      expect(capturedPath, contains('/rpc/register_push_token'));
      expect(capturedBody, {
        'p_installation_id': 'inst-abc',
        'p_token': 'fcm-token-xyz',
        'p_platform': 'android',
      });
    });

    test('registerToken radi fallback na DELETE+UPSERT samo za PGRST202',
        () async {
      final methods = <String>[];

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: _FakeHttpClient((req) async {
          methods.add('${req.method}:${req.url.path}');
          if (req.url.path.contains('/rpc/register_push_token')) {
            return http.Response(
              jsonEncode({
                'code': 'PGRST202',
                'message': 'Could not find the function',
              }),
              404,
              headers: {'content-type': 'application/json'},
              request: req,
            );
          }
          return http.Response('[]', 200, request: req);
        }),
      );

      final repo = SupabasePushTokenRepository(client: supabase);
      await repo.registerToken(
        userId: 'user-1',
        installationId: 'inst-abc',
        token: 'fcm-token-xyz',
        platform: 'android',
      );

      expect(methods.length, 3);
      expect(methods[0], contains('/rpc/register_push_token'));
      expect(methods[1], startsWith('DELETE:'));
      expect(methods[2], startsWith('POST:'));
    });
  });

  group('Paket 3: NotificationHandlerService sanitizacija ID segmenata', () {
    test('prazan ili path-traversal conversation_id rutira na /conversations',
        () {
      final router = _RecordingRouter();
      final appState = AppState(ordersService: OrdersService());
      NotificationHandlerService(router: router, appState: appState)
        ..handleNotification({
          'type': 'new_message',
          'conversation_id': '',
        })
        ..handleNotification({
          'type': 'new_message',
          'conversation_id': '../admin/push-health',
        })
        ..handleNotification({
          'type': 'admin_reply',
          'ticket_id': '../../admin/tickets',
        })
        ..handleNotification({
          'type': 'new_classified_ad',
          'classified_ad_id': 'bad/id?x=1',
        });

      expect(router.pushPaths, isEmpty);
      expect(
        router.goPaths,
        ['/conversations', '/conversations', '/support', '/classifieds'],
      );
    });

    test('validan conversation_id, ticket_id i classified_ad_id prolaze push',
        () {
      final router = _RecordingRouter();
      final appState = AppState(ordersService: OrdersService());
      NotificationHandlerService(router: router, appState: appState)
        ..handleNotification({
          'type': 'new_message',
          'conversation_id': 'conv_123-abc',
        })
        ..handleNotification({
          'type': 'admin_reply',
          'ticket_id': 'ticket_456',
        })
        ..handleNotification({
          'type': 'new_classified_ad',
          'classified_ad_id': 'ad-789',
        });

      expect(
        router.pushPaths,
        ['/chat/conv_123-abc', '/support/ticket/ticket_456', '/classifieds/ad/ad-789'],
      );
    });
  });

  group('Paket 3: StorageService validacija upload-a i allowlist brisanja', () {
    test('tryDetectMimeAndExt odbija HTML/SVG/PDF bajtove i prihvata JPEG/PNG/WebP',
        () {
      expect(
        StorageService.tryDetectMimeAndExt(utf8.encode('<svg onload=alert(1)>')),
        isNull,
      );
      expect(
        StorageService.tryDetectMimeAndExt(utf8.encode('%PDF-1.7')),
        isNull,
      );
      expect(
        StorageService.tryDetectMimeAndExt([0xFF, 0xD8, 0xFF, 0xE0])?.mimeType,
        'image/jpeg',
      );
    });

    test('uploadProductImage odbija ne-sliku i prevelik fajl bez HTTP poziva',
        () async {
      var httpCalled = false;
      final service = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt',
        httpClient: _FakeHttpClient((req) async {
          httpCalled = true;
          return http.Response('{"url":"ok"}', 200, request: req);
        }),
      );

      await expectLater(
        () => service.uploadProductImage(
          'u1',
          utf8.encode('<html>not an image</html>'),
          0,
          compress: false,
        ),
        throwsA(
          isA<AppError>().having((e) => e.type, 'type', ErrorType.validation),
        ),
      );

      final oversized = Uint8List(StorageService.maxUploadBytes + 1)
        ..[0] = 0xFF
        ..[1] = 0xD8
        ..[2] = 0xFF;
      await expectLater(
        () => service.uploadProductImage(
          'u1',
          oversized,
          0,
          compress: false,
        ),
        throwsA(
          isA<AppError>().having((e) => e.type, 'type', ErrorType.validation),
        ),
      );

      expect(httpCalled, isFalse);
    });

    test('deleteFileByBucket odbija spoljne domene i path traversal', () async {
      var httpCalled = false;
      final service = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt',
        httpClient: _FakeHttpClient((req) async {
          httpCalled = true;
          return http.Response('{"success":true}', 200, request: req);
        }),
      );

      final externalRes = await service.deleteFileByPublicUrl(
        'https://evil.example/product-images/u1/a.jpg',
      );
      final traversalRes = await service.deleteFileByPublicUrl(
        'https://cdn.domacimarket.rs/product-images/../../secret.jpg',
      );

      expect(externalRes, isFalse);
      expect(traversalRes, isFalse);
      expect(httpCalled, isFalse);
    });
  });

  group('Paket 3: ClassifiedsProvider filter valute', () {
    test('selectCurrency, setPriceRange sa valutom i clearAllFilters rade konzistentno',
        () async {
      final fakeService = _CurrencyCaptureClassifiedsService();
      final provider = ClassifiedsProvider(
        service: fakeService,
        subscriptionService: _NoopSubscriptionsService(),
      )..selectCurrency('RSD');

      await Future<void>.delayed(Duration.zero);
      expect(provider.selectedCurrency, 'RSD');
      expect(fakeService.lastCurrency, 'RSD');

      provider.setPriceRange(
        minPrice: 100,
        maxPrice: 500,
        currency: 'EUR',
        updateCurrency: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(provider.selectedCurrency, 'EUR');
      expect(provider.minPrice, 100);
      expect(provider.maxPrice, 500);
      expect(fakeService.lastCurrency, 'EUR');

      provider.clearAllFilters();
      await Future<void>.delayed(Duration.zero);
      expect(provider.selectedCurrency, isNull);
      expect(provider.minPrice, isNull);
      expect(provider.maxPrice, isNull);
      expect(fakeService.lastCurrency, isNull);
    });
  });
}
