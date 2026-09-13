import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/core/notification_types.dart';
import 'package:mleko/services/communication/push_service.dart';
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
  group('PushService Deduplication & Notification IDs', () {
    test('computeNotificationId returns deterministic ID for duplicate notifications', () {
      final id1 = PushService.computeNotificationId(
        type: 'new_message',
        orderId: '',
        title: 'Nova poruka od Petra',
        body: 'Zdravo, da li je sir još dostupan?',
      );

      final id2 = PushService.computeNotificationId(
        type: 'new_message',
        orderId: '',
        title: 'Nova poruka od Petra',
        body: 'Zdravo, da li je sir još dostupan?',
      );

      expect(id1, equals(id2));
      expect(id1, isNonNegative);
      expect(id1, lessThan(2147483647));
    });

    test('computeNotificationId produces distinct IDs for different notifications', () {
      final msgId = PushService.computeNotificationId(
        type: 'new_message',
        orderId: 'order-1',
        title: 'Poruka',
        body: 'Tekst 1',
      );

      final orderId = PushService.computeNotificationId(
        type: 'order_status_changed',
        orderId: 'order-1',
        title: 'Poruka',
        body: 'Tekst 1',
      );

      final diffBodyId = PushService.computeNotificationId(
        type: 'new_message',
        orderId: 'order-1',
        title: 'Poruka',
        body: 'Tekst 2',
      );

      expect(msgId, isNot(equals(orderId)));
      expect(msgId, isNot(equals(diffBodyId)));
    });

    test('channel routing separates order events from chat/general notifications', () {
      // Order types must map to order channel
      expect(notificationTypeIsOrderRelated('new_order'), isTrue);
      expect(notificationTypeIsOrderRelated('order_status'), isTrue);
      expect(notificationTypeIsOrderRelated('order_status_changed'), isTrue);

      // Classified and chat notifications must not map to order channel
      expect(notificationTypeIsOrderRelated('new_message'), isFalse);
      expect(notificationTypeIsOrderRelated('chat_message'), isFalse);
      expect(notificationTypeIsOrderRelated('classified_saved_search'), isFalse);
      expect(notificationTypeIsOrderRelated('new_classified_ad'), isFalse);
      expect(notificationTypeIsOrderRelated('classified_ad_moderation'), isFalse);
      expect(notificationTypeIsOrderRelated('system_alert'), isFalse);
      expect(notificationTypeIsOrderRelated(''), isFalse);
      expect(notificationTypeIsOrderRelated(null), isFalse);

      // Classifieds routing helper
      expect(notificationTypeIsClassifiedRelated('classified_saved_search'), isTrue);
      expect(notificationTypeIsClassifiedRelated('new_classified_ad'), isTrue);
      expect(notificationTypeIsClassifiedRelated('classified_ad_moderation'), isTrue);
      expect(notificationTypeIsClassifiedRelated('new_order'), isFalse);
      expect(notificationTypeIsClassifiedRelated(null), isFalse);
    });
  });

  group('PushService Registration Lifecycle & Generation Dedup', () {
    setUp(() async {
      await PushService.clearRegistrationState();
    });

    test('clearRegistrationState increments generation and resets active user', () async {
      final initialGen = PushService.registrationGeneration;
      expect(PushService.registeredUserId, isNull);

      await PushService.clearRegistrationState();
      expect(PushService.registrationGeneration, equals(initialGen + 1));
      expect(PushService.registeredUserId, isNull);
    });

    test('isCurrentRegistration verifies generation and user match', () async {
      final gen = PushService.registrationGeneration;

      // Stale generation is rejected
      expect(PushService.isCurrentRegistration(gen - 1, 'user-123'), isFalse);
      // Future generation is rejected
      expect(PushService.isCurrentRegistration(gen + 1, 'user-123'), isFalse);
      // Mismatched user is rejected
      expect(PushService.isCurrentRegistration(gen, 'user-999'), isFalse);
    });

    test('removeOtherUsersForInstallation sends delete query for other users on same installation', () async {
      String? deletedTable;
      String? queryParams;

      final client = _FakeHttpClient((req) async {
        if (req.method == 'DELETE' && req.url.path.contains('user_push_tokens')) {
          deletedTable = 'user_push_tokens';
          queryParams = req.url.query;
          return http.Response('', 204, request: req);
        }
        return http.Response('Not Found', 404, request: req);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-anon-key',
        httpClient: client,
      );

      final pushService = PushService(client: supabase);
      await pushService.removeOtherUsersForInstallation('inst-device-777', 'user-active-1');

      expect(deletedTable, equals('user_push_tokens'));
      expect(queryParams, contains('installation_id=eq.inst-device-777'));
      expect(queryParams, contains('user_id=neq.user-active-1'));
    });

    test('DI constructor returns consistent instance and accepts client', () {
      final p1 = PushService();
      final p2 = PushService();
      expect(identical(p1, p2), isTrue);

      final custom = PushService(client: null);
      expect(custom, isNotNull);
    });
  });
}
