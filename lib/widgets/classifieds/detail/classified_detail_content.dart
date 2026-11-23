import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart';
import '../../../core/haptic.dart';
import '../../../models/classified_ad_model.dart';
import '../../../models/user_model.dart';
import '../../app_back_button.dart';
import '../../app_footer.dart';
import '../../navigation/desktop_header.dart';
import '../report_classified_ad_dialog.dart';
import 'classified_description_card.dart';
import 'classified_image_gallery.dart';
import 'classified_main_info_card.dart';
import 'classified_more_from_seller_strip.dart';
import 'classified_quick_utility_bar.dart';
import 'classified_report_button.dart';
import 'classified_safety_tips_card.dart';
import 'classified_seller_sidebar.dart';
import 'classified_specifications_table.dart';

class ClassifiedDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ClassifiedDetailAppBar({
    super.key,
    required this.title,
    required this.isDark,
    this.ad,
    this.isOwner = false,
    this.onShare,
  });

  final String title;
  final bool isDark;
  final ClassifiedAdModel? ad;
  final bool isOwner;
  final VoidCallback? onShare;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;
    return AppBar(
      leading: const AppBackButton(fallbackRoute: '/classifieds'),
      backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
      foregroundColor: textColor,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      iconTheme: IconThemeData(color: textColor),
      actions: [
        if (ad != null) ...[
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Podeli oglas',
            onPressed: () {
              AppHaptics.light();
              onShare?.call();
            },
          ),
          if (!isOwner)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Prijavi oglas',
              onPressed: () {
                AppHaptics.light();
                ReportClassifiedAdDialog.show(context, ad: ad!);
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Izmeni oglas',
              onPressed: () => context.push('/classifieds/edit/${ad!.id}'),
            ),
        ],
        const AppHomeButton(),
      ],
    );
  }
}

