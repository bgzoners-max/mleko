import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/communication/push_health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  group('PushHealthService RPC tests', () {
    test('fetchDashboard calls admin_get_push_health_dashboard RPC and parses fields',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/admin_get_push_health_dashboard') &&
            req.method == 'POST') {
          return http.Response(
            jsonEncode([
              {
                'checked_at': '2026-09-17T14:00:00Z',
                'health': 'ok',
                'edge_config_ok': true,
                'functions_base_url': 'https://api.example.com',
                'anon_key_present': true,
                'total_tokens': 150,
                'users_with_tokens': 95,
                'tokens_created_24h': 12,
                'notifications_24h': 80,
                'deliveries_24h': 78,
                'successful_deliveries_24h': 76,
                'failed_deliveries_24h': 2,
                'success_rate_pct': 97.4,
                'last_notification_at': '2026-09-17T13:58:00Z',
                'last_delivery_at': '2026-09-17T13:59:00Z',
                'delivery_backlog_minutes': 0.5,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = PushHealthService(client: supabase);
      final dashboard = await service.fetchDashboard();

      expect(dashboard.health, equals('ok'));
      expect(dashboard.edgeConfigOk, isTrue);
      expect(dashboard.functionsBaseUrl, equals('https://api.example.com'));
      expect(dashboard.anonKeyPresent, isTrue);
      expect(dashboard.totalTokens, equals(150));
      expect(dashboard.usersWithTokens, equals(95));
      expect(dashboard.successfulDeliveries24h, equals(76));
      expect(dashboard.failedDeliveries24h, equals(2));
      expect(dashboard.successRatePct, equals(97.4));
      expect(dashboard.deliveryBacklogMinutes, equals(0.5));
    });

    test('fetchDashboard throws notFound AppError if returned list is empty',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/admin_get_push_health_dashboard')) {
          return http.Response(jsonEncode([]), 200);
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = PushHealthService(client: supabase);
      expect(
        () => service.fetchDashboard(),
        throwsA(isA<AppError>().having(
          (e) => e.type,
          'type',
          equals(ErrorType.notFound),
        )),
      );
    });

    test('fetchDashboard wraps permission denied exception in AppError',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/admin_get_push_health_dashboard')) {
          return http.Response(
            jsonEncode({
              'code': 'P0001',
              'message':
                  'Pristup odbijen: samo administratori mogu pristupiti push health dijagnostici.'
            }),
            400,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = PushHealthService(client: supabase);
      expect(
        () => service.fetchDashboard(),
        throwsA(isA<AppError>()),
      );
    });

    test('fetchUserIssues calls admin_get_push_health_user_issues RPC and maps models',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/admin_get_push_health_user_issues') &&
            req.method == 'POST') {
          return http.Response(
            jsonEncode([
              {
                'checked_at': '2026-09-17T14:00:00Z',
                'user_id': 'user-issue-1',
                'health': 'missing_token',
                'token_count': 0,
                'latest_token_at': null,
                'notifications_7d': 5,
                'latest_notification_at': '2026-09-17T12:00:00Z',
                'latest_delivery_at': null,
                'latest_delivery_status': 'failed',
                'latest_delivery_error_count': 3,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = PushHealthService(client: supabase);
      final issues = await service.fetchUserIssues();

      expect(issues.length, equals(1));
      expect(issues.first.userId, equals('user-issue-1'));
      expect(issues.first.health, equals('missing_token'));
      expect(issues.first.tokenCount, equals(0));
      expect(issues.first.notifications7d, equals(5));
      expect(issues.first.latestDeliveryStatus, equals('failed'));
      expect(issues.first.latestDeliveryErrorCount, equals(3));
    });

    test('fetchUserIssues wraps permission denied exception in AppError',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rpc/admin_get_push_health_user_issues')) {
          return http.Response(
            jsonEncode({
              'code': 'P0001',
              'message':
                  'Pristup odbijen: samo administratori mogu pristupiti podacima o problemima sa push notifikacijama korisnika.'
            }),
            400,
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = PushHealthService(client: supabase);
      expect(
        () => service.fetchUserIssues(),
        throwsA(isA<AppError>()),
      );
    });
  });
}
