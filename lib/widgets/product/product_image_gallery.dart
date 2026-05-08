import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../app_network_image.dart';
import 'full_screen_image_viewer.dart';

class ProductImageGallery extends StatefulWidget {
  final ProductModel product;
  final double height;

  const ProductImageGallery({
    super.key,
    required this.product,
    required this.height,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.product.imageUrls.length > 1;
    final isTablet = Breakpoints.isTabletOrLarger(context);

    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: widget.height,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
              child: widget.product.imageUrls.isEmpty
                  ? const Center(
                      child: Icon(Icons.image_not_supported, size: 64),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemCount: widget.product.imageUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              opaque: false,
                              barrierColor: Colors.black87,
                              barrierDismissible: true,
                              pageBuilder: (BuildContext context, _, __) {
                                return FullScreenImageViewer(
                                  productId: widget.product.id,
                                  imageUrls: widget.product.imageUrls,
                                  initialIndex: i,
                                );
                              },
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                        child: Center(
                          child: Hero(
                            tag: 'product_image_${widget.product.id}_$i',
                            child: AppNetworkImage(
                              imageUrl: widget.product.imageUrls[i],
                              width: double.infinity,
                              height: widget.height,
                              fit: BoxFit.contain,
                              memCacheWidth: 800,
                              fadeInDuration: Duration.zero,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            if (widget.product.imageUrls.isNotEmpty)
              Positioned(
                right: 12,
                bottom: 12,
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fullscreen,
                            color: Colors.white, size: 18),
                        if (hasMultipleImages) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_pageIndex + 1} / ${widget.product.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            if (isTablet && hasMultipleImages) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: _pageIndex > 0
                          ? () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      tooltip: 'Prethodna slika',
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: _pageIndex < widget.product.imageUrls.length - 1
                          ? () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      tooltip: 'Sledeća slika',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasMultipleImages) _buildGalleryThumbnails(widget.product),
      ],
    );
  }

  Widget _buildGalleryThumbnails(ProductModel product) {
    return Container(
      height: 84,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              product.imageUrls.length,
              (i) {
                final isSelected = _pageIndex == i;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    margin: EdgeInsets.only(
                      left: i == 0 ? 16 : 6,
                      right: i == product.imageUrls.length - 1 ? 16 : 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.5,
                        child: AppNetworkImage.thumbnail(
                          imageUrl: product.imageUrls[i],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
