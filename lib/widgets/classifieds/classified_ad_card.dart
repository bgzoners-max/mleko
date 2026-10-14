import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../models/classified_ad_model.dart';
import 'classified_ad_card_media.dart';

/// Amazon Marketplace kompaktna kartica za male oglase:
/// - Kompaktne dimenzije sa visokom gustinom informacija
/// - Zum animacija slike na hover
/// - Istaknuta Amazon hijerarhija cene (velike crvene cifre #B12704 + valuta)
/// - Moderni Amazon bedževi (Istaknuto u zlatno-jantarnoj #FF9900, Hitno u deal crvenoj #CC0C39, Novo u zelenoj)
/// - Prikaz prodavca/oglašivača u Amazon link stilu (#007185), lokacije i vremena objave
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ad = widget.ad;

    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = _isHovered
        ? AmazonColors.amberDark
        : (ad.isCurrentlyFeatured
            ? AmazonColors.amber
            : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray));

    final borderRadius = BorderRadius.circular(10);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor,
            width: ad.isCurrentlyFeatured ? 1.4 : (_isHovered ? 1.2 : 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? (ad.isCurrentlyFeatured
                      ? AmazonColors.amber.withValues(alpha: _isHovered ? 0.25 : 0.1)
                      : Colors.black.withValues(alpha: _isHovered ? 0.4 : 0.15))
                  : (ad.isCurrentlyFeatured
                      ? AmazonColors.amber.withValues(alpha: _isHovered ? 0.2 : 0.08)
                      : Colors.black.withValues(alpha: _isHovered ? 0.09 : 0.025)),
              blurRadius: _isHovered ? 10 : 4,
              offset: Offset(0, _isHovered ? 4 : 1),
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
              ClassifiedAdCardMedia(
                ad: ad,
                isHovered: _isHovered,
                isDark: isDark,
              ),

              // 2. Sadržaj oglasa (Amazon format cene i kompaktne tipografije)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amazon stil cene (istaknuta Deal Red boja)
                    _buildPriceSection(context, ad, isDark),
                    const SizedBox(height: 4),

                    // Naslov oglasa (hover podvlačenje / narandžasti hover)
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.24,
                        letterSpacing: -0.1,
                        color: _isHovered
                            ? (isDark ? AmazonColors.amberLight : AmazonColors.linkHover)
                            : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
                        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: isDark ? AmazonColors.amberLight : AmazonColors.linkHover,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Specifikacije nekretnine (m², sobe, sprat)
                    if (ad.isRealEstate) ...[
                      const SizedBox(height: 3),
                      _buildRealEstateSpecs(ad, isDark),
                    ],

                    const SizedBox(height: 6),

                    // Prodavac ili kategorija u Amazon link stilu
                    if (ad.sellerName != null && ad.sellerName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            ad.isBusinessSeller
                                ? Icons.storefront_outlined
                                : Icons.person_outline_rounded,
                            size: 12,
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ad.sellerName!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? AmazonColors.amberLight : AmazonColors.link,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ad.isBusinessSeller
                                  ? const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.22 : 0.1)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: ad.isBusinessSeller
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              ad.sellerTypeBadgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ad.isBusinessSeller
                                    ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                    : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ] else if (ad.categoryName != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.categoryName!,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: ad.isBusinessSeller
                                  ? const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.22 : 0.1)
                                  : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: ad.isBusinessSeller
                                    ? const Color(0xFF2563EB).withValues(alpha: 0.35)
                                    : (isDark ? Colors.white12 : Colors.black12),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              ad.sellerTypeBadgeText,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: ad.isBusinessSeller
                                    ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                    : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Lokacija i vreme objave
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            ad.city,
                            style: TextStyle(
                              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ad.timeAgo,
                          style: TextStyle(
                            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                            fontSize: 9.5,
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
    bool isDark,
  ) {
    if (ad.priceType == 'free') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: (isDark ? AmazonColors.lightGreen : AmazonColors.green).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'BESPLATNO',
          style: TextStyle(
            color: isDark ? AmazonColors.lightGreen : AmazonColors.green,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    if (ad.priceType == 'call') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AmazonColors.navNavy.withValues(alpha: isDark ? 0.3 : 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Cena na upit',
          style: TextStyle(
            color: isDark ? Colors.white : AmazonColors.darkNavy,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      );
    }

    if (ad.priceType == 'negotiable' && ad.price <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
        decoration: BoxDecoration(
          color: AmazonColors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Dogovor',
          style: TextStyle(
            color: AmazonColors.amberDark,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      );
    }

    // Standardna cena sa dominantnim Amazon-stilom (crvene masne cifre)
    final formattedNumber = _formatPriceNumber(ad.price);
    final m2Price = ad.pricePerM2;
    final arPrice = ad.pricePerAr;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formattedNumber,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              ad.currency,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            ),
            if (ad.priceType == 'negotiable') ...[
              const SizedBox(width: 4),
              Text(
                '· dogovor',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AmazonColors.amberLight : AmazonColors.amberDark,
                ),
              ),
            ],
          ],
        ),
        if (m2Price != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E3A4B) : AmazonColors.canvasLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
                width: 0.5,
              ),
            ),
            child: Text(
              '${m2Price.toStringAsFixed(0)} ${ad.currency}/m²',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            ),
          )
        else if (arPrice != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E3A4B) : AmazonColors.canvasLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
                width: 0.5,
              ),
            ),
            child: Text(
              '${arPrice.toStringAsFixed(0)} ${ad.currency}/ar',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRealEstateSpecs(
    ClassifiedAdModel ad,
    bool isDark,
  ) {
    final specs = <Widget>[];

    if (ad.realEstateAreaM2 != null && ad.realEstateAreaM2! > 0) {
      final m2 = ad.realEstateAreaM2!;
      final m2Str = m2 % 1 == 0 ? m2.toInt().toString() : m2.toStringAsFixed(1);
      specs.add(_buildSpecItem(Icons.square_foot_rounded, '$m2Str m²', isDark));
    }

    if (ad.realEstateLandAreaAri != null && ad.realEstateLandAreaAri! > 0) {
      final ari = ad.realEstateLandAreaAri!;
      final ariStr = ari % 1 == 0 ? ari.toInt().toString() : ari.toStringAsFixed(1);
      specs.add(_buildSpecItem(Icons.landscape_outlined, '$ariStr ar', isDark));
    }

    if (ad.realEstateRooms != null && ad.realEstateRooms!.isNotEmpty) {
      specs.add(_buildSpecItem(Icons.meeting_room_outlined, '${ad.realEstateRooms} sobe', isDark));
    }

    if (ad.realEstateFloor != null && ad.realEstateFloor!.isNotEmpty) {
      final fl = ad.realEstateFloor!;
      final flLabel = (int.tryParse(fl) != null) ? '$fl. sprat' : fl;
      specs.add(_buildSpecItem(Icons.layers_outlined, flLabel, isDark));
    }

    if (specs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: specs,
    );
  }

  Widget _buildSpecItem(
    IconData icon,
    String text,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 11,
          color: isDark ? AmazonColors.amberLight : AmazonColors.navNavy,
        ),
        const SizedBox(width: 2.5),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
