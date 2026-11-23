import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../core/haptic.dart';
import '../../../models/classified_ad_model.dart';
import '../../../models/user_model.dart';
import '../../../theme/app_design.dart';

/// Kartica oglašivača u Domaći Market stilu:
/// - Identitet oglašivača (avatar, ime, bedž verifikacije, grad, datum članstva, ocena)
/// - Brze akcije (`Svi oglasi (N)`, `Prati prodavca`, opciono `Poseti gazdinstvo`)
/// - Integrisana diskretna zakonska napomena u donjem pojasu kartice
class ClassifiedSellerSidebar extends StatelessWidget {
  const ClassifiedSellerSidebar({
    super.key,
    required this.ad,
    required this.isDark,
    required this.isOwner,
    this.sellerProfile,
    this.sellerAvgRating = 0,
    this.sellerReviewCount = 0,
    this.sellerActiveAdsCount = 0,
    this.isFollowingSeller = false,
    this.isTogglingFollow = false,
    this.onToggleFollowSeller,
    this.onViewAllSellerAds,
  });

  final ClassifiedAdModel ad;
  final bool isDark;
  final bool isOwner;
  final UserModel? sellerProfile;
  final double sellerAvgRating;
  final int sellerReviewCount;
  final int sellerActiveAdsCount;
  final bool isFollowingSeller;
  final bool isTogglingFollow;
  final VoidCallback? onToggleFollowSeller;
  final VoidCallback? onViewAllSellerAds;

  String? _formatMemberSince(DateTime? dt) {
    if (dt == null) return null;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return 'Član od $d.$m.${dt.year}.';
  }

  String _reviewWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod10 == 1 && mod100 != 11) return 'ocena';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'ocene';
    }
    return 'ocena';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final primaryText =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;
    final linkColor = isDark ? AmazonColors.lightGreen : AmazonColors.link;

    final sellerDisplayName = ad.sellerName ??
        sellerProfile?.farmName ??
        sellerProfile?.displayName ??
        'Korisnik Domaćeg Marketa';
    final sellerAvatar = ad.sellerAvatar ?? sellerProfile?.profileImageUrl;
    final isVerified = sellerProfile?.isVerified == true;
    final memberSince = _formatMemberSince(sellerProfile?.createdAt);
    final isFoodSeller = sellerProfile?.isSeller == true;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDesign.spaceM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Oglašivač',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.12),
                      backgroundImage:
                          sellerAvatar != null && sellerAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(sellerAvatar)
                              : null,
                      child: sellerAvatar == null || sellerAvatar.isEmpty
                          ? Icon(
                              ad.isBusinessSeller
                                  ? Icons.storefront_rounded
                                  : Icons.person_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            )
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
                                  sellerDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: primaryText,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 5),
                                Tooltip(
                                  message: 'Verifikovan nalog',
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AmazonColors.lightGreen
                                        : AmazonColors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                sellerProfile?.city?.trim().isNotEmpty == true
                                    ? sellerProfile!.city!
                                    : ad.city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                              if (memberSince != null)
                                Text(
                                  '· $memberSince',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (sellerReviewCount > 0) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.push('/seller/${ad.userId}/reviews'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFFAF6EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: isDark
                                ? AmazonColors.amberLight
                                : AmazonColors.amberDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sellerAvgRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '($sellerReviewCount ${_reviewWord(sellerReviewCount)})',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: secondaryText,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Akcije za prodavca: Svi oglasi + Prati prodavca u jednom urednom redu
                Row(
                  children: [
                    if (onViewAllSellerAds != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppHaptics.light();
                            onViewAllSellerAds!();
                          },
                          icon: const Icon(Icons.grid_view_rounded, size: 15),
                          label: Text(
                            sellerActiveAdsCount > 0
                                ? 'Svi oglasi ($sellerActiveAdsCount)'
                                : 'Svi oglasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 8,
                            ),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    if (onViewAllSellerAds != null &&
                        !isOwner &&
                        onToggleFollowSeller != null)
                      const SizedBox(width: 8),
                    if (!isOwner && onToggleFollowSeller != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isTogglingFollow ? null : onToggleFollowSeller,
                          icon: isTogglingFollow
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  isFollowingSeller
                                      ? Icons.bookmark_added_rounded
                                      : Icons.person_add_alt_1_outlined,
                                  size: 15,
                                  color: isFollowingSeller ? linkColor : null,
                                ),
                          label: Text(
                            isFollowingSeller
                                ? 'Pratiš prodavca'
                                : 'Prati prodavca',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isFollowingSeller ? linkColor : null,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 9,
                              horizontal: 8,
                            ),
                            side: BorderSide(
                              color: isFollowingSeller
                                  ? linkColor.withValues(alpha: 0.5)
                                  : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                if (isFoodSeller) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/seller/${ad.userId}'),
                    icon: Icon(
                      Icons.agriculture_rounded,
                      size: 16,
                      color: linkColor,
                    ),
                    label: Text(
                      'Poseti gazdinstvo na Pijaci hrane',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: linkColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Integrisana zakonska napomena u donjem pojasu kartice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8F9FA),
              border: Border(
                top: BorderSide(color: borderColor.withValues(alpha: 0.75)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad.isBusinessSeller
                      ? 'Registrovani trgovac · Primenjuju se odredbe Zakona o zaštiti potrošača.'
                      : 'Fizičko lice · Na kupovinu od fizičkog lica ne primenjuju se odredbe Zakona o zaštiti potrošača.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => context.push('/uslovi-koriscenja'),
                  child: Text(
                    'Uslovi korišćenja platforme →',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: linkColor,
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
