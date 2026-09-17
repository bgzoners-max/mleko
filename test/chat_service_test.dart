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
}
