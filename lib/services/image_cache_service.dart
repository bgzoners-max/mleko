import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Servis za optimizaciju image cache-a
class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();

  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  /// Preload slike za carousel, search, itd. - ne čeka se završetak
  Future<void> preloadImage(BuildContext context, String imageUrl) async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(imageUrl),
        context,
      );
    } catch (e) {
      // Tiho ignoruj greške pri preload-u
      debugPrint('Image preload error: $e');
    }
  }

  /// Batch preload za listu slika (koristi se za carousel, featured)
  Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls, {
    int limit = 5,
  }) async {
    final urls = imageUrls.take(limit);
    for (final url in urls) {
      if (url.isNotEmpty) {
        unawaited(preloadImage(context, url));
      }
    }
  }

  /// Očisti sve cache-ovane slike
  void clearAllCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  /// Očisti samo u memoriji cache
  void clearMemoryCache() {
    imageCache.clearLiveImages();
  }
}
