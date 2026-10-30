import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_design.dart';

class ClassifiedSellerCard extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const ClassifiedSellerCard({
    super.key,
    required this.ad,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacije o oglašivaču',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: ad.sellerAvatar != null
                    ? CachedNetworkImageProvider(ad.sellerAvatar!)
                    : null,
                child: ad.sellerAvatar == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ad.sellerName ?? 'Korisnik Domaćeg Marketa',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF059669),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ad.city,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ad.isBusinessSeller
                                ? const Color(0xFF1D4ED8).withValues(alpha: isDark ? 0.25 : 0.1)
                                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: ad.isBusinessSeller
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ad.isBusinessSeller ? Icons.storefront_rounded : Icons.person_rounded,
                                size: 10,
                                color: ad.isBusinessSeller
                                    ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                ad.sellerTypeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: ad.isBusinessSeller
                                      ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ad.isBusinessSeller
                  ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.12 : 0.06)
                  : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ad.isBusinessSeller
                    ? const Color(0xFF2563EB).withValues(alpha: 0.25)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ad.isBusinessSeller ? Icons.verified_user_outlined : Icons.shield_outlined,
                  size: 15,
                  color: ad.isBusinessSeller
                      ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ad.sellerTypeLegalDisclaimer,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
