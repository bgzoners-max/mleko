import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../core/haptic.dart';
import '../../../models/classified_ad_model.dart';
import '../../../models/user_model.dart';
import '../../../theme/app_design.dart';

/// Desni sidebar kartice prodavca, kontakta i pravne napomene (po uzoru na KP).
/// Može se koristiti i na desktopu (sa primarnim CTA na vrhu) i na mobilnom (bez duplog CTA).
class ClassifiedSellerSidebar extends StatelessWidget {
  const ClassifiedSellerSidebar({
    super.key,
    required this.ad,
    required this.isDark,
    required this.isOwner,
    required this.hasPhone,
    required this.isLoadingPhone,
    required this.currentPhone,
    required this.showPrimaryCta,
    required this.onChatTap,
    required this.onPhoneReveal,
    required this.onPhoneTap,
    required this.onEdit,
    required this.onMarkAsSold,
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
  final bool hasPhone;
  final bool isLoadingPhone;
  final String? currentPhone;
  final bool showPrimaryCta;
  final VoidCallback onChatTap;
  final VoidCallback onPhoneReveal;
  final VoidCallback onPhoneTap;
  final VoidCallback onEdit;
  final VoidCallback onMarkAsSold;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final primaryText =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;
    final linkColor = isDark ? AmazonColors.lightGreen : AmazonColors.link;

    final isPhoneRevealed =
        currentPhone != null && currentPhone!.trim().isNotEmpty;
    final sellerDisplayName = ad.sellerName ??
        sellerProfile?.farmName ??
        sellerProfile?.displayName ??
        'Korisnik Domaćeg Marketa';
    final sellerAvatar = ad.sellerAvatar ?? sellerProfile?.profileImageUrl;
    final isVerified = sellerProfile?.isVerified == true;
    final memberSince = _formatMemberSince(sellerProfile?.createdAt);
    final isFoodSeller = sellerProfile?.isSeller == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── KARTICA 1: KONTAKT & PODACI O OGLAŠIVAČU ──
        Container(
          padding: const EdgeInsets.all(AppDesign.spaceM),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: AmazonColors.getCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showPrimaryCta) ...[
                _buildTopCta(colorScheme),
                const SizedBox(height: 14),
                Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
                const SizedBox(height: 14),
              ],

              // Identitet prodavca
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    backgroundImage: sellerAvatar != null
                        ? CachedNetworkImageProvider(sellerAvatar)
                        : null,
                    onBackgroundImageError:
                        sellerAvatar != null ? (_, __) {} : null,
                    child: sellerAvatar == null
                        ? Icon(Icons.person_rounded,
                            color: colorScheme.primary, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 10),
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
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  color: primaryText,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 5),
                              Tooltip(
                                message: 'Verifikovano gazdinstvo',
                                child: Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: isDark
                                      ? AmazonColors.lightGreen
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ad.city,
                          style: TextStyle(fontSize: 12.5, color: secondaryText),
                        ),
                        if (memberSince != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            memberSince,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Ocene prodavca
              if (sellerReviewCount > 0) ...[
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => context.push('/seller/${ad.userId}/reviews'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                            color: linkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(height: 1, color: borderColor.withValues(alpha: 0.7)),
              const SizedBox(height: 6),

              // Lista akcija (KP stil)
              if (onViewAllSellerAds != null)
                _SellerActionLink(
                  icon: Icons.view_list_rounded,
                  label: sellerActiveAdsCount > 0
                      ? 'Svi oglasi ($sellerActiveAdsCount)'
                      : 'Svi oglasi prodavca',
                  isDark: isDark,
                  onTap: onViewAllSellerAds!,
                ),

              if (!isOwner && onToggleFollowSeller != null)
                _SellerActionLink(
                  icon: isFollowingSeller
                      ? Icons.bookmark_added_rounded
                      : Icons.person_add_alt_1_outlined,
                  label: isFollowingSeller
                      ? 'Sačuvan prodavac'
                      : 'Sačuvaj prodavca',
                  accentColor: isFollowingSeller
                      ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                      : null,
                  trailing: isTogglingFollow
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  isDark: isDark,
                  onTap: isTogglingFollow ? null : onToggleFollowSeller,
                ),

              if (hasPhone && !isOwner && ad.isAvailable)
                _SellerActionLink(
                  icon: isPhoneRevealed
                      ? Icons.phone_in_talk_rounded
                      : Icons.phone_outlined,
                  label: isLoadingPhone
                      ? 'Učitavanje broja...'
                      : (isPhoneRevealed
                          ? currentPhone!
                          : 'Klik za broj telefona'),
                  accentColor: isPhoneRevealed ? linkColor : null,
                  trailing: isLoadingPhone
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (isVerified
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 11,
                                    color: isDark
                                        ? AmazonColors.lightGreen
                                        : const Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verifikovan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AmazonColors.lightGreen
                                          : const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null),
                  isDark: isDark,
                  onTap: isLoadingPhone
                      ? null
                      : () {
                          AppHaptics.medium();
                          if (isPhoneRevealed) {
                            onPhoneTap();
                          } else {
                            onPhoneReveal();
                          }
                        },
                ),

              if (isFoodSeller)
                _SellerActionLink(
                  icon: Icons.eco_outlined,
                  label: 'Pogledaj gazdinstvo',
                  accentColor:
                      isDark ? AmazonColors.lightGreen : AmazonColors.green,
                  isDark: isDark,
                  onTap: () => context.push('/seller/${ad.userId}'),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── KARTICA 2: ZAKONSKA IZJAVA (FIZIČKO LICE / TRGOVAC) ──
        Container(
          padding: const EdgeInsets.all(AppDesign.spaceM),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ad.isBusinessSeller
                        ? Icons.storefront_rounded
                        : Icons.info_outline_rounded,
                    size: 16,
                    color: ad.isBusinessSeller
                        ? (isDark
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF1D4ED8))
                        : secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ad.isBusinessSeller
                          ? 'Oglašivač je registrovani trgovac.'
                          : 'Korisnik je izjavio da nije trgovac.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ad.sellerTypeLegalDisclaimer,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => context.push('/uslovi-koriscenja'),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'Uslovi korišćenja i prava kupaca →',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: linkColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCta(ColorScheme colorScheme) {
    if (isOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Izmeni oglas'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: ad.isSold ? null : onMarkAsSold,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: Text(ad.isSold ? 'Već prodat' : 'Označi prodato'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    }

    if (!ad.isAvailable) {
      final message = ad.isSold
          ? 'Ovaj oglas je označen kao prodat.'
          : ad.isRejected
              ? 'Ovaj oglas je uklonjen nakon moderacije.'
              : 'Ovaj oglas više nije aktivan.';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () {
        AppHaptics.medium();
        onChatTap();
      },
      icon: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: AmazonColors.darkNavy,
        size: 18,
      ),
      label: const Text(
        'Pošalji poruku',
        style: TextStyle(
          color: AmazonColors.darkNavy,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AmazonColors.amberLight,
        foregroundColor: AmazonColors.darkNavy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AmazonColors.amberDark, width: 0.9),
        ),
      ),
    );
  }
}

class _SellerActionLink extends StatelessWidget {
  const _SellerActionLink({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.accentColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? accentColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textColor = accentColor ??
        (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary);
    final iconColor = accentColor ??
        (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
