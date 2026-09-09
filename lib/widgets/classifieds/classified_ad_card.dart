import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system.dart';
import '../../core/haptic.dart';
import '../../models/classified_ad_model.dart';

/// Amazon-style premium kartica za male oglase:
/// - Podizanje na prelaz mišem (hover lift) sa mekom difuznom senkom
/// - Zum animacija slike na hover
/// - Istaknuta Amazon-style hijerarhija cene (velike masne cifre + valuta)
/// - Moderni bedževi stanja (Novo u smaragdnoj boji, Polovno, Dogovor)
/// - Prikaz prodavca/gazdinstva, lokacije sa čiolicom i broja fotografija
class ClassifiedAdCard extends StatefulWidget {
  final ClassifiedAdModel ad;
  final VoidCallback? onTap;

  const ClassifiedAdCard({
    super.key,
    required this.ad,
    this.onTap,
  });

  @override
  State<ClassifiedAdCard> createState() => _ClassifiedAdCardState();
}

class _ClassifiedAdCardState extends State<ClassifiedAdCard> {
  bool _isHovered = false;

  String _formatPriceNumber(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final ad = widget.ad;
    final hasImage = ad.images.isNotEmpty;
    final imageUrl = hasImage ? ad.images.first : null;

    final borderRadius = BorderRadius.circular(14);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.2),
            width: _isHovered ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: _isHovered ? 0.45 : 0.2)
                  : Colors.black.withValues(alpha: _isHovered ? 0.12 : 0.04),
              blurRadius: _isHovered ? 16 : 8,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AppHaptics.light();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              context.push('/classifieds/ad/${ad.id}');
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Slika sa zum efektom i Amazon bedževima
              AspectRatio(
                aspectRatio: 1.2,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Slika sa blagim hover zumom
                      AnimatedScale(
                        scale: _isHovered ? 1.04 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: hasImage && imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (ctx, url) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (ctx, url, error) => Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 32,
                                  ),
                                ),
                              )
                            : Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 38,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                      ),

                      // Gornji suptilni senčeni sloj za bolji kontrast bedževa
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Oznaka "PRODATO"
                      if (ad.isSold)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.7),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRODATO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Bedž stanja (Novo / Polovno / Dogovor)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            if (ad.showConditionBadge)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ad.condition == 'new'
                                      ? const Color(0xFF059669) // Emerald zelena
                                      : Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (ad.condition == 'new') ...[
                                      const Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      ad.conditionLabel.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Broj slika (ako ih ima više od 1)
                      if (ad.images.length > 1)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_camera_outlined, size: 11, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '${ad.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Sadržaj oglasa (Amazon format cene i tipografije)
              Padding(
                padding: const EdgeInsets.all(AppDesign.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amazon stil cene
                    _buildPriceSection(context, ad, colorScheme, isDark),
                    const SizedBox(height: 6),

                    // Naslov oglasa (hover podvlačenje / promena boje)
                    Text(
                      ad.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                        color: _isHovered ? colorScheme.primary : colorScheme.onSurface,
                        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Opciono: Prodavac ili kategorija
                    if (ad.sellerName != null && ad.sellerName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 13,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ad.sellerName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ] else if (ad.categoryName != null) ...[
                      Text(
                        ad.categoryName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: colorScheme.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Lokacija i vreme objave
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            ad.city,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ad.timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(
    BuildContext context,
    ClassifiedAdModel ad,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    if (ad.priceType == 'free') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'BESPLATNO',
          style: TextStyle(
            color: Color(0xFF059669),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    if (ad.priceType == 'call') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Cena na upit',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      );
    }

    if (ad.priceType == 'negotiable' && ad.price <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade800.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Dogovor',
          style: TextStyle(
            color: Colors.amber.shade900,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      );
    }

    // Standardna cena sa dominantnim Amazon-stilom
    final formattedNumber = _formatPriceNumber(ad.price);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formattedNumber,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : colorScheme.primary,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          ad.currency,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (ad.priceType == 'negotiable') ...[
          const SizedBox(width: 4),
          Text(
            '· dogovor',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ],
      ],
    );
  }
}
