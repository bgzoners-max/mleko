import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Storage za slike – profili i proizvodi (Supabase).
class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const _uuid = Uuid();
  static const _bucketProducts = 'product-images';
  static const _bucketProfiles = 'profiles';
  static const _bucketFarmGallery = 'farm-gallery';

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
        bytes[11] == 0x50) {
      return (ext: 'webp', mimeType: 'image/webp');
    }
    // Podrazumevano: JPEG
    return (ext: 'jpg', mimeType: 'image/jpeg');
  }

  Future<String> uploadProfileImage(String userId, List<int> bytes) async {
    final client = Supabase.instance.client;
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final mimeInfo = detectMimeAndExt(data);
    final path = '$userId.${mimeInfo.ext}';
    await client.storage.from(_bucketProfiles).uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: mimeInfo.mimeType, upsert: true),
    );
    final publicUrl = client.storage.from(_bucketProfiles).getPublicUrl(path);
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?t=$ts';
  }

  Future<String> uploadProductImage(String userId, List<int> bytes, int index) async {
    final client = Supabase.instance.client;
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final mimeInfo = detectMimeAndExt(data);
    final name = '${_uuid.v4()}.${mimeInfo.ext}';
    final path = '$userId/$name';
    await client.storage.from(_bucketProducts).uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: mimeInfo.mimeType),
    );
    return client.storage.from(_bucketProducts).getPublicUrl(path);
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
  /// Koristi se za rollback kada oglas/proizvod/galerija nije sačuvan,
  /// da ne ostaju „orphan“ fajlovi u bucketu.
  Future<void> deleteFileByBucket(String bucket, String url) async {
    final path = extractPathFromPublicUrl(bucket, url);
    if (path == null) return;
    final client = Supabase.instance.client;
    await client.storage.from(bucket).remove([path]);
  }

  /// Briše fajl iz `product-images` na osnovu public URL-a.
  /// Zadržano radi kompatibilnosti; nova mesta treba da koriste
  /// [deleteFileByBucket] sa eksplicitnim bucketom.
  Future<void> deleteFileByPublicUrl(String url) =>
      deleteFileByBucket(_bucketProducts, url);

  Future<String> uploadFarmGalleryImage(String sellerId, List<int> bytes, int index) async {
    final client = Supabase.instance.client;
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final mimeInfo = detectMimeAndExt(data);
    final name = '${_uuid.v4()}.${mimeInfo.ext}';
    final path = '$sellerId/$name';
    await client.storage.from(_bucketFarmGallery).uploadBinary(
      path,
      data,
      fileOptions: FileOptions(contentType: mimeInfo.mimeType, upsert: true),
    );
    return client.storage.from(_bucketFarmGallery).getPublicUrl(path);
  }
}
