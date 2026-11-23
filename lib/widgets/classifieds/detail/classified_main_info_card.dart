import 'package:flutter/material.dart';

import '../../../core/design_system.dart' show AmazonColors;
import '../../../core/haptic.dart';
import '../../../models/classified_ad_model.dart';
import '../../../services/core/exchange_rate_service.dart';
import '../../../theme/app_design.dart';
import 'classified_main_info_badges.dart';

/// Glavna Domaći Market kartica oglasa (desna kolona na desktopu, hero kartica na mobilnom):
/// - Bedževi + meni opcija (`⋮`)
/// - Naslov oglasa
/// - Istaknuta cena sa automatskom `EUR ↔ RSD` procenom i lokacijom
/// - Kompaktna statistika (`👁 pregledi` · `♡ sačuvano` · `🕒 vreme`)
/// - Integrisani akcioni blok na desktopu (`Pošalji poruku`, inline `Broj telefona`, `♡ Sačuvaj`, `Podeli`)
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
  final bool isLoadingPhone;
  final String? currentPhone;
  final VoidCallback? onChatTap;
  final VoidCallback? onPhoneReveal;
  final VoidCallback? onPhoneTap;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkAsSold;
  final VoidCallback? onReport;

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
    this.isLoadingPhone = false,
    this.currentPhone,
    this.onChatTap,
    this.onPhoneReveal,
    this.onPhoneTap,
    this.onEdit,
    this.onMarkAsSold,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final primaryText =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    final secondaryText =
        isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary;
    final effectiveFavorites = favoritesCount ?? ad.favoritesCount;
    final hasBuiltInDesktopActions =
        isWide && actionButtons == null && (onChatTap != null || onEdit != null);

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.045),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Red 1: Bedževi + opciono dugme Podeli / ⋮ meni
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ClassifiedMainInfoBadges(ad: ad, isDark: isDark)),
              if (onShare != null && !hasBuiltInDesktopActions) ...[
                const SizedBox(width: 8),
                _buildCompactShareButton(),
              ],
              if (_hasOverflowMenu) _buildOverflowMenu(secondaryText),
            ],
          ),
          const SizedBox(height: 12),

          // Red 2: Naslov oglasa (+ dugme Sačuvaj na mobilnom)
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
              if (!isWide && !isOwner && onToggleFavorite != null) ...[
                const SizedBox(width: 10),
                _buildMobileSaveChip(secondaryText),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Red 3: Istaknut blok cene + EUR ↔ RSD procena + grad & statistika
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AmazonColors.darkCanvas : const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<EurRateInfo>(
                  valueListenable: ExchangeRateService.instance.rateNotifier,
                  builder: (_, rateInfo, __) {
                    final secondaryEstimate =
                        ad.secondaryCurrencyEstimateForRate(rateInfo.middle);
                    return Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
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
                          Tooltip(
                            message: rateInfo.sourceTooltip,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.045),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$secondaryEstimate · NBS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryText,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _statChip(
                      Icons.place_outlined,
                      ad.city,
                      isDark ? AmazonColors.lightGreen : AmazonColors.link,
                      tooltip: 'Lokacija',
                      bold: true,
                    ),
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
                          ? (isDark
                              ? const Color(0xFFFF6B6B)
                              : AmazonColors.dealRed)
                          : secondaryText,
                      tooltip: 'Sačuvano kod korisnika',
                    ),
                    _statChip(
                      Icons.schedule_rounded,
                      ad.timeAgo,
                      secondaryText,
                      tooltip: 'Objavljeno',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Red 4: Desktop akcioni blok integrisan u karticu oglasa
          if (hasBuiltInDesktopActions) ...[
            const SizedBox(height: 16),
            _buildDesktopActionBlock(),
          ] else if (isWide && actionButtons != null) ...[
            const SizedBox(height: 18),
            actionButtons!,
          ],
        ],
      ),
    );
  }

  bool get _hasOverflowMenu =>
      (!isOwner && onReport != null) || (isOwner && onEdit != null);

  Widget _buildDesktopActionBlock() {
    final isPhoneRevealed =
        currentPhone != null && currentPhone!.trim().isNotEmpty;
    final activeFavColor =
        isDark ? const Color(0xFFFF6B6B) : AmazonColors.dealRed;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    if (isOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(
              'Izmeni oglas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          if (!ad.isSold && onMarkAsSold != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onMarkAsSold,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Označi kao prodato',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          if (onShare != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onShare,
              icon: Icon(Icons.adaptive.share, size: 16),
              label: const Text(
                'Podeli oglas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            AppHaptics.light();
            onChatTap?.call();
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text(
            'Pošalji poruku',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 9),
        if (hasPhone) ...[
          OutlinedButton.icon(
            onPressed: isLoadingPhone
                ? null
                : () {
                    AppHaptics.light();
                    if (isPhoneRevealed) {
                      onPhoneTap?.call();
                    } else {
                      onPhoneReveal?.call();
                    }
                  },
            icon: isLoadingPhone
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isPhoneRevealed
                        ? Icons.phone_in_talk_rounded
                        : Icons.phone_outlined,
                    size: 18,
                  ),
            label: Text(
              isLoadingPhone
                  ? 'Učitavanje broja...'
                  : (isPhoneRevealed ? currentPhone! : 'Prikaži broj telefona'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isPhoneRevealed ? 14.5 : 13.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
              side: BorderSide(
                color: isPhoneRevealed ? colorScheme.primary : borderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 9),
        ],
        Row(
          children: [
            if (onToggleFavorite != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isTogglingFavorite ? null : onToggleFavorite,
                  icon: isTogglingFavorite
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isFavorited
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 17,
                          color: isFavorited ? activeFavColor : null,
                        ),
                  label: Text(
                    isFavorited ? 'Sačuvano' : 'Sačuvaj',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFavorited ? activeFavColor : null,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: isFavorited
                          ? activeFavColor.withValues(alpha: 0.5)
                          : borderColor,
                    ),
                    backgroundColor: isFavorited
                        ? activeFavColor.withValues(alpha: isDark ? 0.14 : 0.07)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            if (onToggleFavorite != null && onShare != null)
              const SizedBox(width: 8),
            if (onShare != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    onShare!();
                  },
                  icon: Icon(Icons.adaptive.share, size: 16),
                  label: const Text(
                    'Podeli',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactShareButton() {
    return Tooltip(
      message: 'Podeli oglas',
      child: OutlinedButton.icon(
        onPressed: onShare,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.adaptive.share, size: 15),
        label: const Text(
          'Podeli',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMobileSaveChip(Color secondaryText) {
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isTogglingFavorite)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 17,
                  color: isFavorited ? activeColor : secondaryText,
                ),
              const SizedBox(width: 4),
              Text(
                isFavorited ? 'Sačuvano' : 'Sačuvaj',
                style: TextStyle(
                  fontSize: 12,
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

  Widget _buildOverflowMenu(Color iconColor) {
    return PopupMenuButton<String>(
      tooltip: 'Više opcija',
      icon: Icon(Icons.more_vert_rounded, size: 19, color: iconColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 160),
      onSelected: (value) {
        AppHaptics.light();
        if (value == 'report') {
          onReport?.call();
        } else if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'sold') {
          onMarkAsSold?.call();
        }
      },
      itemBuilder: (_) {
        if (isOwner) {
          return [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 17),
                  SizedBox(width: 8),
                  Text('Izmeni oglas'),
                ],
              ),
            ),
            if (!ad.isSold && onMarkAsSold != null)
              const PopupMenuItem(
                value: 'sold',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 17),
                    SizedBox(width: 8),
                    Text('Označi kao prodato'),
                  ],
                ),
              ),
          ];
        }
        return const [
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 17),
                SizedBox(width: 8),
                Text('Prijavi oglas'),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _statChip(
    IconData icon,
    String text,
    Color color, {
    required String tooltip,
    bool bold = false,
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
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
