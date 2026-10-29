import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'image_compression_service.dart';

/// Storage za slike – podržava Cloudflare R2 (primarni sa 0$ egress troškovima)
/// sa automatskim fallback-om na Supabase Storage.
class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const _uuid = Uuid();
  static const _bucketProducts = 'product-images';
  static const _bucketProfiles = 'profiles';
  static const _bucketFarmGallery = 'farm-gallery';

  /// Javni R2 domen za serviranje medija sa Cloudflare Anycast CDN-a
  static const r2PublicBaseUrl =
      'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev';

  /// Autoritativni bazni URL za pozivanje Cloudflare Pages funkcija
  static String get _apiBaseUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (!origin.contains('localhost') && !origin.contains('127.0.0.1')) {
        return origin;
      }
    }
    return 'https://domacimarket.pages.dev';
  }

  /// Detektuje ekstenziju i MIME tip na osnovu „magic bytes“ u zaglavlju fajla.
  static ({String ext, String mimeType}) detectMimeAndExt(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return (ext: 'jpg', mimeType: 'image/jpeg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return (ext: 'png', mimeType: 'image/png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x40) {
      return (ext: 'webp', mimeType: 'image/webp');
    }
    return (ext: 'jpg', mimeType: 'image/jpeg');
  }

  /// Pomoćni metod za upload: pokušava Cloudflare R2, sa fallbackom na Supabase
  Future<String> _uploadFile({
    required String bucket,
    required String subPath,
    required Uint8List data,
    required ({String ext, String mimeType}) mimeInfo,
    bool cacheBust = false,
  }) async {
    final fullPath = '$bucket/$subPath';

    // 1. Primarni upload na Cloudflare R2 preko Pages funkcije
    try {
      final uri = Uri.parse(
        '$_apiBaseUrl/api/upload?path=${Uri.encodeComponent(fullPath)}',
      );
      final session = Supabase.instance.client.auth.currentSession;
      final headers = <String, String>{
        'Content-Type': mimeInfo.mimeType,
      };
      if (session?.accessToken != null) {
        headers['Authorization'] = 'Bearer ${session!.accessToken}';
      }

      final response = await http
          .post(uri, headers: headers, body: data)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final url = json['url'] as String? ?? '$r2PublicBaseUrl/$fullPath';
        if (cacheBust) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          return '$url?t=$ts';
        }
        return url;
      }
    } catch (_) {
      // Ignoriši i pređi na fallback Supabase Storage
    }

    // 2. Sigurnosni fallback na Supabase Storage
    final client = Supabase.instance.client;
    await client.storage.from(bucket).uploadBinary(
      subPath,
      data,
      fileOptions: FileOptions(contentType: mimeInfo.mimeType, upsert: true),
    );
    final publicUrl = client.storage.from(bucket).getPublicUrl(subPath);
    if (cacheBust) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      return '$publicUrl?t=$ts';
    }
    return publicUrl;
  }

  Future<String> uploadProfileImage(
    String userId,
    List<int> bytes, {
    bool compress = true,
  }) async {
    final rawData = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final data = compress
        ? await ImageCompressionService().compressProfileImage(rawData)
        : rawData;
    final mimeInfo = detectMimeAndExt(data);
    final subPath = '$userId.${mimeInfo.ext}';
    return _uploadFile(
      bucket: _bucketProfiles,
      subPath: subPath,
      data: data,
      mimeInfo: mimeInfo,
      cacheBust: true,
    );
  }

  Future<String> uploadProductImage(
    String userId,
    List<int> bytes,
    int index, {
    bool compress = true,
  }) async {
    final rawData = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final data = compress
        ? await ImageCompressionService().compressImage(rawData)
        : rawData;
    final mimeInfo = detectMimeAndExt(data);
    final name = '${_uuid.v4()}.${mimeInfo.ext}';
    final subPath = '$userId/$name';
    return _uploadFile(
      bucket: _bucketProducts,
      subPath: subPath,
      data: data,
      mimeInfo: mimeInfo,
      cacheBust: false,
    );
  }

  Future<String> uploadFarmGalleryImage(
    String sellerId,
    List<int> bytes,
    int index, {
    bool compress = true,
  }) async {
    final rawData = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final data = compress
        ? await ImageCompressionService().compressImage(rawData)
        : rawData;
    final mimeInfo = detectMimeAndExt(data);
    final name = '${_uuid.v4()}.${mimeInfo.ext}';
    final subPath = '$sellerId/$name';
    return _uploadFile(
      bucket: _bucketFarmGallery,
      subPath: subPath,
      data: data,
      mimeInfo: mimeInfo,
      cacheBust: false,
    );
  }

  /// Izdvaja storage putanju iz public URL-a (čista funkcija, testabilna).
  /// Vraća `null` ako URL ne pripada zadatom bucketu.
  /// Odbacuje query parametre (npr. `?t=...` cache-buster).
  static String? extractPathFromPublicUrl(String bucket, String url) {
    final marker = '/$bucket/';
    final idx = url.indexOf(marker);
    if (idx < 0) return null;
    var path = url.substring(idx + marker.length);
    final qIdx = path.indexOf('?');
    if (qIdx >= 0) path = path.substring(0, qIdx);
    return path.isEmpty ? null : path;
  }

  /// Briše fajl iz zadatog bucketa na osnovu public URL-a.
  /// Podržava i Cloudflare R2 i legacy Supabase Storage URL-ove.
  Future<void> deleteFileByBucket(String bucket, String url) async {
    final path = extractPathFromPublicUrl(bucket, url);
    if (path == null) return;

    if (url.contains('r2.dev') || url.contains('r2.cloudflarestorage.com')) {
      try {
        final fullPath = '$bucket/$path';
        final uri = Uri.parse(
          '$_apiBaseUrl/api/upload?path=${Uri.encodeComponent(fullPath)}',
        );
        final session = Supabase.instance.client.auth.currentSession;
        final headers = <String, String>{};
        if (session?.accessToken != null) {
          headers['Authorization'] = 'Bearer ${session!.accessToken}';
        }
        await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 10));
        return;
      } catch (_) {
        // Ignoriši grešku pri rollbacku
      }
    }

    // Supabase rollback za starije slike
    try {
      final client = Supabase.instance.client;
      await client.storage.from(bucket).remove([path]);
    } catch (_) {}
  }

  /// Briše fajl iz `product-images` na osnovu public URL-a.
  Future<void> deleteFileByPublicUrl(String url) =>
      deleteFileByBucket(_bucketProducts, url);
}
