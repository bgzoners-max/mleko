import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design_system.dart';
import '../core/haptic.dart';
import '../core/profile_display_names.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

/// Vraća javni bazni URL za deljenje linkova (bez završne kose crte).
String resolvePublicShareBaseUrl() {
  final rawBase = SupabaseConfig.shareBaseUrl.isNotEmpty
      ? SupabaseConfig.shareBaseUrl
      : (kIsWeb
          ? (Uri.base.origin == 'https://domacimarket.rs'
              ? 'https://www.domacimarket.rs'
              : Uri.base.origin)
          : 'https://www.domacimarket.rs');
  return rawBase.replaceAll(RegExp(r'/+$'), '');
}

/// Otvara dijalog/sheet za deljenje konkretnog proizvoda (`/p/:id`).
Future<void> shareProduct(BuildContext context, ProductModel product) async {
  final base = resolvePublicShareBaseUrl();
  final url = '$base/p/${product.id}';
  final text =
      'Pogledaj ${product.name} – ${product.priceFormatted} na Domaćem marketu:';

  await showAppShareSheet(
    context,
    title: product.name,
    url: url,
    shareText: text,
    subject: product.name,
    sheetTitle: 'Podeli proizvod',
  );
}

/// Otvara dijalog/sheet za deljenje profila prodavca / gazdinstva (`/seller/:id`).
Future<void> shareSellerProfile(BuildContext context, UserModel seller) async {
  final base = resolvePublicShareBaseUrl();
  final url = '$base/seller/${seller.id}';
  final displayName = resolveProfileDisplayName(
    seller.farmName,
    seller.displayName,
  );
  final place = seller.city?.trim().isNotEmpty == true
      ? seller.city!.trim()
      : (seller.location?.trim() ?? '');
  final locationSuffix = place.isNotEmpty ? ' ($place)' : '';
  final text =
      'Pogledaj gazdinstvo $displayName$locationSuffix na Domaćem marketu:';

  await showAppShareSheet(
    context,
    title: displayName,
    url: url,
    shareText: text,
    subject: '$displayName – Domaći Market',
    sheetTitle: 'Podeli profil',
  );
}

/// Prikazuje elegantan prozor ili bottom sheet za deljenje oglasa, proizvoda
/// ili profila gazdinstva sa brzim opcijama za Viber, WhatsApp, kopiranje linka
/// i sistemsko deljenje.
Future<void> showAppShareSheet(
  BuildContext context, {
  required String title,
  required String url,
  required String shareText,
  String? subject,
  String sheetTitle = 'Podeli ponudu',
}) {
  final isDesktop = Breakpoints.isDesktop(context);

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _ShareDialog(
        title: title,
        url: url,
        shareText: shareText,
        subject: subject,
        sheetTitle: sheetTitle,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusL)),
    ),
    builder: (ctx) => _ShareSheet(
      title: title,
      url: url,
      shareText: shareText,
      subject: subject,
      sheetTitle: sheetTitle,
    ),
  );
}

class _ShareDialog extends StatelessWidget {
  final String title;
  final String url;
  final String shareText;
  final String? subject;
  final String sheetTitle;

  const _ShareDialog({
    required this.title,
    required this.url,
    required this.shareText,
    this.subject,
    required this.sheetTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusL),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.share_outlined, color: colorScheme.primary, size: 24),
                  const SizedBox(width: AppDesign.spaceM),
                  Expanded(
                    child: Text(
                      sheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spaceS),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppDesign.spaceS),
              _ShareUrlPill(url: url, isDark: isDark),
              const SizedBox(height: AppDesign.spaceL),
              _ShareOptionsGrid(
                url: url,
                shareText: shareText,
                subject: subject,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareSheet extends StatelessWidget {
  final String title;
  final String url;
  final String shareText;
  final String? subject;
  final String sheetTitle;

  const _ShareSheet({
    required this.title,
    required this.url,
    required this.shareText,
    this.subject,
    required this.sheetTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.spaceL,
          0,
          AppDesign.spaceL,
          AppDesign.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sheetTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.spaceS),
            _ShareUrlPill(url: url, isDark: isDark),
            const SizedBox(height: AppDesign.spaceL),
            _ShareOptionsGrid(
              url: url,
              shareText: shareText,
              subject: subject,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareUrlPill extends StatelessWidget {
  final String url;
  final bool isDark;

  const _ShareUrlPill({required this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2620) : const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderSubtle,
        ),
      ),
      child: SelectableText(
        url,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AmazonColors.darkTextSecondary
              : AmazonColors.textSecondary,
        ),
      ),
    );
  }
}

class _ShareOptionsGrid extends StatelessWidget {
  final String url;
  final String shareText;
  final String? subject;
  final bool isDark;

  const _ShareOptionsGrid({
    required this.url,
    required this.shareText,
    this.subject,
    required this.isDark,
  });

  Future<void> _copyLink(BuildContext context) async {
    unawaited(AppHaptics.medium());
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Link je kopiran u privremenu memoriju!'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareViber(BuildContext context) async {
    unawaited(AppHaptics.light());
    final fullText = '$shareText\n$url';
    final viberUri = Uri.parse('viber://forward?text=${Uri.encodeComponent(fullText)}');
    if (await canLaunchUrl(viberUri)) {
      await launchUrl(viberUri, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.of(context).pop();
    } else {
      // Fallback na SharePlus
      if (context.mounted) {
        Navigator.of(context).pop();
        await SharePlus.instance.share(ShareParams(text: fullText, subject: subject));
      }
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    unawaited(AppHaptics.light());
    final fullText = '$shareText\n$url';
    final waUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(fullText)}');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.of(context).pop();
    } else {
      if (context.mounted) {
        Navigator.of(context).pop();
        await SharePlus.instance.share(ShareParams(text: fullText, subject: subject));
      }
    }
  }

  Future<void> _shareSystem(BuildContext context) async {
    unawaited(AppHaptics.light());
    final fullText = '$shareText\n$url';
    if (context.mounted) Navigator.of(context).pop();
    await SharePlus.instance.share(ShareParams(text: fullText, subject: subject));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ShareButton(
                icon: Icons.link_rounded,
                label: 'Kopiraj link',
                color: AmazonColors.link,
                onTap: () => _copyLink(context),
              ),
            ),
            Expanded(
              child: _ShareButton(
                icon: Icons.phone_in_talk_rounded,
                label: 'Viber',
                color: const Color(0xFF7360F2),
                onTap: () => _shareViber(context),
              ),
            ),
            Expanded(
              child: _ShareButton(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareWhatsApp(context),
              ),
            ),
            Expanded(
              child: _ShareButton(
                icon: Icons.more_horiz_rounded,
                label: 'Više opcija',
                color: isDark
                    ? AmazonColors.darkTextPrimary
                    : AmazonColors.textPrimary,
                onTap: () => _shareSystem(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
