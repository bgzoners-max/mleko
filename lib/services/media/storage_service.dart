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

  Future<String> uploadProfileImage(String userId, List<int> bytes) async {
    final client = Supabase.instance.client;
    final path = '$userId.jpg';
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await client.storage.from(_bucketProfiles).uploadBinary(
      path,
      data,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    final publicUrl = client.storage.from(_bucketProfiles).getPublicUrl(path);
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$publicUrl?t=$ts';
  }

  Future<String> uploadProductImage(String userId, List<int> bytes, int index) async {
    final client = Supabase.instance.client;
    final name = '${_uuid.v4()}.jpg';
    final path = '$userId/$name';
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await client.storage.from(_bucketProducts).uploadBinary(
      path,
      data,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return client.storage.from(_bucketProducts).getPublicUrl(path);
  }

  /// Briše fajl iz `product-images` na osnovu public URL-a.
  /// Koristi se za rollback kada oglas/proizvod nije sačuvan, da ne ostaju
  /// „orphan“ fajlovi u bucketu.
  Future<void> deleteFileByPublicUrl(String url) async {
    final client = Supabase.instance.client;
    final marker = '/$_bucketProducts/';
    final idx = url.indexOf(marker);
    if (idx < 0) return;
    var path = url.substring(idx + marker.length);
    final qIdx = path.indexOf('?');
    if (qIdx >= 0) path = path.substring(0, qIdx);
    await client.storage.from(_bucketProducts).remove([path]);
  }

  Future<String> uploadFarmGalleryImage(String sellerId, List<int> bytes, int index) async {
    final client = Supabase.instance.client;
    final name = '${_uuid.v4()}.jpg';
    final path = '$sellerId/$name';
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    await client.storage.from(_bucketFarmGallery).uploadBinary(
      path,
      data,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return client.storage.from(_bucketFarmGallery).getPublicUrl(path);
  }
}
