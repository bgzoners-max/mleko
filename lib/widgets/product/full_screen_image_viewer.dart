import 'package:flutter/material.dart';
import '../app_network_image.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String productId;
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.productId,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    // Postavljamo početnu stranicu na veliki broj kako bismo dobili iluziju
    // beskonačnog scroll-a unazad (left swipe) od samog početka.
    final initialPage = widget.imageUrls.isNotEmpty
        ? 10000 * widget.imageUrls.length + widget.initialIndex
        : 0;
    _pageController = PageController(initialPage: initialPage);
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _nextImage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousImage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 2, -position.dy * 2, 0.0, 1.0)
        ..scaleByDouble(3.0, 3.0, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (widget.imageUrls.isNotEmpty) {
                setState(() {
                  _currentIndex = index % widget.imageUrls.length;
                  _transformationController.value = Matrix4.identity();
                });
              }
            },
            itemBuilder: (context, index) {
              if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
              final realIndex = index % widget.imageUrls.length;
              return GestureDetector(
                onDoubleTapDown: _handleDoubleTapDown,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'product_image_${widget.productId}_$realIndex',
                      child: AppNetworkImage(
                        imageUrl: widget.imageUrls[realIndex],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 36),
                    onPressed: _previousImage,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right,
                        color: Colors.white, size: 36),
                    onPressed: _nextImage,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
