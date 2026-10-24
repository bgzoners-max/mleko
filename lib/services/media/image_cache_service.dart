import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Centralizovana upravljanja image cache-om – pregled i kontrola memorije.
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  static final _cacheManager = CachedNetworkImageProvider.defaultCacheManager;

  factory ImageCacheService() => _instance;

  ImageCacheService._internal();

  /// Očisti entire disk i memory cache – koristi nakon sign-out ili veće osvežavanja.
  Future<void> clearAllCaches() async {
    await _cacheManager.emptyCache();
    imageCache
      ..clear()
      ..clearLiveImages();
  }

  /// Očisti samo disk cache (memorija se očisti automatski nakon vremena).
  Future<void> clearDiskCache() async {
    await _cacheManager.emptyCache();
  }

  /// Očisti specifičnu sliku iz cache-a (disk + memory).
  Future<bool> evictImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      return false;
    }
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Očisti više slika odjednom.
  Future<int> evictImages(List<String> imageUrls) async {
    int count = 0;
    for (final url in imageUrls) {
      if (await evictImage(url)) count++;
    }
    return count;
  }

  /// Dobij info o dostupnom prostoru u memoriji (Flutter image cache).
  ImageCache getImageCacheStats() => imageCache;

  /// Dobij maximalan mogući prostor za memoriju (bytes).
  /// Flutter default je ~20MB, ali možeš proveriti stvarnu vrednost.
  int get maxImageCacheSize => imageCache.maximumSizeBytes;

  /// Trenutna veličina image cache-a (approx, jer Flutter ne daje tačnu brojku).
  String get cacheStatusMessage =>
      'Image cache: ${imageCache.currentSize ~/ (1024 * 1024)}MB (max: ${maxImageCacheSize ~/ (1024 * 1024)}MB)';
}
