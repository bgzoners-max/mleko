import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/models/app_error.dart';
import 'package:mleko/services/communication/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockHttpHandlerClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request, String body) handler;
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
  group('ChatService.getOrCreateConversation', () {
    test('successful upsert returns conversation id', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          return http.Response(
            jsonEncode({'id': 'conv-success-123'}),
            201,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final id = await service.getOrCreateConversation('buyer1', 'seller1');
      expect(id, equals('conv-success-123'));
    });

    test('upsert with orderId includes order_id in request payload', () async {
      String? sentPayload;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          sentPayload = body;
          return http.Response(
            jsonEncode({'id': 'conv-with-order'}),
            201,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        orderId: 'order-999',
        updateOrderIdIfPresent: true,
      );
      expect(id, equals('conv-with-order'));
      expect(sentPayload, contains('"order_id":"order-999"'));
    });

    test('fallback branch: PostgrestException triggers _findConversationId and updates orderId', () async {
      bool findCalled = false;
      bool updateCalled = false;

      final mockClient = MockHttpHandlerClient((req, body) async {
        // 1. Initial upsert fails with Postgrest 409 Conflict
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          return http.Response(
            jsonEncode({
              'code': '23505',
              'message': 'duplicate key value violates unique constraint',
              'details': 'Key already exists'
            }),
            409,
          );
        }

        // 2. Fallback fetch finds existing conversation
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'GET') {
          findCalled = true;
          return http.Response(
            jsonEncode({'id': 'existing-conv-456'}),
            200,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }

        // 3. Fallback updates order_id on existing conversation
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'PATCH') {
          updateCalled = true;
          expect(body, contains('"order_id":"new-order-555"'));
          return http.Response(
            jsonEncode({'id': 'existing-conv-456'}),
            200,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        orderId: 'new-order-555',
        updateOrderIdIfPresent: true,
      );

      expect(id, equals('existing-conv-456'));
      expect(findCalled, isTrue);
      expect(updateCalled, isTrue);
    });

    test('fallback branch: when existing conversation is not found, throws AppError', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          return http.Response(
            jsonEncode({'code': 'PGRST116', 'message': 'The result contains 0 rows'}),
            400,
          );
        }

        // GET maybeSingle returns null / empty 200 representation
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'GET') {
          return http.Response('', 200);
        }

        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      expect(
        () => service.getOrCreateConversation('buyer1', 'seller1'),
        throwsA(isA<AppError>()),
      );
    });

    test('generic network or unexpected exception rethrows as AppError', () async {
      final mockClient = MockHttpHandlerClient((req, body) async {
        throw http.ClientException('Connection aborted');
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      expect(
        () => service.getOrCreateConversation('buyer1', 'seller1'),
        throwsA(isA<AppError>()),
      );
    });

    test('upsert with productId sets product_id and onConflict for product', () async {
      String? sentPayload;
      String? onConflictHeader;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          sentPayload = body;
          onConflictHeader = req.url.queryParameters['on_conflict'];
          return http.Response(
            jsonEncode({'id': 'conv-product-101'}),
            201,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        productId: 'prod-cheese-456',
      );
      expect(id, equals('conv-product-101'));
      expect(sentPayload, contains('"product_id":"prod-cheese-456"'));
      expect(onConflictHeader, equals('buyer_id,seller_id,product_id'));
    });

    test('upsert with adId sets ad_id and onConflict for classified ad', () async {
      String? sentPayload;
      String? onConflictHeader;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          sentPayload = body;
          onConflictHeader = req.url.queryParameters['on_conflict'];
          return http.Response(
            jsonEncode({'id': 'conv-ad-777'}),
            201,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        adId: 'ad-tractor-888',
      );
      expect(id, equals('conv-ad-777'));
      expect(sentPayload, contains('"ad_id":"ad-tractor-888"'));
      expect(onConflictHeader, equals('buyer_id,seller_id,ad_id'));
    });
  });

  group('Chat Image Signed URLs & Privacy', () {
    test('extractChatImagePath parses signed, public, and relative chat image URLs', () {
      expect(
        ChatService.extractChatImagePath(
          'https://xyz.supabase.co/storage/v1/object/sign/chat-images/user1/conv1/photo.jpg?token=secret123',
        ),
        equals('user1/conv1/photo.jpg'),
      );

      expect(
        ChatService.extractChatImagePath(
          'https://xyz.supabase.co/storage/v1/object/public/chat-images/user1/conv1/photo.jpg',
        ),
        equals('user1/conv1/photo.jpg'),
      );

      expect(
        ChatService.extractChatImagePath('chat-images/user1/conv1/photo.jpg'),
        equals('user1/conv1/photo.jpg'),
      );

      expect(
        ChatService.extractChatImagePath('user1/conv1/photo.jpg'),
        equals('user1/conv1/photo.jpg'),
      );

      expect(
        ChatService.extractChatImagePath(''),
        isNull,
      );
    });

    test('getSignedChatImageUrl returns cached signed URL and avoids redundant network calls', () async {
      ChatService.clearSignedUrlCache();

      var signCalls = 0;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/storage/v1/object/sign/chat-images/user1/conv1/photo.jpg') &&
            req.method == 'POST') {
          signCalls++;
          return http.Response(
            jsonEncode({'signedURL': '/object/sign/chat-images/user1/conv1/photo.jpg?token=abc'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient(
        'https://fake-project.supabase.co',
        'fake-key',
        httpClient: mockClient,
      );

      final service = ChatService(client: supabase);
      final url1 = await service.getSignedChatImageUrl('user1/conv1/photo.jpg');
      expect(url1, contains('token=abc'));
      expect(signCalls, equals(1));

      // Drugi poziv za istu putanju mora vratiti keširan URL bez novog poziva
      final url2 = await service.getSignedChatImageUrl('user1/conv1/photo.jpg');
      expect(url2, equals(url1));
      expect(signCalls, equals(1));
    });
  });

  group('Chat Hardening: Self-Chat, Scoped Orders, and Bounded markAsRead', () {
    test('self-conversation throws validation AppError when buyerId == sellerId', () async {
      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key');
      final service = ChatService(client: supabase);

      expect(
        () => service.getOrCreateConversation('same-user', 'same-user'),
        throwsA(predicate((e) =>
            e is AppError &&
            e.type == ErrorType.validation &&
            (e.userMessage?.contains('samim sobom') ?? false))),
      );
    });

    test('getOrCreateConversation with orderId uses onConflict=order_id', () async {
      String? onConflict;
      String? sentPayload;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          sentPayload = body;
          onConflict = req.url.queryParameters['on_conflict'];
          return http.Response(
            jsonEncode({'id': 'conv-scoped-order-1'}),
            201,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = ChatService(client: supabase);

      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        orderId: 'order-scoped-123',
      );

      expect(id, equals('conv-scoped-order-1'));
      expect(sentPayload, contains('"order_id":"order-scoped-123"'));
      expect(onConflict, equals('order_id'));
    });

    test('fallback does not overwrite order_id if conversation already has an order_id', () async {
      bool patchCalled = false;

      final mockClient = MockHttpHandlerClient((req, body) async {
        // 1. POST fails with 409
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'POST') {
          return http.Response(
            jsonEncode({'code': '23505', 'message': 'duplicate key'}),
            409,
          );
        }
        // 2. GET find fallback finds existing conversation
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'GET') {
          return http.Response(
            jsonEncode({'id': 'existing-conv-with-order', 'order_id': 'original-order-111'}),
            200,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        // 3. PATCH should NOT be called because order_id is already present
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'PATCH') {
          patchCalled = true;
          return http.Response('{}', 200);
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = ChatService(client: supabase);

      final id = await service.getOrCreateConversation(
        'buyer1',
        'seller1',
        orderId: 'new-order-222',
        updateOrderIdIfPresent: true,
      );

      expect(id, equals('existing-conv-with-order'));
      expect(patchCalled, isFalse);
    });

    test('markAsRead calls server-side RPC mark_conversation_read with limit', () async {
      String? rpcBody;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/mark_conversation_read') && req.method == 'POST') {
          rpcBody = body;
          return http.Response('5', 200); // 5 messages updated
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = ChatService(client: supabase);

      await service.markAsRead('conv-123', 'user-1', limit: 150);

      expect(rpcBody, contains('"p_conversation_id":"conv-123"'));
      expect(rpcBody, contains('"p_limit":150'));
    });

    test('markAsRead falls back to bounded update when RPC code is 42883', () async {
      bool rpcAttempted = false;
      bool fetchConvAttempted = false;
      bool fetchMessagesAttempted = false;
      bool updateMessagesAttempted = false;

      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/mark_conversation_read') && req.method == 'POST') {
          rpcAttempted = true;
          return http.Response(
            jsonEncode({'code': '42883', 'message': 'function mark_conversation_read does not exist'}),
            404,
          );
        }
        if (req.url.path.contains('/rest/v1/conversations') && req.method == 'GET') {
          fetchConvAttempted = true;
          return http.Response(
            jsonEncode({'buyer_id': 'user-1', 'seller_id': 'user-2'}),
            200,
            headers: {'content-type': 'application/vnd.pgrst.object+json'},
          );
        }
        if (req.url.path.contains('/rest/v1/messages') && req.method == 'GET') {
          fetchMessagesAttempted = true;
          expect(req.url.queryParameters['limit'], equals('100'));
          return http.Response(
            jsonEncode([{'id': 'msg-1'}, {'id': 'msg-2'}]),
            200,
          );
        }
        if (req.url.path.contains('/rest/v1/messages') && req.method == 'PATCH') {
          updateMessagesAttempted = true;
          final idParam = req.url.queryParameters['id'] ?? '';
          expect(idParam, contains('msg-1'));
          expect(idParam, contains('msg-2'));
          return http.Response('', 204);
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = ChatService(client: supabase);

      await service.markAsRead('conv-123', 'user-1', limit: 100);

      expect(rpcAttempted, isTrue);
      expect(fetchConvAttempted, isTrue);
      expect(fetchMessagesAttempted, isTrue);
      expect(updateMessagesAttempted, isTrue);
    });

    test('getOrCreateConversation calls get_or_create_conversation RPC and returns id', () async {
      String? rpcPayload;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/rpc/get_or_create_conversation') && req.method == 'POST') {
          rpcPayload = body;
          return http.Response(jsonEncode('conv-rpc-atomic-id'), 200, headers: {
            'content-type': 'application/json',
          });
        }
        return http.Response('Not Found', 404);
      });

      final supabase = SupabaseClient('https://fake.supabase.co', 'fake-key', httpClient: mockClient);
      final service = ChatService(client: supabase);

      final id = await service.getOrCreateConversation(
        'buyer-1',
        'seller-1',
        productId: 'prod-1',
        orderId: 'order-1',
      );

      expect(id, equals('conv-rpc-atomic-id'));
      expect(rpcPayload, contains('"p_buyer_id":"buyer-1"'));
      expect(rpcPayload, contains('"p_seller_id":"seller-1"'));
      expect(rpcPayload, contains('"p_product_id":"prod-1"'));
      expect(rpcPayload, contains('"p_order_id":"order-1"'));
    });
  });
}


