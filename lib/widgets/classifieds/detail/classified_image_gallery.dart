import 'package:flutter/material.dart';
import '../../../models/classified_ad_model.dart';
import '../../../widgets/app_network_image.dart';

class ClassifiedImageGallery extends StatefulWidget {
  final ClassifiedAdModel ad;
  final ColorScheme colorScheme;
  final bool isDesktop;
  final void Function(List<String> images, int index) onImageTap;

  const ClassifiedImageGallery({
    super.key,
    required this.ad,
    required this.colorScheme,
    required this.isDesktop,
    required this.onImageTap,
  });

  @override
  State<ClassifiedImageGallery> createState() => _ClassifiedImageGalleryState();
}

class _ClassifiedImageGalleryState extends State<ClassifiedImageGallery> {
  late PageController _pageController;
  int _currentImageIndex = 0;

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
    if (widget.ad.images.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.isDesktop ? 1.35 : 1.25,
        child: Container(
          decoration: BoxDecoration(
            color: widget.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    final hasMultiple = widget.ad.images.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Glavna slika (Hero)
        AspectRatio(
          aspectRatio: widget.isDesktop ? 1.35 : 1.25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.ad.images.length,
                  onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  itemBuilder: (ctx, i) {
                    return InkWell(
                      onTap: () => widget.onImageTap(widget.ad.images, i),
                      child: AppNetworkImage(
                        imageUrl: widget.ad.images[i],
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: widget.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: Container(
                          color: widget.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image, size: 60),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Zum ikonica u uglu
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => widget.onImageTap(widget.ad.images, _currentImageIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Leva strelica
              if (hasMultiple && _currentImageIndex > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),

              // Desna strelica
              if (hasMultiple && _currentImageIndex < widget.ad.images.length - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),

              // Brojač slika (1 / N)
              if (hasMultiple)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentImageIndex + 1} / ${widget.ad.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Oznaka "PRODATO"
              if (widget.ad.isSold)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'PRODATO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Thumbnail strip ispod glavne slike
        if (hasMultiple) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.ad.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final isSelected = _currentImageIndex == idx;
                return InkWell(
                  onTap: () {
                    setState(() => _currentImageIndex = idx);
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? widget.colorScheme.primary
                            : widget.colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage.thumbnail(
                        imageUrl: widget.ad.images[idx],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
