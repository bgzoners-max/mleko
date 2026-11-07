import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../app_network_image.dart';
import '../product/full_screen_image_viewer.dart';

/// Sekcija galerije gazdinstva sa horizontalnim kompaktnim foto-karticama
/// i uvećanjem preko celog ekrana na klik.
class SellerFarmGallerySection extends StatefulWidget {
  final List<String> urls;

  const SellerFarmGallerySection({super.key, required this.urls});

  @override
  State<SellerFarmGallerySection> createState() =>
      _SellerFarmGallerySectionState();
}

class _SellerFarmGallerySectionState extends State<SellerFarmGallerySection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
  }

  @override
  void didUpdateWidget(covariant SellerFarmGallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls.length != widget.urls.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollButtons());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final canLeft = offset > 8;
    final canRight = offset < (max - 8);
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      if (mounted) {
        setState(() {
          _canScrollLeft = canLeft;
          _canScrollRight = canRight;
        });
      }
    }
  }

  void _scroll(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _openFullScreen(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (BuildContext context, _, __) {
          return FullScreenImageViewer(
            productId: 'farm-gallery',
            imageUrls: widget.urls,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Breakpoints.isDesktop(context);
    final isPhone = Breakpoints.isPhone(context);

    final cardHeight = isPhone ? 120.0 : (isDesktop ? 142.0 : 132.0);
    final cardWidth = isPhone ? 160.0 : (isDesktop ? 195.0 : 180.0);

    final headerIconBg = isDark
        ? const Color(0xFF1E3A27)
        : const Color(0xFFE8F5E9);
    final headerIconColor = isDark
        ? const Color(0xFF81C784)
        : const Color(0xFF2E7D32);
    final countBadgeBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF2B3A2E) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF1A241C) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zaglavlje sekcije: ikonica, naziv, brojač i strelice za scroll
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: headerIconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                    color: headerIconColor,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Galerija gazdinstva',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: countBadgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.urls.length}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isPhone) ...[
                  Text(
                    'Kliknite za uvećanje',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_canScrollLeft || _canScrollRight) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: _canScrollLeft
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade400,
                      ),
                      onPressed:
                          _canScrollLeft ? () => _scroll(-cardWidth * 2) : null,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: _canScrollRight
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey.shade400,
                      ),
                      onPressed:
                          _canScrollRight ? () => _scroll(cardWidth * 2) : null,
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Horizontalni niz kompaktnih foto-kartica
            SizedBox(
              height: cardHeight,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: widget.urls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = widget.urls[i];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openFullScreen(i),
                      child: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AppNetworkImage.thumbnail(
                                imageUrl: url,
                                width: cardWidth,
                                height: cardHeight,
                                fit: BoxFit.cover,
                                errorWidget: ColoredBox(
                                  color: isDark
                                      ? const Color(0xFF2D3748)
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 28,
                                    color: isDark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              // Blaga senka i zum ikonica u donjem desnom uglu
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
