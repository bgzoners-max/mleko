import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_error.dart';
import '../../core/logger_service.dart';
import '../../media/image_compression_service.dart';

mixin ChatMediaMixin {
  SupabaseClient get client;

  static final Map<String, String> _signedUrlCache = {};

  /// Čisti keš potpisanih URL-ova slika.
  static void clearSignedUrlCache() {
    _signedUrlCache.clear();
  }

  /// Ekstrahuje putanju objekta iz chat-images URL-a ili direktne putanje.
  static String? extractChatImagePath(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return null;
    final uri = Uri.tryParse(pathOrUrl);
    if (uri != null && uri.hasScheme) {
      final segments = uri.pathSegments;
      final bucketIdx = segments.indexOf('chat-images');
      if (bucketIdx != -1 && bucketIdx + 1 < segments.length) {
        return segments.sublist(bucketIdx + 1).join('/');
      }
    }
    final match = RegExp(
            r'(?:chat-images/)?([a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+/[^?#]+)')
        .firstMatch(pathOrUrl);
    return match?.group(1);
  }

  /// Kreira ili vraća keširani signed URL za datu privatnu chat sliku.
  /// Ako URL već ima važeći token, vraća ga bez dodatnih poziva.
  Future<String> getSignedChatImageUrl(String pathOrUrl) async {
    final path = extractChatImagePath(pathOrUrl);
    if (path == null) {
      return pathOrUrl;
    }

    final cached = _signedUrlCache[path];
    if (cached != null) return cached;

    try {
      final signedUrl = await client.storage.from('chat-images').createSignedUrl(
            path,
            60 * 60 * 24 * 7, // 7 dana
          );
      _signedUrlCache[path] = signedUrl;
      return signedUrl;
    } catch (e) {
      LoggerService.warning('Failed to create signed URL for chat image: $e',
          extra: {'path': path});
      return pathOrUrl;
    }
  }

  /// Otprema sliku u namenski privatni chat-images bucket i vraća potpisani (signed) URL.
  Future<String> uploadMessageImage(
    String conversationId,
    String userId,
    List<int> bytes,
  ) async {
    try {
      final rawData = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      final data = await ImageCompressionService().compressChatImage(rawData);
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$conversationId/$name';

      await client.storage.from('chat-images').uploadBinary(
            path,
            data,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );

      final signedUrl = await client.storage.from('chat-images').createSignedUrl(
            path,
            60 * 60 * 24 * 7, // 7 dana
          );
      _signedUrlCache[path] = signedUrl;
      return signedUrl;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
