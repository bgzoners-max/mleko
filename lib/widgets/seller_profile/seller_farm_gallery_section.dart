import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/responsive.dart';

class SellerFarmGallerySection extends StatelessWidget {
  final List<String> urls;

  const SellerFarmGallerySection({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    final isLargeTablet = Breakpoints.isLargeTablet(context);
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galerija',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isLargeTablet ? 20 : null,
                )),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final galleryHeight = Breakpoints.adaptiveDouble(
              context,
              phone: 168,
              smallTabletValue: 188,
              largeTabletValue: 220,
              desktop: 240,
            );
            final tileWidth = constraints.maxWidth *
                (Breakpoints.isDesktop(context)
                    ? 0.9
                    : (isLargeTablet ? 0.88 : (isSmallTablet ? 0.86 : 0.84)));

            return SizedBox(
              height: galleryHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: urls.length,
                itemBuilder: (_, i) => Padding(
                  padding:
                      EdgeInsets.only(right: i == urls.length - 1 ? 0 : 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      width: tileWidth,
                      memCacheWidth: 900,
                      memCacheHeight: 600,
                      height: galleryHeight,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
