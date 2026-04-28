import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

  /// Za thumbnails u gridu (400px širina, visina proporcionalna), bez fade-in za brži scroll.
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

  /// Za male profile slike (48x48), bez fade-in.
  factory AppNetworkImage.profileSmall({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
  }) =>
      AppNetworkImage(
        key: key,
        imageUrl: imageUrl,
        width: width ?? 48,
        height: height ?? 48,
        memCacheWidth: 48,
        memCacheHeight: 48,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        placeholder: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: width ?? 48,
            height: height ?? 48,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      );

  /// Za veće profile slike (120x120), bez fade-in.
  factory AppNetworkImage.profileLarge({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
  }) =>
      AppNetworkImage(
        key: key,
        imageUrl: imageUrl,
        width: width ?? 120,
        height: height ?? 120,
        memCacheWidth: 120,
        memCacheHeight: 120,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        placeholder: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: width ?? 120,
            height: height ?? 120,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      );

  /// Za seller banner slike (800x300), sa fade-in.
  factory AppNetworkImage.banner({
    Key? key,
    required String imageUrl,
    double? width,
    double? height,
  }) =>
      AppNetworkImage(
        key: key,
        imageUrl: imageUrl,
        width: width,
        height: height ?? 180,
        memCacheWidth: 800,
        memCacheHeight: 300,
        fit: BoxFit.cover,
      );

  /// Za product detail slike (600x600), sa fade-in.
  factory AppNetworkImage.productDetail({
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
        memCacheWidth: 600,
        memCacheHeight: 600,
        fit: BoxFit.contain,
      );

  static Widget _defaultPlaceholder() => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(color: Colors.white),
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
