import 'package:flutter/material.dart';
import '../../../models/classified_ad_model.dart';
import '../../../theme/amazon_colors.dart';
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
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bedževi stanja, statusa, isticanja i hitnosti
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (ad.isCurrentlyFeatured) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                      ),
                    ],
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
                ),
              ],
              if (ad.isUrgent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AmazonColors.badgeRed,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                      ),
                    ],
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
                ),
              ],
              if (ad.showConditionBadge) ...[
                Container(
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
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ad.isBusinessSeller
                      ? const Color(0xFF1D4ED8)
                      : (isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFF475569)),
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
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ad.isSold
                      ? Colors.red.shade800.withValues(alpha: 0.12)
                      : ad.isRejected
                          ? Colors.red.shade900.withValues(alpha: 0.15)
                          : ad.isArchived
                              ? Colors.grey.shade800.withValues(alpha: 0.15)
                              : Colors.green.shade800.withValues(alpha: 0.12),
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
                                : Colors.green.shade800,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ad.timeAgo,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Naslov oglasa
          Text(
            ad.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Istaknuti blok cene (Amazon Style Deal Price Box)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AmazonColors.darkCanvas
                  : const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              ),
            ),
            child: Row(
              children: [
                Text(
                  ad.priceFormatted,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined, size: 16, color: AmazonColors.link),
                const SizedBox(width: 4),
                Text(
                  ad.city,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Na širokim ekranima, dugmad za akciju su smeštena direktno u ovaj box!
          if (isWide && actionButtons != null) ...[
            const SizedBox(height: 20),
            actionButtons!,
          ],
        ],
      ),
    );
  }
}
