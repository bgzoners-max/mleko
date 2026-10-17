import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/communication/chat_service.dart';

/// HTTP-level mock (isti obrazac kao chat_service_test.dart).
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

/// JSON odgovor sa UTF-8 enkodiranjem (srpski dijakritiki u telu poruka).
http.Response _jsonResponse(Object data) => http.Response.bytes(
      utf8.encode(jsonEncode(data)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> _msgJson(
  String id,
  String body, {
  String senderId = 'buyer-1',
  DateTime? createdAt,
}) =>
    {
      'id': id,
      'conversation_id': 'conv-1',
      'sender_id': senderId,
      'body': body,
      'created_at': (createdAt ?? DateTime(2026, 1, 1, 12)).toIso8601String(),
    };

Map<String, dynamic> _conversationJson(String id) => {
      'id': id,
      'buyer_id': 'buyer-1',
      'seller_id': 'seller-1',
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-02T10:00:00Z',
      'last_message_body': 'Zdravo, da li imate sira?',
      'last_message_at': '2026-01-02T10:00:00Z',
    };

void main() {
  group('ChatService.getConversations', () {
    test('fetches via get_conversations_for_user RPC and parses conversations',
        () async {
      String? rpcPath;
      String? rpcBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/get_conversations_for_user')) {
          rpcPath = req.url.path;
          rpcBody = body;
          return _jsonResponse([_conversationJson('conv-1')]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      final conversations = await service.getConversations('buyer-1');

      expect(rpcPath, isNotNull);
      expect(rpcBody, contains('"p_user_id":"buyer-1"'));
      expect(conversations.length, equals(1));
      expect(conversations.first.id, equals('conv-1'));
      expect(conversations.first.buyerId, equals('buyer-1'));
      expect(
          conversations.first.lastMessageBody, 'Zdravo, da li imate sira?');
    });

    test('returns empty list when user has no conversations', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path
            .contains('/rest/v1/rpc/get_conversations_for_user')) {
          return _jsonResponse([]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      expect(await service.getConversations('buyer-1'), isEmpty);
    });
  });

  group('ChatService.setConversationUserPrefs', () {
    test('calls set_conversation_user_prefs RPC with favorite and hidden',
        () async {
      String? rpcBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path
            .contains('/rest/v1/rpc/set_conversation_user_prefs')) {
          rpcBody = body;
          return http.Response('null', 200);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      await service.setConversationUserPrefs(
        'conv-1',
        isFavorite: true,
        hidden: false,
      );

      expect(rpcBody, contains('"p_conversation_id":"conv-1"'));
      expect(rpcBody, contains('"p_is_favorite":true'));
      expect(rpcBody, contains('"p_hidden":false'));
    });
  });

  group('ChatService.getMessages', () {
    test('reverses newest-first rows into oldest-first chat order', () async {
      String? capturedQuery;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages')) {
          capturedQuery = req.url.query;
          // Server vraća opadajuće (najnovija prva), kao PostgREST order desc
          return _jsonResponse([
            _msgJson('m-3', 'Treća poruka',
                createdAt: DateTime(2026, 1, 1, 12, 0, 2)),
            _msgJson('m-2', 'Druga poruka',
                createdAt: DateTime(2026, 1, 1, 12, 0, 1)),
            _msgJson('m-1', 'Prva poruka',
                createdAt: DateTime(2026, 1, 1, 12, 0, 0)),
          ]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      final messages = await service.getMessages('conv-1');

      // Upit: filter po razgovoru, sortiranje i limit najnovijih
      expect(capturedQuery, contains('conversation_id=eq.conv-1'));
      expect(capturedQuery, contains('order=created_at.desc'));
      expect(capturedQuery, contains('limit=50'));

      // Rezultat: uzlazno (najstarija prva) za prikaz chata
      expect(messages.map((m) => m.id).toList(), equals(['m-1', 'm-2', 'm-3']));
      expect(messages.first.body, equals('Prva poruka'));
    });
  });

  group('ChatService.sendMessage', () {
    test('inserts message with conversation, sender and body', () async {
      String? sentPath;
      String? sentBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages') &&
            req.method == 'POST') {
          sentPath = req.url.path;
          sentBody = body;
          return http.Response('[]', 201);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      await service.sendMessage('conv-1', 'buyer-1', 'Dobar dan!');

      expect(sentPath, isNotNull);
      expect(sentBody, contains('"conversation_id":"conv-1"'));
      expect(sentBody, contains('"sender_id":"buyer-1"'));
      expect(sentBody, contains('"body":"Dobar dan!"'));
      expect(sentBody, isNot(contains('image_url')));
    });

    test('includes image_url only when provided', () async {
      String? sentBody;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages') &&
            req.method == 'POST') {
          sentBody = body;
          return http.Response('[]', 201);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      await service.sendMessage(
        'conv-1',
        'buyer-1',
        'Pogledajte sliku',
        imageUrl: 'chat-images/conv-1/photo.jpg',
      );

      expect(
          sentBody, contains('"image_url":"chat-images/conv-1/photo.jpg"'));
    });
  });

  group('ChatService.deleteMessage security', () {
    SupabaseClient buildClient(
        Future<http.Response> Function(http.BaseRequest, String) handler) {
      return SupabaseClient('https://fake-project.supabase.co', 'fake-key',
          httpClient: MockHttpHandlerClient(handler));
    }

    /// /auth/v1/token odgovor koji gotrue parsira u prijavljenog korisnika.
    http.Response authTokenResponse(String userId) => _jsonResponse({
          'access_token': 'test-access-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'refresh_token': 'test-refresh-token',
          'user': {
            'id': userId,
            'email': 'user@test.rs',
            'aud': 'authenticated',
            'role': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z',
            'app_metadata': {
              'provider': 'email',
              'providers': ['email'],
            },
            'user_metadata': {},
          },
        });

    test('unauthenticated user cannot delete a message', () async {
      var messagesRequestSeen = false;
      final supabase = buildClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages')) {
          messagesRequestSeen = true;
        }
        return http.Response('[]', 200);
      });
      final service = ChatService(client: supabase);

      await expectLater(
        () => service.deleteMessage('m-1'),
        throwsA(isA<AppError>()
            .having((e) => e.type, 'type', equals(ErrorType.unauthorized))),
      );
      expect(messagesRequestSeen, isFalse);
    });

    test('message not found throws notFound', () async {
      final supabase = buildClient((req, body) async {
        if (req.url.path.contains('/auth/v1/token')) {
          return authTokenResponse('user-1');
        }
        if (req.url.path.contains('/rest/v1/messages')) {
          return http.Response('[]', 200); // maybeSingle -> null
        }
        return http.Response('[]', 200);
      });
      final service = ChatService(client: supabase);

      await supabase.auth.signInWithPassword(
        email: 'user@test.rs',
        password: 'password123',
      );

      await expectLater(
        () => service.deleteMessage('missing-msg'),
        throwsA(isA<AppError>()
            .having((e) => e.type, 'type', equals(ErrorType.notFound))),
      );
    });

    test('only the sender can delete their message', () async {
      final supabase = buildClient((req, body) async {
        if (req.url.path.contains('/auth/v1/token')) {
          return authTokenResponse('user-1');
        }
        if (req.url.path.contains('/rest/v1/messages')) {
          return _jsonResponse({'id': 'm-1', 'sender_id': 'other-user'});
        }
        return http.Response('[]', 200);
      });
      final service = ChatService(client: supabase);

      await supabase.auth.signInWithPassword(
        email: 'user@test.rs',
        password: 'password123',
      );

      await expectLater(
        () => service.deleteMessage('m-1'),
        throwsA(isA<AppError>()
            .having((e) => e.type, 'type', equals(ErrorType.forbidden))),
      );
    });

    test('sender can delete their own message with sender-scoped delete',
        () async {
      String? deleteQuery;
      String? deleteMethod;

      final supabase = buildClient((req, body) async {
        if (req.url.path.contains('/auth/v1/token')) {
          return authTokenResponse('user-1');
        }
        if (req.url.path.contains('/rest/v1/messages') &&
            req.method == 'DELETE') {
          deleteMethod = req.method;
          deleteQuery = req.url.query;
          return http.Response('[]', 204);
        }
        if (req.url.path.contains('/rest/v1/messages')) {
          return _jsonResponse({'id': 'm-1', 'sender_id': 'user-1'});
        }
        return http.Response('[]', 200);
      });
      final service = ChatService(client: supabase);

      await supabase.auth.signInWithPassword(
        email: 'user@test.rs',
        password: 'password123',
      );

      await service.deleteMessage('m-1');

      expect(deleteMethod, equals('DELETE'));
      expect(deleteQuery, contains('id=eq.m-1'));
      expect(deleteQuery, contains('sender_id=eq.user-1'));
    });
  });

  group('ChatService.getConversationInfoWithProfiles', () {
    test('returns default names when RPC returns empty result', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path
            .contains('/rest/v1/rpc/get_conversation_info_with_profile')) {
          return _jsonResponse([]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      final info = await service.getConversationInfoWithProfiles('conv-1');

      expect(info.id, isNull);
      expect(info.buyerName, equals('Korisnik'));
      expect(info.sellerName, equals('Korisnik'));
    });

    test('maps RPC row to conversation info record', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path
            .contains('/rest/v1/rpc/get_conversation_info_with_profile')) {
          return _jsonResponse([
            {
              'id': 'conv-1',
              'buyer_id': 'buyer-1',
              'seller_id': 'seller-1',
              'order_id': 'order-9',
              'product_id': null,
              'ad_id': null,
              'item_title': 'Domaći Sir',
              'item_image_url': 'https://example.com/sir.jpg',
              'item_price': 1200,
              'item_unit': 'kg',
              'item_type': 'product',
              'buyer_name': 'Nikola Nikolić',
              'seller_name': 'Miloševo gazdinstvo',
            }
          ]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      final info = await service.getConversationInfoWithProfiles('conv-1');

      expect(info.id, equals('conv-1'));
      expect(info.buyerId, equals('buyer-1'));
      expect(info.sellerId, equals('seller-1'));
      expect(info.orderId, equals('order-9'));
      expect(info.itemTitle, equals('Domaći Sir'));
      expect(info.itemPrice, equals(1200));
      expect(info.buyerName, equals('Nikola Nikolić'));
      expect(info.sellerName, equals('Miloševo gazdinstvo'));
    });

    test('getOtherPartyName returns seller name for the buyer and vice versa',
        () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path
            .contains('/rest/v1/rpc/get_conversation_info_with_profile')) {
          return _jsonResponse([
            {
              'id': 'conv-1',
              'buyer_id': 'buyer-1',
              'seller_id': 'seller-1',
              'buyer_name': 'Nikola Nikolić',
              'seller_name': 'Miloševo gazdinstvo',
            }
          ]);
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      expect(
        await service.getOtherPartyName('conv-1', 'buyer-1'),
        equals('Miloševo gazdinstvo'),
      );
      expect(
        await service.getOtherPartyName('conv-1', 'seller-1'),
        equals('Nikola Nikolić'),
      );
    });
  });

  group('ChatService.watchMessages (inkrementalni realtime update)', () {
    test('full fetch, insert dedup, update and delete events', () async {
      final serverRows = <Map<String, dynamic>>[
        _msgJson('m-2', 'Druga poruka',
            createdAt: DateTime(2026, 1, 1, 12, 0, 1)),
        _msgJson('m-1', 'Prva poruka',
            createdAt: DateTime(2026, 1, 1, 12, 0, 0)),
      ];

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages')) {
          return _jsonResponse(serverRows.toList());
        }
        return http.Response('[]', 200);
      });
      final supabase = SupabaseClient(
          'https://fake-project.supabase.co', 'fake-key',
          httpClient: mockClient);
      final service = ChatService(client: supabase);

      final emitted = <List<String>>[];
      final sub = service.watchMessages('conv-1').listen(
            (msgs) => emitted.add(msgs.map((m) => m.id).toList()),
          );

      // 1. Inicijalni full fetch (server vraća desc -> stream emituje asc)
      await pumpEventQueue();
      expect(emitted.last, equals(['m-1', 'm-2']));

      // Pristup deljenoj sobi razgovora preko javnog roomManager-a
      final room = service.roomManager.getOrCreateRoom(supabase, 'conv-1');

      void fireRoomCallbacks(PostgresChangePayload payload) {
        for (final cb in List.of(room.onMessageCallbacks)) {
          cb(payload);
        }
      }

      PostgresChangePayload payloadFor(
        PostgresChangeEvent event, {
        Map<String, dynamic> newRecord = const {},
        Map<String, dynamic> oldRecord = const {},
      }) =>
          PostgresChangePayload(
            schema: 'public',
            table: 'messages',
            commitTimestamp: DateTime.now(),
            eventType: event,
            newRecord: newRecord,
            oldRecord: oldRecord,
            errors: null,
          );

      // 2. Realtime INSERT najnovije poruke -> dodata na kraj, bez ponovnog fetch-a
      serverRows.insert(
          0,
          _msgJson('m-3', 'Treća poruka',
              createdAt: DateTime(2026, 1, 1, 12, 0, 2)));
      fireRoomCallbacks(payloadFor(
        PostgresChangeEvent.insert,
        newRecord: serverRows.first,
      ));
      await pumpEventQueue();
      expect(emitted.last, equals(['m-1', 'm-2', 'm-3']));

      // 3. INSERT iste poruke (duplikat) -> ignorisan, lista nepromenjena
      fireRoomCallbacks(payloadFor(
        PostgresChangeEvent.insert,
        newRecord: serverRows.first,
      ));
      await pumpEventQueue();
      expect(emitted.last, equals(['m-1', 'm-2', 'm-3']));

      // 4. Realtime UPDATE postojeće poruke -> zamenjena na istom mestu
      final updated = Map<String, dynamic>.from(_msgJson(
        'm-2',
        'Druga poruka (izmenjena)',
        createdAt: DateTime(2026, 1, 1, 12, 0, 1),
      ));
      fireRoomCallbacks(payloadFor(
        PostgresChangeEvent.update,
        newRecord: updated,
      ));
      await pumpEventQueue();
      expect(emitted.last, equals(['m-1', 'm-2', 'm-3']));

      // 5. Realtime DELETE poruke -> uklonjena iz liste
      fireRoomCallbacks(payloadFor(
        PostgresChangeEvent.delete,
        oldRecord: {'id': 'm-2'},
      ));
      await pumpEventQueue();
      expect(emitted.last, equals(['m-1', 'm-3']));

      await sub.cancel();
    });
  });
}
