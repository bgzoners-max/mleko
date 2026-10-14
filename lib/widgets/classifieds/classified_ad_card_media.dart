import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';
import '../../models/classified_ad_model.dart';
import '../app_network_image.dart';

/// Vizuelna medijska komponenta za karticu oglasa:
/// - Prikaz slike uz suptilan hover zum
/// - Oznake za istaknute, hitne, nove oglase i tip transakcije
/// - Brojač slika i brza hover akcija
class ClassifiedAdCardMedia extends StatelessWidget {
  final ClassifiedAdModel ad;
  final bool isHovered;
  final bool isDark;

  const ClassifiedAdCardMedia({
    super.key,
    required this.ad,
    required this.isHovered,
    required this.isDark,
  });

  Color _getTransactionBadgeColor(String transactionType) {
    switch (transactionType.toLowerCase().trim()) {
      case 'izdavanje':
        return const Color(0xFF0284C7); // Sky blue
      case 'na_dan':
      case 'stan_na_dan':
        return const Color(0xFF0F766E); // Teal
      case 'prodaja':
      default:
        return AmazonColors.navNavy; // Navy
    }
  }

  String _getTransactionBadgeLabel(String transactionType) {
    switch (transactionType.toLowerCase().trim()) {
      case 'izdavanje':
        return 'IZDAVANJE';
      case 'na_dan':
      case 'stan_na_dan':
        return 'STAN NA DAN';
      case 'prodaja':
      default:
        return 'PRODAJA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = ad.images.isNotEmpty;
    final imageUrl = hasImage ? ad.images.first : null;

    return AspectRatio(
      aspectRatio: 1.25,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Slika sa blagim hover zumom
            AnimatedScale(
              scale: isHovered ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: hasImage && imageUrl != null
                  ? AppNetworkImage.thumbnail(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF3F3F3),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF3F3F3),
                        child: Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                            color: isDark ? Colors.white38 : AmazonColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF3F3F3),
                      child: Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 32,
                          color: isDark ? Colors.white38 : AmazonColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),

            // Gornji suptilni senčeni sloj za bolji kontrast bedževa
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
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
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AmazonColors.badgeRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PRODATO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bedževi stanja, isticanja i hitnosti
            Positioned(
              top: 6,
              left: 6,
              right: 6,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (ad.isCurrentlyFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AmazonColors.amber,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 11, color: AmazonColors.textPrimary),
                          SizedBox(width: 2),
                          Text(
                            'ISTAKNUTO',
                            style: TextStyle(
                              color: AmazonColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ad.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AmazonColors.badgeRed,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 11, color: Colors.white),
                          SizedBox(width: 1),
                          Text(
                            'HITNO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ad.showConditionBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ad.condition == 'new'
                            ? AmazonColors.green
                            : AmazonColors.navNavy.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        ad.conditionLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  if (ad.isRealEstate && ad.realEstateTransactionType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTransactionBadgeColor(ad.realEstateTransactionType!),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        _getTransactionBadgeLabel(ad.realEstateTransactionType!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Broj slika (ako ih ima više od 1)
            if (ad.images.length > 1)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AmazonColors.darkNavy.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_outlined, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        '${ad.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Brza akcija na hover (desktop)
            Positioned(
              bottom: 6,
              left: 8,
              child: AnimatedOpacity(
                opacity: isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Detalji oglasa',
                        style: TextStyle(
                          fontSize: 10,
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
          ],
        ),
      ),
    );
  }
}
