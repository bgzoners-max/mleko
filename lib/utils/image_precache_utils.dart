import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'image_url_utils.dart';

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
        precacheImage(CachedNetworkImageProvider(url), context).catchError((_) {});
      }
    }
  });
}
