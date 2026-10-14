import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/image_url_utils.dart';

/// Zajednički wrapper za mrežne slike – podržava automatsku server-side
/// transformaciju (Supabase Storage), fallback na original, placeholder, error i memCache.
class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final String? serverTransformedUrl;
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
    this.serverTransformedUrl,
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
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return AppNetworkImage(
      key: key,
      imageUrl: imageUrl,
      serverTransformedUrl: ImageUrlUtils.thumbnailUrl(imageUrl),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 400,
      fadeInDuration: Duration.zero,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

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
        serverTransformedUrl: ImageUrlUtils.iconUrl(imageUrl, size: 120),
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
        serverTransformedUrl: ImageUrlUtils.iconUrl(imageUrl, size: 96),
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
        serverTransformedUrl: ImageUrlUtils.iconUrl(imageUrl, size: 240),
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
        serverTransformedUrl: ImageUrlUtils.transformUrl(imageUrl, width: 800, height: 300, quality: 80),
        width: width,
        height: height ?? 180,
        memCacheWidth: 800,
        memCacheHeight: 300,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 400),
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
        serverTransformedUrl: ImageUrlUtils.detailUrl(imageUrl, width: 800, quality: 85),
        width: width,
        height: height,
        memCacheWidth: 600,
        memCacheHeight: 600,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 300),
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
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  bool _useServerTransform = true;

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.serverTransformedUrl != widget.serverTransformedUrl) {
      _useServerTransform = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverUrl = widget.serverTransformedUrl;
    final resolvedUrl =
        _useServerTransform && serverUrl != null ? serverUrl : widget.imageUrl;

    if (kIsWeb) {
      return Image.network(
        resolvedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return widget.placeholder ?? AppNetworkImage._defaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          if (_useServerTransform && serverUrl != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _useServerTransform = false);
              }
            });
          }
          return widget.errorWidget ?? AppNetworkImage._defaultError();
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      fadeInDuration: widget.fadeInDuration ?? const Duration(milliseconds: 500),
      fadeInCurve: Curves.easeInCubic,
      placeholder: (_, __) =>
          widget.placeholder ?? AppNetworkImage._defaultPlaceholder(),
      errorWidget: (context, url, error) {
        // Ako server transform nije uspeo, jednom bezbedno padni na originalni URL
        if (_useServerTransform && serverUrl != null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _useServerTransform = false);
            }
          });
        }
        return widget.errorWidget ?? AppNetworkImage._defaultError();
      },
    );
  }
}

/// Namenska komponenta za thumbnails sa kompatibilnim interfejsom
class AppNetworkImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final String? serverThumbnailUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImageThumbnail({
    super.key,
    required this.imageUrl,
    this.serverThumbnailUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppNetworkImage(
      imageUrl: imageUrl,
      serverTransformedUrl: serverThumbnailUrl ?? ImageUrlUtils.thumbnailUrl(imageUrl),
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: 400,
      fadeInDuration: Duration.zero,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