class ClassifiedPhoneActionSheet {
  static void show(
    BuildContext context, {
    required String phone,
    required VoidCallback onCall,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Kontakt prodavca',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  phone,
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: phone));
                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Broj telefona je kopiran.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Kopiraj'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onCall();
                        },
                        icon: const Icon(Icons.phone_rounded, size: 18),
                        label: const Text('Pozovi'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Originalan Domaći Market 2-kolonski raspored detalja malog oglasa:
/// - Gore: kompaktna utility traka (`Breadcrumbs` + brze prečice i kurs evra na desktopu)
/// - Desktop (`>= 960 px`): 60% levo (kompaktna galerija sa thumbnail-ima ispod + specifikacije +
///   opis + još oglasa od prodavca) | 40% desno (kartica cene i akcija + kartica oglašivača sa
///   pravnom napomenom + bezbednosni saveti) — sve bitno odmah vidljivo iznad "fold"-a!
/// - Mobilni (`< 960 px`): čist jednostubni tok sa donjom fiksnom trakom za kontakt.
class ClassifiedDetailContent extends StatelessWidget {
  const ClassifiedDetailContent({
    super.key,
    required this.ad,
    required this.isDesktop,
    required this.isWide,
    required this.isOwner,
    required this.hasPhone,
    required this.isLoadingPhone,
    required this.currentPhone,
    required this.onImageTap,
    required this.onEdit,
    required this.onMarkAsSold,
    required this.onPhoneReveal,
    required this.onPhoneTap,
    required this.onChatTap,
    this.onShare,
    this.sellerProfile,
    this.sellerAvgRating = 0,
    this.sellerReviewCount = 0,
    this.sellerOtherAds = const [],
    this.sellerActiveAdsCount = 0,
    this.isFollowingSeller = false,
    this.isTogglingFollow = false,
    this.isFavorited = false,
    this.isTogglingFavorite = false,
    this.favoritesCount,
    this.onToggleFavorite,
    this.onToggleFollowSeller,
    this.onViewAllSellerAds,
  });

  final ClassifiedAdModel ad;
  final bool isDesktop;
  final bool isWide;
  final bool isOwner;
  final bool hasPhone;
  final bool isLoadingPhone;
  final String? currentPhone;
  final void Function(List<String> images, int initialIndex) onImageTap;
  final VoidCallback onEdit;
  final VoidCallback onMarkAsSold;
  final VoidCallback onPhoneReveal;
  final VoidCallback onPhoneTap;
  final VoidCallback onChatTap;
  final VoidCallback? onShare;

  final UserModel? sellerProfile;
  final double sellerAvgRating;
  final int sellerReviewCount;
  final List<ClassifiedAdModel> sellerOtherAds;
  final int sellerActiveAdsCount;
  final bool isFollowingSeller;
  final bool isTogglingFollow;
  final bool isFavorited;
  final bool isTogglingFavorite;
  final int? favoritesCount;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleFollowSeller;
  final VoidCallback? onViewAllSellerAds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useTwoColumns = isWide || screenWidth >= 960;
    final sellerDisplayName = ad.sellerName ??
        sellerProfile?.farmName ??
        sellerProfile?.displayName ??
        'Oglašivač';

    return Column(
      children: [
        if (isDesktop) const DesktopHeader(isStandalone: true),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: useTwoColumns ? 24 : 14,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: useTwoColumns ? 1180 : 820,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClassifiedQuickUtilityBar(
                      ad: ad,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      showShortcuts: useTwoColumns,
                    ),
                    const SizedBox(height: 14),
                    if (useTwoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leva kolona (60%): Kompaktna galerija + detalji + opis + ostali oglasi
                          Expanded(
                            flex: 60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClassifiedImageGallery(
                                  ad: ad,
                                  colorScheme: colorScheme,
                                  isDesktop: true,
                                  onImageTap: onImageTap,
                                ),
                                const SizedBox(height: 16),
                                ClassifiedSpecificationsTable(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 16),
                                ClassifiedDescriptionCard(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                                if (sellerOtherAds.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  ClassifiedMoreFromSellerStrip(
                                    sellerName: sellerDisplayName,
                                    otherAds: sellerOtherAds,
                                    isDark: isDark,
                                    onViewAll: onViewAllSellerAds ?? () {},
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Desna kolona (40%): Cena i akcije + profil oglašivača + bezbednost
                          Expanded(
                            flex: 40,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClassifiedMainInfoCard(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                  isOwner: isOwner,
                                  hasPhone: hasPhone,
                                  isWide: true,
                                  onShare: onShare,
                                  isFavorited: isFavorited,
                                  isTogglingFavorite: isTogglingFavorite,
                                  favoritesCount: favoritesCount,
                                  onToggleFavorite: onToggleFavorite,
                                  isLoadingPhone: isLoadingPhone,
                                  currentPhone: currentPhone,
                                  onChatTap: onChatTap,
                                  onPhoneReveal: onPhoneReveal,
                                  onPhoneTap: onPhoneTap,
                                  onEdit: onEdit,
                                  onMarkAsSold: onMarkAsSold,
                                  onReport: () =>
                                      ReportClassifiedAdDialog.show(
                                    context,
                                    ad: ad,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSellerCard(isDark: isDark),
                                const SizedBox(height: 14),
                                ClassifiedSafetyTipsCard(
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      _buildMobileSingleColumn(
                        context,
                        theme: theme,
                        colorScheme: colorScheme,
                        isDark: isDark,
                        sellerDisplayName: sellerDisplayName,
                      ),
                    const SizedBox(height: 20),
                    const AppFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSingleColumn(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isDark,
    required String sellerDisplayName,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClassifiedImageGallery(
          ad: ad,
          colorScheme: colorScheme,
          isDesktop: false,
          onImageTap: onImageTap,
        ),
        const SizedBox(height: 14),
        ClassifiedMainInfoCard(
          ad: ad,
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
          isOwner: isOwner,
          hasPhone: hasPhone,
          isWide: false,
          onShare: onShare,
          isFavorited: isFavorited,
          isTogglingFavorite: isTogglingFavorite,
          favoritesCount: favoritesCount,
          onToggleFavorite: onToggleFavorite,
        ),
        const SizedBox(height: 14),
        ClassifiedSpecificationsTable(
          ad: ad,
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        ClassifiedDescriptionCard(
          ad: ad,
          theme: theme,
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        _buildSellerCard(isDark: isDark),
        if (sellerOtherAds.isNotEmpty) ...[
          const SizedBox(height: 14),
          ClassifiedMoreFromSellerStrip(
            sellerName: sellerDisplayName,
            otherAds: sellerOtherAds,
            isDark: isDark,
            onViewAll: onViewAllSellerAds ?? () {},
          ),
        ],
        const SizedBox(height: 14),
        ClassifiedSafetyTipsCard(
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        ClassifiedReportButton(
          ad: ad,
          isOwner: isOwner,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSellerCard({required bool isDark}) {
    return ClassifiedSellerSidebar(
      ad: ad,
      isDark: isDark,
      isOwner: isOwner,
      sellerProfile: sellerProfile,
      sellerAvgRating: sellerAvgRating,
      sellerReviewCount: sellerReviewCount,
      sellerActiveAdsCount: sellerActiveAdsCount,
      isFollowingSeller: isFollowingSeller,
      isTogglingFollow: isTogglingFollow,
      onToggleFollowSeller: onToggleFollowSeller,
      onViewAllSellerAds: onViewAllSellerAds,
    );
  }
}
