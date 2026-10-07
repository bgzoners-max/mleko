import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/design_system.dart';
import '../core/haptic.dart';
import '../models/product_model.dart';
import '../providers/app_settings_provider.dart';
import 'app_network_image.dart';
import 'rustic_image_placeholder.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool isPopular;
  final double? avgRating;
  final int? reviewCount;

  /// Da li je omogućen Hero prelaz. Podrazumevano `false` radi sprečavanja konflikta
  /// dupliranih Hero tagova kada se isti proizvod pojavi na više mesta na ekranu
  /// (npr. grid feed + "popularno" carousel).
  final bool enableHero;
  final String? heroTag;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite,
    this.onFavoriteToggle,
    this.isPopular = false,
    this.avgRating,
    this.reviewCount,
    this.enableHero = false,
    this.heroTag,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isNew {
    final diff = DateTime.now().difference(widget.product.createdAt).inDays;
    return diff < AppConstants.newProductDays;
  }

  Widget _buildCard(BuildContext context, bool gridMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = _isHovered
        ? AmazonColors.amber
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);

    final hasValidImage = widget.product.imageUrls.isNotEmpty &&
        !widget.product.imageUrls.first.contains('placehold.co');

    final imageChild = !hasValidImage
        ? const RusticImagePlaceholder()
        : AppNetworkImage.thumbnail(
            imageUrl: widget.product.imageUrls.first,
            fit: BoxFit.cover,
            placeholder: Container(
              color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF0EDE5),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: const RusticImagePlaceholder(),
          );

    final effectiveHeroTag =
        widget.heroTag ?? 'product_image_${widget.product.id}_0';

    final image = Stack(
      fit: gridMode ? StackFit.expand : StackFit.loose,
      children: [
        HeroMode(
          enabled: widget.enableHero,
          child: Hero(
            tag: effectiveHeroTag,
            child: AnimatedScale(
              scale: _isHovered ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: gridMode
                  ? SizedBox.expand(child: imageChild)
                  : AspectRatio(aspectRatio: 1.25, child: imageChild),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Badges top-left — blaga rotacija daje "ručno žigosan" pečat
        Positioned(
          top: 8,
          left: 8,
          child: Transform.rotate(
            angle: -0.035, // ≈ -2°: dovoljno da odiše zanatski, ne haotično
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (!widget.product.isAvailable)
                  const _AmazonBadge(
                    label: 'RASPRODATO',
                    backgroundColor: AmazonColors.slate,
                  ),
                if (_isNew)
                  const _AmazonBadge(
                    label: 'SVEŽE',
                    backgroundColor: AmazonColors.green,
                  ),
                if (widget.isPopular)
                  const _AmazonBadge(
                    label: 'PREPORUKA',
                    backgroundColor: AmazonColors.amber,
                    textColor: AmazonColors.darkNavy,
                  ),
                if (widget.product.sellerIsVerified)
                  const _AmazonBadge(
                    label: 'PROVERENO',
                    backgroundColor: AmazonColors.link,
                  ),
              ],
            ),
          ),
        ),
        // Brza akcija na hover (desktop grid)
        if (gridMode)
          Positioned(
            bottom: 8,
            left: 12,
            right: 12,
            child: AnimatedOpacity(
              opacity: _isHovered ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AmazonColors.amber,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Pogledaj detalje',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Favorite button top-right
        if (widget.onFavoriteToggle != null)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B241E).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  tooltip: widget.isFavorite == true
                      ? 'Ukloni iz omiljenih'
                      : 'Dodaj u omiljene',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      widget.isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      key: ValueKey(widget.isFavorite),
                      color: widget.isFavorite == true
                          ? const Color(0xFFE04F44)
                          : (isDark ? Colors.white70 : AmazonColors.textSecondary),
                      size: 18,
                    ),
                  ),
                  onPressed: () => withHaptic(widget.onFavoriteToggle),
                ),
              ),
            ),
          ),
      ],
    );

    final textContent = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Kategorija (warm forest moss / light green in dark mode)
          Text(
            widget.product.category.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // 2. Naziv proizvoda + verifikovan nalog
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.product.sellerIsVerified) ...[
                const SizedBox(width: 4),
                _VerifiedPulse(
                  child: Icon(
                    Icons.verified,
                    size: 14,
                    color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),

          // 3. Cena sa jasnom hijerarhijom + Ocena
          Builder(
            builder: (context) {
              // Bez string-parsiranja: broj, valuta i jedinica dolaze iz modela.
              final priceNum = widget.product.priceNumber;
              final priceUnit = widget.product.priceUnitSuffix;
              final animationsOn =
                  context.read<AppSettingsProvider?>()?.animationsEnabled ?? true;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    // Kada se cena osveži, iznos "tiho" klizne umesto da skoči.
                    child: AnimatedSwitcher(
                      duration: animationsOn
                          ? const Duration(milliseconds: 240)
                          : Duration.zero,
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.30),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      // Ključ po formatiranoj ceni: animira se samo pri promeni.
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: priceNum,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: isDark ? const Color(0xFFFF8B72) : AmazonColors.dealRed,
                              ),
                            ),
                            TextSpan(
                              text: ' ${ProductModel.priceCurrencyLabel}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFFF8B72) : AmazonColors.dealRed,
                              ),
                            ),
                            TextSpan(
                              text: priceUnit,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AmazonColors.darkTextSecondary
                                    : AmazonColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        key: ValueKey(widget.product.priceFormatted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (widget.avgRating != null && (widget.reviewCount ?? 0) > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AmazonColors.amber,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${widget.avgRating!.toStringAsFixed(1)} (${widget.reviewCount})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AmazonColors.darkTextSecondary
                                : AmazonColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),

          // 4. Lokacija i minimalna porudžbina
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: isDark
                    ? AmazonColors.darkTextSecondary
                    : AmazonColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.product.location,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AmazonColors.darkTextSecondary
                        : AmazonColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? AmazonColors.darkBorder.withValues(alpha: 0.5)
                      : const Color(0xFFF0ECE1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'min ${widget.product.minOrderFormatted}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AmazonColors.darkTextSecondary
                        : AmazonColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // 5. Ako nije grid (npr. lista), prikaži dugme
          if (!gridMode) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AmazonColors.amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => withHaptic(
                    () => context.push('/product/${widget.product.id}')),
                child: const Text(
                  'Pogledaj ponudu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _isHovered ? -4.0 : 0, 0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusL),
        border: Border.all(
          color: borderColor,
          width: _isHovered ? 1.2 : 1.0,
        ),
        boxShadow: AmazonColors.getCardShadow(context, isHovered: _isHovered),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        enabled: true,
        label:
            'Proizvod ${widget.product.name}. Cena ${widget.product.priceFormatted}.',
        child: InkWell(
          onTap: () =>
              withHaptic(() => context.push('/product/${widget.product.id}')),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (gridMode) Expanded(child: image) else image,
              textContent,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      // Blagi "stisak" kartice pri pritisku — povratna informacija da je tap
      // registrovan (na webu se kombinuje sa hover lift-om iz _buildCard).
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridMode = constraints.maxHeight.isFinite;
          return _buildCard(context, gridMode);
        },
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: card,
    );
  }
}

class _AmazonBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _AmazonBadge({
    required this.label,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Statički verified badge bez AnimationController-a i tickera po kartici.
/// Sprečava dženk na slabijim uređajima u gridovima sa mnogo kartica.
class _VerifiedPulse extends StatelessWidget {
  final Widget child;

  const _VerifiedPulse({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

