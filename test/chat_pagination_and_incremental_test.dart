import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
  group('ChatService Keyset Pagination', () {
    test('getOlderMessages with beforeId applies keyset filter', () async {
      String? requestedUrl;
      final mockClient = MockHttpHandlerClient((req, body) async {
        if (req.url.path.contains('/rest/v1/messages')) {
          requestedUrl = req.url.toString();
          final sampleMessages = [
            {
              'id': 'msg-1',
              'conversation_id': 'conv-1',
              'sender_id': 'user-1',
              'body': 'Pozdrav',
              'created_at': DateTime(2026, 1, 1, 10, 0, 0).toIso8601String(),
              'read_at': null,
              'image_url': null,
            }
          ];
          return http.Response(
            jsonEncode(sampleMessages),
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
      final beforeTime = DateTime(2026, 1, 1, 10, 5, 0);
      final messages = await service.getOlderMessages(
        'conv-1',
        before: beforeTime,
        beforeId: 'msg-5',
      );

      expect(messages.length, 1);
      expect(messages.first.id, equals('msg-1'));
      expect(requestedUrl, isNotNull);
      // Keyset filter or format check
      expect(requestedUrl, contains('or='));
      expect(requestedUrl, contains('id.lt.msg-5'));
    });
  });
}
