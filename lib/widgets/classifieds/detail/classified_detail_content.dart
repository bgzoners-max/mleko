import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system.dart';
import '../../../core/haptic.dart';
import '../../../core/responsive.dart';
import '../../../models/classified_ad_model.dart';
import '../../app_back_button.dart';
import '../../app_footer.dart';
import '../../navigation/desktop_header.dart';
import '../report_classified_ad_dialog.dart';
import 'classified_action_buttons.dart';
import 'classified_breadcrumbs.dart';
import 'classified_description_card.dart';
import 'classified_image_gallery.dart';
import 'classified_main_info_card.dart';
import 'classified_report_button.dart';
import 'classified_safety_tips_card.dart';
import 'classified_seller_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPhoneRevealed =
        currentPhone != null && currentPhone!.trim().isNotEmpty;

    return Column(
      children: [
        if (isDesktop) const DesktopHeader(isStandalone: true),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      isWide ? Breakpoints.dataContentWidth(context) : 1200,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClassifiedBreadcrumbs(ad: ad, colorScheme: colorScheme),
                    const SizedBox(height: 12),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClassifiedImageGallery(
                                  ad: ad,
                                  colorScheme: colorScheme,
                                  isDesktop: true,
                                  onImageTap: onImageTap,
                                ),
                                const SizedBox(height: 24),
                                ClassifiedSafetyTipsCard(
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 12),
                                ClassifiedReportButton(
                                  ad: ad,
                                  isOwner: isOwner,
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 45,
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
                                  actionButtons: ClassifiedActionButtons(
                                    ad: ad,
                                    isOwner: isOwner,
                                    hasPhone: hasPhone,
                                    colorScheme: colorScheme,
                                    isDark: isDark,
                                    isLoadingPhone: isLoadingPhone,
                                    currentPhone: currentPhone,
                                    isPhoneRevealed: isPhoneRevealed,
                                    onEdit: onEdit,
                                    onMarkAsSold: onMarkAsSold,
                                    onPhoneReveal: onPhoneReveal,
                                    onPhoneTap: onPhoneTap,
                                    onChatTap: onChatTap,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ClassifiedSpecificationsTable(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 20),
                                ClassifiedDescriptionCard(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 20),
                                ClassifiedSellerCard(
                                  ad: ad,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClassifiedImageGallery(
                            ad: ad,
                            colorScheme: colorScheme,
                            isDesktop: false,
                            onImageTap: onImageTap,
                          ),
                          const SizedBox(height: 16),
                          ClassifiedMainInfoCard(
                            ad: ad,
                            theme: theme,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            isOwner: isOwner,
                            hasPhone: hasPhone,
                            isWide: false,
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
                          const SizedBox(height: 16),
                          ClassifiedSellerCard(
                            ad: ad,
                            theme: theme,
                            colorScheme: colorScheme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          ClassifiedSafetyTipsCard(
                            colorScheme: colorScheme,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          ClassifiedReportButton(
                            ad: ad,
                            isOwner: isOwner,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    const SizedBox(height: 16),
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
}
