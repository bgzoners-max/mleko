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
  /// Za brži scroll na listama – isključi fade-in animaciju.
  final Duration? fadeInDuration;

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
    this.fadeInDuration,
  });

  /// Za thumbnails u gridu (400x250), bez fade-in za brži scroll.
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
        fadeInDuration: Duration.zero,
      );

  /// Za male ikone (120x120), bez fade-in za brži scroll u listama.
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
        fadeInDuration: Duration.zero,
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
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 500),
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
    );
  }
}
