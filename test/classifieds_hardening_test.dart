import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;
  _FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await handler(request);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      request: request,
      headers: res.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Classifieds Categories Cache & TTL (P1)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ClassifiedsService.clearCategoriesCache();
    });

    test('getCachedCategories respects version 2 and fresh TTL (<24h)', () async {
      final prefs = await SharedPreferences.getInstance();
      final freshTime = DateTime.now().subtract(const Duration(hours: 2));

      final rawCategories = [
        {
          'id': 'poljoprivreda',
          'name': 'Poljoprivreda',
          'icon_name': 'agriculture',
          'parent_id': null,
          'sort_order': 1,
          'is_condition_applicable': true,
        },
      ];

      final payload = {
        'version': 2,
        'fetched_at': freshTime.toIso8601String(),
        'data': rawCategories,
      };

      await prefs.setString(
        'cached_classified_categories_payload_v2',
        jsonEncode(payload),
      );

      final service = ClassifiedsService.test();
      final cached = await service.getCachedCategories(allowExpired: false);

      expect(cached, isNotEmpty);
      expect(cached.first.id, 'poljoprivreda');
    });

    test('getCachedCategories ignores expired cache when allowExpired is false, but returns it when true', () async {
      final prefs = await SharedPreferences.getInstance();
      final expiredTime = DateTime.now().subtract(const Duration(hours: 25)); // > 24h

      final rawCategories = [
        {
          'id': 'nekretnine',
          'name': 'Nekretnine',
          'icon_name': 'home',
          'parent_id': null,
          'sort_order': 2,
          'is_condition_applicable': false,
        },
      ];

      final payload = {
        'version': 2,
        'fetched_at': expiredTime.toIso8601String(),
        'data': rawCategories,
      };

      await prefs.setString(
        'cached_classified_categories_payload_v2',
        jsonEncode(payload),
      );

      final service = ClassifiedsService.test();

      // Normal refresh check -> expired -> empty list
      final nonExpiredCheck = await service.getCachedCategories(allowExpired: false);
      expect(nonExpiredCheck, isEmpty);

      // Offline fallback -> returns even if expired
      final offlineFallback = await service.getCachedCategories(allowExpired: true);
      expect(offlineFallback, isNotEmpty);
      expect(offlineFallback.first.id, 'nekretnine');
    });

    test('getCachedCategories rejects incompatible cache versions', () async {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'version': 99, // Unknown / outdated schema
        'fetched_at': DateTime.now().toIso8601String(),
        'data': [
          {'id': 'test', 'name': 'Test', 'icon_name': 'star'},
        ],
      };

      await prefs.setString(
        'cached_classified_categories_payload_v2',
        jsonEncode(payload),
      );

      final service = ClassifiedsService.test();
      final cached = await service.getCachedCategories(allowExpired: true);
      expect(cached, isEmpty);
    });
  });

  group('Server-driven isConditionApplicable & Category Tree (P1)', () {
    test('buildCategoryTree uses server boolean and inherits false from parent', () {
      final rawData = [
        // Root: Nekretnine (server set to false)
        {
          'id': 'nekretnine',
          'name': 'Nekretnine',
          'icon_name': 'home',
          'parent_id': null,
          'sort_order': 1,
          'is_condition_applicable': false,
        },
        // Child under Nekretnine
        {
          'id': 'stanovi',
          'name': 'Stanovi',
          'icon_name': 'apartment',
          'parent_id': 'nekretnine',
          'sort_order': 1,
          'is_condition_applicable': false,
        },
        // Root: Poljoprivreda (server set to true)
        {
          'id': 'poljoprivreda',
          'name': 'Poljoprivreda',
          'icon_name': 'agriculture',
          'parent_id': null,
          'sort_order': 2,
          'is_condition_applicable': true,
        },
        // Child under Poljoprivreda: Traktori (true)
        {
          'id': 'traktori',
          'name': 'Traktori',
          'icon_name': 'agriculture',
          'parent_id': 'poljoprivreda',
          'sort_order': 1,
          'is_condition_applicable': true,
        },
      ];

      final tree = ClassifiedsService.buildCategoryTreeForTesting(rawData);

      final nekretnine = tree.firstWhere((c) => c.id == 'nekretnine');
      expect(nekretnine.isConditionApplicable, isFalse);
      expect(nekretnine.subcategories.first.isConditionApplicable, isFalse);

      final poljoprivreda = tree.firstWhere((c) => c.id == 'poljoprivreda');
      expect(poljoprivreda.isConditionApplicable, isTrue);
      expect(poljoprivreda.subcategories.first.isConditionApplicable, isTrue);
    });
  });

  group('Admin Guard on Promotional Statuses (P0)', () {
    test('updateAdFeatured throws Unauthorized when not logged in', () async {
      final client = _FakeHttpClient((req) async => http.Response('{}', 200));
      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: client,
      );

      final service = ClassifiedsService(client: supabase);

      expect(
        () => service.updateAdFeatured('ad-1', true),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            equals(ErrorType.unauthorized),
          ),
        ),
      );
    });

    test('updateAdUrgent throws Unauthorized when not logged in', () async {
      final client = _FakeHttpClient((req) async => http.Response('{}', 200));
      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: client,
      );

      final service = ClassifiedsService(client: supabase);

      expect(
        () => service.updateAdUrgent('ad-1', true),
        throwsA(
          isA<AppError>().having(
            (e) => e.type,
            'type',
            equals(ErrorType.unauthorized),
          ),
        ),
      );
    });
  });

  group('Telemetry & Silent Catch Elimination (P2)', () {
    setUp(() {
      ClassifiedsService.resetFailureCountsForTesting();
    });

    test('incrementViews tracks and logs RPC failure count', () async {
      expect(ClassifiedsService.failedViewsRpcCount, equals(0));
      expect(ClassifiedsService.totalRpcFailures, equals(0));

      // Simuliramo HTTP 500 RPC grešku
      final client = _FakeHttpClient((req) async {
        return http.Response('{"message": "RLS policy violation"}', 500);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: client,
      );

      final service = ClassifiedsService(client: supabase);

      await service.incrementViews('ad-err-1');
      expect(ClassifiedsService.failedViewsRpcCount, equals(1));
      expect(ClassifiedsService.totalRpcFailures, equals(1));

      // Druga greška
      await service.incrementViews('ad-err-2');
      expect(ClassifiedsService.failedViewsRpcCount, equals(2));
      expect(ClassifiedsService.totalRpcFailures, equals(2));
    });

    test('recordInteraction tracks and logs RPC failure count', () async {
      expect(ClassifiedsService.failedInteractionsRpcCount, equals(0));

      final client = _FakeHttpClient((req) async {
        return http.Response('{"message": "RPC not found"}', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: client,
      );

      final service = ClassifiedsService(client: supabase);

      await service.recordInteraction('ad-1', 'call');
      expect(ClassifiedsService.failedInteractionsRpcCount, equals(1));
      expect(ClassifiedsService.totalRpcFailures, equals(1));

      await service.recordInteraction('ad-2', 'share');
      expect(ClassifiedsService.failedInteractionsRpcCount, equals(2));
      expect(ClassifiedsService.totalRpcFailures, equals(2));
    });
  });
}
