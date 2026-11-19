import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../models/app_error.dart';
import '../../core/logger_service.dart';
import '../../media/image_compression_service.dart';
import '../../media/storage_service.dart';

/// Handler za chat medije (slike, signed URLs) izdvojen radi čiste kompozicije.
class ChatMediaHandler {
  final SupabaseClient? _customClient;
  static const _uuid = Uuid();

  ChatMediaHandler({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

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
  Future<String> getSignedChatImageUrl(String pathOrUrl) async {
    final path = extractChatImagePath(pathOrUrl);
    if (path == null) {
      return pathOrUrl;
    }

    final cached = _signedUrlCache[path];
    if (cached != null) return cached;

    try {
      final signedUrl =
          await _client.storage.from('chat-images').createSignedUrl(
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
      StorageService.validateImageBytes(rawData);
      final data = await ImageCompressionService().compressChatImage(rawData);
      final mimeInfo = StorageService.validateImageBytes(data);
      final name = '${_uuid.v4()}.${mimeInfo.ext}';
      final path = '$userId/$conversationId/$name';

      await _client.storage.from('chat-images').uploadBinary(
            path,
            data,
            fileOptions:
                FileOptions(contentType: mimeInfo.mimeType, upsert: true),
          );

      final signedUrl =
          await _client.storage.from('chat-images').createSignedUrl(
                path,
                60 * 60 * 24 * 7, // 7 dana
              );
      _signedUrlCache[path] = signedUrl;
      return signedUrl;
    } catch (e, st) {
      if (e is AppError) rethrow;
      throw AppError.from(e, stackTrace: st);
    }
  }
}
