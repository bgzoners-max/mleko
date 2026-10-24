import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/product_model.dart';
import 'image_url_utils.dart';

/// Centralizovano upravljanje memorijskim i disk kešom slika
class AppImageCache {
  /// Custom CacheManager sa stalePeriod od 7 dana i maksimalno 200 keširanih fajlova
  static final CacheManager cacheManager = CacheManager(
    Config(
      'app_image_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  /// Konfiguriše limite u RAM memoriji (sprečava OOM na starijim uređajima i mobilnom webu)
  static void configureMemoryLimits({
    int maxObjects = 150,
    int maxSizeBytes = 40 * 1024 * 1024, // 40 MB
  }) {
    PaintingBinding.instance.imageCache
      ..maximumSize = maxObjects
      ..maximumSizeBytes = maxSizeBytes;
  }

  /// Čisti RAM memorijski keš slika (korisno nakon zatvaranja galerija i detalja proizvoda)
  static void clearMemoryCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

/// Centralizovani helper za preload slika proizvoda u cache browsera / memorije.
///
/// Preloaduje primarnu sliku i (za prvih [topCountWithSecondary] proizvoda) drugu sliku
/// radi bržeg prikaza detalja ili karusela bez seckanja, do limita [maxTotalUrls].
void warmupProductImages({
  required BuildContext context,
  required List<ProductModel> products,
  required Set<String> preloadedUrls,
  bool Function()? isMounted,
  int topCountWithSecondary = 4,
  int maxTotalUrls = 12,
}) {
  if (products.isEmpty) return;

  final List<String> urls = [];
  for (var i = 0; i < products.length; i++) {
    final p = products[i];
    if (p.imageUrls.isNotEmpty) {
      final firstUrl = p.imageUrls.first;
      final firstResolved = ImageUrlUtils.thumbnailUrl(firstUrl) ?? firstUrl;
      if (!preloadedUrls.contains(firstResolved)) {
        urls.add(firstResolved);
      }
      if (i < topCountWithSecondary && p.imageUrls.length > 1) {
        final secondUrl = p.imageUrls[1];
        final secondResolved = ImageUrlUtils.thumbnailUrl(secondUrl) ?? secondUrl;
        if (!preloadedUrls.contains(secondResolved)) {
          urls.add(secondResolved);
        }
      }
    }
    if (urls.length >= maxTotalUrls) break;
  }

  if (urls.isEmpty) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final url in urls) {
      if (isMounted != null && !isMounted()) return;
      if (preloadedUrls.add(url)) {
        precacheImage(
          CachedNetworkImageProvider(url, cacheManager: AppImageCache.cacheManager),
          context,
        ).catchError((_) {});
      }
    }
  });
}
