import 'package:flutter/material.dart';

import '../../../models/classified_ad_model.dart';
import '../../../widgets/app_network_image.dart';

/// Galerija slika malog oglasa:
/// - Na desktopu prikazuje vertikalnu kolonu thumbnail-a sa leve strane (sa ▲/▼ strelicama)
///   i kompaktnu glavnu sliku (`360 px` visine, `BoxFit.contain`) sa bedžom `1 od N` pri dnu.
/// - Na mobilnom prikazuje kompaktnu glavnu sliku (`280 px`) i horizontalni strip ispod.
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
  static const double _mobileGalleryHeight = 280;
  static const double _thumbSize = 56;
  static const double _thumbGap = 8;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _scrollThumbnailsBy(double delta) {
    if (!_thumbScrollController.hasClients) return;
    final target = (_thumbScrollController.offset + delta).clamp(
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final hasMultiple = widget.ad.images.length > 1;
    final mainViewer = _buildMainImageViewer(height: height, isDark: isDark);

    if (widget.isDesktop && hasMultiple) {
      return SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildVerticalThumbnailRail(isDark: isDark),
            const SizedBox(width: 10),
            Expanded(child: mainViewer),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: height, child: mainViewer),
        if (hasMultiple) ...[
          const SizedBox(height: 10),
          _buildHorizontalThumbnailStrip(),
        ],
      ],
    );
  }

  Widget _buildMainImageViewer({
    required double height,
    required bool isDark,
  }) {
    final hasMultiple = widget.ad.images.length > 1;
    final frameBg = isDark ? const Color(0xFF14181E) : const Color(0xFFF1F3F5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        color: frameBg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.ad.images.length,
              onPageChanged: (i) {
                setState(() => _currentImageIndex = i);
                _scrollThumbIntoView(i);
              },
              itemBuilder: (ctx, i) {
                return _ClassifiedGalleryKeepAliveItem(
                  child: InkWell(
                    onTap: () => widget.onImageTap(widget.ad.images, i),
                    child: Center(
                      child: AppNetworkImage(
                        imageUrl: widget.ad.images[i],
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
                          child: const Icon(Icons.broken_image, size: 52),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Fullscreen dugme u gornjem desnom uglu
            Positioned(
              top: 10,
              right: 10,
              child: InkWell(
                onTap: () =>
                    widget.onImageTap(widget.ad.images, _currentImageIndex),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // Leva strelica
            if (hasMultiple && _currentImageIndex > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.48),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _selectImage(_currentImageIndex - 1),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Desna strelica
            if (hasMultiple && _currentImageIndex < widget.ad.images.length - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.48),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _selectImage(_currentImageIndex + 1),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Centrirani brojač slika (1 od N) pri dnu — kao na KP
            if (hasMultiple)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_currentImageIndex + 1} od ${widget.ad.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Oznaka "PRODATO"
            if (widget.ad.isSold)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.68),
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

  Widget _buildVerticalThumbnailRail({required bool isDark}) {
    final canScroll = widget.ad.images.length > 5;
    final buttonBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SizedBox(
      width: _thumbSize + 4,
      child: Column(
        children: [
          if (canScroll) ...[
            InkWell(
              onTap: () => _scrollThumbnailsBy(-(_thumbSize + _thumbGap) * 2),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 22,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: ListView.separated(
              controller: _thumbScrollController,
              itemCount: widget.ad.images.length,
              separatorBuilder: (_, __) => const SizedBox(height: _thumbGap),
              itemBuilder: (ctx, idx) => _buildThumbTile(idx),
            ),
          ),
          if (canScroll) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _scrollThumbnailsBy((_thumbSize + _thumbGap) * 2),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 22,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: buttonBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHorizontalThumbnailStrip() {
    return SizedBox(
      height: _thumbSize + 4,
      child: ListView.separated(
        controller: _thumbScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: widget.ad.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: _thumbGap),
        itemBuilder: (ctx, idx) => _buildThumbTile(idx),
      ),
    );
  }

  Widget _buildThumbTile(int idx) {
    final isSelected = _currentImageIndex == idx;
    return InkWell(
      onTap: () => _selectImage(idx),
      borderRadius: BorderRadius.circular(8),
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
            width: isSelected ? 2.2 : 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: Opacity(
            opacity: isSelected ? 1.0 : 0.78,
            child: AppNetworkImage.thumbnail(
              imageUrl: widget.ad.images[idx],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassifiedGalleryKeepAliveItem extends StatefulWidget {
  final Widget child;
  const _ClassifiedGalleryKeepAliveItem({required this.child});

  @override
  State<_ClassifiedGalleryKeepAliveItem> createState() =>
      _ClassifiedGalleryKeepAliveItemState();
}

class _ClassifiedGalleryKeepAliveItemState
    extends State<_ClassifiedGalleryKeepAliveItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
