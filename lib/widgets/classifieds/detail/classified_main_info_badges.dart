import 'package:flutter/material.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';

/// Kompaktni bedževi statusa, stanja, isticanja i tipa oglašivača
/// prikazani u zaglavlju kartice detalja malog oglasa.
class ClassifiedMainInfoBadges extends StatelessWidget {
  const ClassifiedMainInfoBadges({
    super.key,
    required this.ad,
    required this.isDark,
  });

  final ClassifiedAdModel ad;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
    );
  }

  Widget _buildFeaturedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AmazonColors.amber,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 13, color: AmazonColors.textPrimary),
          SizedBox(width: 4),
          Text(
            'ISTAKNUT',
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
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 13, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'HITNO',
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
        borderRadius: BorderRadius.circular(5),
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
        borderRadius: BorderRadius.circular(5),
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
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        ad.isSold
            ? 'PRODATO'
            : ad.isRejected
                ? 'UKLONJENO'
                : ad.isArchived
                    ? 'ARHIVIRANO'
                    : 'AKTIVAN',
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
