import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/responsive.dart';
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
  final FocusNode _focusNode = FocusNode();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (widget.imageUrls.length <= 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousImage() {
    if (widget.imageUrls.length <= 1) return;
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).maybePop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);
    final hasMultipleImages = widget.imageUrls.length > 1;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Pozadinski klik za zatvaranje
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),

            // PageView sa podrškom za miš, tačped i touch
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: PageView.builder(
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
                        child: AppNetworkImage(
                          imageUrl: widget.imageUrls[realIndex],
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Dugme za zatvaranje (gore desno)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Tooltip(
                message: 'Zatvori (Esc)',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Navigacione strelice levo i desno na desktopu i mobilnom
            if (hasMultipleImages) ...[
              // LEVA STRELICA
              Positioned(
                left: isDesktop ? 24 : 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Tooltip(
                    message: 'Prethodna slika (←)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _previousImage,
                        borderRadius: BorderRadius.circular(30),
                        hoverColor: Colors.white24,
                        child: Container(
                          width: isDesktop ? 54 : 44,
                          height: isDesktop ? 54 : 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: isDesktop ? 38 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // DESNA STRELICA
              Positioned(
                right: isDesktop ? 24 : 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Tooltip(
                    message: 'Sledeća slika (→)',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _nextImage,
                        borderRadius: BorderRadius.circular(30),
                        hoverColor: Colors.white24,
                        child: Container(
                          width: isDesktop ? 54 : 44,
                          height: isDesktop ? 54 : 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: isDesktop ? 38 : 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Indikator pozicije i thumbnail traka na dnu
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isDesktop) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.imageUrls.length,
                              (i) {
                                final isSelected = _currentIndex == i;
                                return GestureDetector(
                                  onTap: () {
                                    final currentPos =
                                        _pageController.page?.round() ?? 0;
                                    final currentMod =
                                        currentPos % widget.imageUrls.length;
                                    final diff = i - currentMod;
                                    _pageController.animateToPage(
                                      currentPos + diff,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white30,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: AppNetworkImage.thumbnail(
                                        imageUrl: widget.imageUrls[i],
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
