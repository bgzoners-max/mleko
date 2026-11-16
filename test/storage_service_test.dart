import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mleko/services/core/logger_service.dart';
import 'package:mleko/services/media/storage_service.dart';

class _MockStorageHttpClient extends http.BaseClient {
  _MockStorageHttpClient(this.handler);

  final Future<http.Response> Function(http.Request request, List<int> bodyBytes)
      handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    final bodyBytes = req.bodyBytes;
    final res = await handler(req, bodyBytes);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([res.bodyBytes]),
      res.statusCode,
      headers: res.headers,
      request: req,
    );
  }
}

void main() {
  group('StorageService.detectMimeAndExt', () {
    test('prepoznaje validan JPEG po magic bajtovima', () {
      final result =
          StorageService.detectMimeAndExt([0xFF, 0xD8, 0xFF, 0xE0, 0x00]);
      expect(result.ext, 'jpg');
      expect(result.mimeType, 'image/jpeg');
    });

    test('prepoznaje validan PNG po magic bajtovima', () {
      final result = StorageService.detectMimeAndExt([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
      ]);
      expect(result.ext, 'png');
      expect(result.mimeType, 'image/png');
    });

    test('prepoznaje validan WebP (RIFF....WEBP sa 0x50 za P)', () {
      final result = StorageService.detectMimeAndExt([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x24, 0x00, 0x00, 0x00, // veličina
        0x57, 0x45, 0x42, 0x50, // WEBP
      ]);
      expect(result.ext, 'webp');
      expect(result.mimeType, 'image/webp');
    });

    test('ne prepoznaje WEB@ (0x40) kao WebP već vraća fallback', () {
      final result = StorageService.detectMimeAndExt([
        0x52,
        0x49,
        0x46,
        0x46,
        0x24,
        0x00,
        0x00,
        0x00,
        0x57,
        0x45,
        0x42,
        0x40,
      ]);
      expect(result.mimeType, isNot('image/webp'));
    });
  });

  group('StorageService R2 konfiguracija i URL detekcija', () {
    test('podrazumevani javni R2 domen je produkcioni custom CDN', () {
      expect(StorageService.r2PublicBaseUrl, 'https://cdn.domacimarket.rs');
    });

    test('upload timeout je prilagodjen sporijim vezama (60s)', () {
      expect(StorageService.r2UploadTimeout, const Duration(seconds: 60));
    });

    test('isR2PublicUrl prepoznaje r2.dev, cloudflarestorage i custom CDN domen',
        () {
      expect(
        StorageService.isR2PublicUrl(
          'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev/product-images/a.jpg',
        ),
        isTrue,
      );
      expect(
        StorageService.isR2PublicUrl(
          'https://cdn.domacimarket.rs/product-images/a.jpg',
        ),
        isTrue,
      );
      expect(
        StorageService.isR2PublicUrl(
          'https://bucket.account.r2.cloudflarestorage.com/product-images/a.jpg',
        ),
        isTrue,
      );
      expect(
        StorageService.isR2PublicUrl(
          'https://x.supabase.co/storage/v1/object/public/product-images/a.jpg?ref=r2.dev',
        ),
        isFalse,
      );
    });
  });

  group('StorageService upload i brisanje', () {
    test('uploadProductImage salje JWT i vraca R2 URL kada server vrati 200',
        () async {
      http.Request? captured;
      final service = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt-token-123',
        httpClient: _MockStorageHttpClient((req, body) async {
          captured = req;
          return http.Response(
            jsonEncode({
              'success': true,
              'url':
                  'https://cdn.domacimarket.rs/product-images/u1/test.jpg',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final url = await service.uploadProductImage(
        'u1',
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00]),
        0,
        compress: false,
      );

      expect(
        url,
        'https://cdn.domacimarket.rs/product-images/u1/test.jpg',
      );
      expect(captured?.method, 'POST');
      expect(captured?.headers['Authorization'], 'Bearer jwt-token-123');
      expect(captured?.url.path, '/api/upload');
    });

    test('deleteFileByBucket vraca true za 200 OK na r2.dev i custom domenu',
        () async {
      final deletedPaths = <String?>[];
      final service = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt-token-123',
        httpClient: _MockStorageHttpClient((req, _) async {
          deletedPaths.add(req.url.queryParameters['path']);
          return http.Response('{"success":true}', 200);
        }),
      );

      final r2Ok = await service.deleteFileByPublicUrl(
        'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev/product-images/u1/a.jpg',
      );
      final cdnOk = await service.deleteFileByPublicUrl(
        'https://cdn.domacimarket.rs/product-images/u1/b.jpg?t=123',
      );

      expect(r2Ok, isTrue);
      expect(cdnOk, isTrue);
      expect(deletedPaths, ['product-images/u1/a.jpg', 'product-images/u1/b.jpg']);
    });

    test('deleteFileByBucket vraca false i loguje WARNING pri HTTP 500 i izuzetku',
        () async {
      final failHttpService = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt-token-123',
        httpClient: _MockStorageHttpClient((req, _) async {
          return http.Response('{"error":"boom"}', 500);
        }),
      );

      final httpResult = await failHttpService.deleteFileByPublicUrl(
        'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev/product-images/u1/err.jpg',
      );
      expect(httpResult, isFalse);
      expect(
        LoggerService.recentLogs.last.level,
        'WARNING',
      );
      expect(
        LoggerService.recentLogs.last.extra?['statusCode'],
        500,
      );

      final throwService = StorageService(
        apiBaseUrl: 'https://domacimarket.rs',
        accessTokenProvider: () => 'jwt-token-123',
        httpClient: _MockStorageHttpClient((req, _) async {
          throw http.ClientException('Network down');
        }),
      );

      final throwResult = await throwService.deleteFileByPublicUrl(
        'https://cdn.domacimarket.rs/product-images/u1/offline.jpg',
      );
      expect(throwResult, isFalse);
      expect(LoggerService.recentLogs.last.level, 'WARNING');
      expect(
        LoggerService.recentLogs.last.extra?['path'],
        'u1/offline.jpg',
      );
    });
  });
}
