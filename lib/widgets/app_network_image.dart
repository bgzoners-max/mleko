import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Zajednički wrapper za mrežne slike – placeholder, error i memCache za optimizaciju.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  /// Za thumbnails u gridu (400x250)
  factory AppNetworkImage.thumbnail({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) =>
      AppNetworkImage(
        key: key,
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: 400,
        memCacheHeight: 250,
      );

  /// Za male ikone (120x120)
  factory AppNetworkImage.icon({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
  }) =>
      AppNetworkImage(
        key: key,
        imageUrl: imageUrl,
        width: width,
        height: height,
        memCacheWidth: 120,
        memCacheHeight: 120,
      );

  static Widget _defaultPlaceholder() => ColoredBox(
        color: Colors.grey.shade200,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
          ),
        ),
      );

  static Widget _defaultError({double iconSize = 48}) => ColoredBox(
        color: Colors.grey.shade200,
        child: Icon(Icons.broken_image, size: iconSize, color: Colors.grey.shade400),
      );

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
    );
  }
}
