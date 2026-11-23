import 'package:flutter/material.dart';

import '../../../models/classified_ad_model.dart';
import '../../../widgets/app_network_image.dart';

/// Kompaktna galerija slika malog oglasa u Domaći Market stilu:
/// - Kompaktna glavna slika (`360 px` na desktopu, `280 px` na mobilnom, `BoxFit.contain`)
///   sa diskretnim brojačem `1 / N` u donjem desnom uglu i dugmetom za ceo ekran.
/// - Horizontalni red thumbnail sličica ispod glavne slike (konzistentno sa Pijacom hrane).
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
  final ScrollController _thumbScrollController = ScrollController();
  int _currentImageIndex = 0;

  static const double _desktopGalleryHeight = 360;
  static const double _mobileGalleryHeight = 270;
  static const double _thumbSize = 58;
  static const double _thumbGap = 8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant ClassifiedImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ad.id != widget.ad.id) {
      _currentImageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    super.dispose();
  }

  void _selectImage(int idx) {
    if (idx < 0 || idx >= widget.ad.images.length) return;
    setState(() => _currentImageIndex = idx);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _scrollThumbIntoView(idx);
  }

  void _scrollThumbIntoView(int idx) {
    if (!_thumbScrollController.hasClients) return;
    final target = (idx * (_thumbSize + _thumbGap) - _thumbSize).clamp(
      0.0,
      _thumbScrollController.position.maxScrollExtent,
    );
    _thumbScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height =
        widget.isDesktop ? _desktopGalleryHeight : _mobileGalleryHeight;

    if (widget.ad.images.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: widget.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: widget.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.45),
              ),
              const SizedBox(height: 8),
              Text(
                'Oglas nema dodate fotografije',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMultiple = widget.ad.images.length > 1;
    final frameBg = isDark ? const Color(0xFF131A22) : const Color(0xFFF3F5F7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMainViewport(
          height: height,
          frameBg: frameBg,
          hasMultiple: hasMultiple,
        ),
        if (hasMultiple) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: _thumbSize,
            child: ListView.separated(
              controller: _thumbScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.ad.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
              itemBuilder: (_, idx) => _buildThumbTile(idx),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMainViewport({
    required double height,
    required Color frameBg,
    required bool hasMultiple,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: frameBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.ad.images.length,
              onPageChanged: (idx) {
                setState(() => _currentImageIndex = idx);
                _scrollThumbIntoView(idx);
              },
              itemBuilder: (ctx, idx) {
                final url = widget.ad.images[idx];
                return GestureDetector(
                  onTap: () => widget.onImageTap(widget.ad.images, idx),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.zoomIn,
                    child: Hero(
                      tag: 'ad_${widget.ad.id}_img_$idx',
                      child: AppNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: height,
                        fit: BoxFit.contain,
                        placeholder: Container(
                          color: frameBg,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: Container(
                          color: frameBg,
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Leva strelica
            if (hasMultiple && _currentImageIndex > 0)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _selectImage(_currentImageIndex - 1),
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
                  child: _navArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _selectImage(_currentImageIndex + 1),
                  ),
                ),
              ),

            // Donji desni ugao: kompaktan brojač + fullscreen (Domaći Market stil)
            Positioned(
              right: 12,
              bottom: 12,
              child: InkWell(
                onTap: () =>
                    widget.onImageTap(widget.ad.images, _currentImageIndex),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      if (hasMultiple) ...[
                        const SizedBox(width: 5),
                        Text(
                          '${_currentImageIndex + 1} / ${widget.ad.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Oznaka "PRODATO"
            if (widget.ad.isSold)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.66),
                  child: const Center(
                    child: Text(
                      'PRODATO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
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
    );
  }

  Widget _navArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildThumbTile(int idx) {
    final isSelected = idx == _currentImageIndex;
    return GestureDetector(
      onTap: () => _selectImage(idx),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: _thumbSize,
          height: _thumbSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? widget.colorScheme.primary
                  : widget.colorScheme.outlineVariant.withValues(alpha: 0.45),
              width: isSelected ? 2.2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.72,
            child: AppNetworkImage(
              imageUrl: widget.ad.images[idx],
              width: _thumbSize,
              height: _thumbSize,
              fit: BoxFit.cover,
              errorWidget: const Icon(Icons.broken_image, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}
