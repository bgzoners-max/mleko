import 'package:flutter/material.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_design.dart';

class ClassifiedMainInfoCard extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isOwner;
  final bool hasPhone;
  final bool isWide;
  final Widget? actionButtons;
  final VoidCallback? onShare;
  final bool isFavorited;
  final bool isTogglingFavorite;
  final int? favoritesCount;
  final VoidCallback? onToggleFavorite;
  final bool embedded;

  const ClassifiedMainInfoCard({
    super.key,
    required this.ad,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
    required this.isOwner,
    required this.hasPhone,
    required this.isWide,
    this.actionButtons,
    this.onShare,
    this.isFavorited = false,
    this.isTogglingFavorite = false,
    this.favoritesCount,
    this.onToggleFavorite,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;
    final effectiveFavorites = favoritesCount ?? ad.favoritesCount;
    final secondaryEstimate = ad.secondaryCurrencyEstimate;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bedževi stanja, statusa, isticanja i hitnosti + opciono dugme Podeli
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (ad.isCurrentlyFeatured) _buildFeaturedBadge(),
                  if (ad.isUrgent) _buildUrgentBadge(),
                  if (ad.showConditionBadge) _buildConditionBadge(),
                  _buildSellerTypeBadge(),
                  _buildStatusBadge(),
                ],
              ),
            ),
            if (onShare != null) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Podeli oglas',
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(Icons.adaptive.share, size: 15),
                  label: const Text(
                    'Podeli',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Naslov oglasa + dugme "♡ Prati" (KP stil)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ad.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.24,
                  color: primaryText,
                ),
              ),
            ),
            if (!isOwner && onToggleFavorite != null) ...[
              const SizedBox(width: 12),
              _buildFavoriteToggleButton(secondaryText),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Cena + automatska procena u sekundarnoj valuti (EUR ↔ RSD)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? AmazonColors.darkCanvas : const Color(0xFFF7F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 2,
                  children: [
                    Text(
                      ad.priceFormatted,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? const Color(0xFFFF6B6B)
                            : AmazonColors.dealRed,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (secondaryEstimate != null)
                      Text(
                        secondaryEstimate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: isDark ? AmazonColors.lightGreen : AmazonColors.link,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      ad.city,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Kompaktna statistika u jednom redu (👁 pregledi · ♡ prati · 🕒 vreme · 📍 grad)
        Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _statChip(
              Icons.visibility_outlined,
              '${ad.viewsCount}',
              secondaryText,
              tooltip: 'Broj pregleda',
            ),
            _statChip(
              isFavorited
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              '$effectiveFavorites',
              isFavorited
                  ? (isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed)
                  : secondaryText,
              tooltip: 'Broj korisnika koji prate oglas',
            ),
            _statChip(
              Icons.schedule_rounded,
              ad.timeAgo,
              secondaryText,
              tooltip: 'Vreme objave',
            ),
            _statChip(
              Icons.place_outlined,
              ad.city,
              secondaryText,
              tooltip: 'Lokacija',
            ),
          ],
        ),

        // Opciona akciona dugmad ako ih pozivatelj prosledi (zadržano zbog kompatibilnosti)
        if (isWide && actionButtons != null) ...[
          const SizedBox(height: 18),
          actionButtons!,
        ],
      ],
    );

    if (embedded) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  Widget _buildFavoriteToggleButton(Color secondaryText) {
    final activeColor =
        isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed;
    final borderColor = isFavorited
        ? activeColor.withValues(alpha: 0.45)
        : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray);

    return Tooltip(
      message: isFavorited ? 'Ukloni iz sačuvanih oglasa' : 'Sačuvaj oglas',
      child: InkWell(
        onTap: isTogglingFavorite ? null : onToggleFavorite,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isFavorited
                ? activeColor.withValues(alpha: isDark ? 0.14 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTogglingFavorite)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorited ? activeColor : secondaryText,
                ),
              const SizedBox(height: 2),
              Text(
                isFavorited ? 'Praćeno' : 'Prati',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isFavorited ? activeColor : secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(
    IconData icon,
    String text,
    Color color, {
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AmazonColors.amber,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AmazonColors.textPrimary),
          SizedBox(width: 4),
          Text(
            'ISTAKNUT OGLAS',
            style: TextStyle(
              color: AmazonColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AmazonColors.badgeRed,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'HITNA PRODAJA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ad.condition == 'new'
            ? AmazonColors.green
            : AmazonColors.navNavy.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ad.condition == 'new') ...[
            const Icon(Icons.verified_rounded, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            ad.conditionLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ad.isBusinessSeller
            ? const Color(0xFF1D4ED8)
            : (isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFF475569)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ad.isBusinessSeller
                ? Icons.storefront_rounded
                : Icons.person_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            ad.isBusinessSeller ? 'TRGOVAC' : 'FIZIČKO LICE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ad.isSold
            ? Colors.red.shade800.withValues(alpha: 0.12)
            : ad.isRejected
                ? Colors.red.shade900.withValues(alpha: 0.15)
                : ad.isArchived
                    ? Colors.grey.shade800.withValues(alpha: 0.15)
                    : (isDark
                        ? AmazonColors.green.withValues(alpha: 0.25)
                        : Colors.green.shade800.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        ad.isSold
            ? 'PRODATO'
            : ad.isRejected
                ? 'UKLONJENO (MODERACIJA)'
                : ad.isArchived
                    ? 'ARHIVIRANO'
                    : 'AKTIVAN OGLAS',
        style: TextStyle(
          color: ad.isSold
              ? Colors.red.shade800
              : ad.isRejected
                  ? Colors.red.shade900
                  : ad.isArchived
                      ? Colors.grey.shade800
                      : (isDark
                          ? AmazonColors.lightGreen
                          : Colors.green.shade800),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
