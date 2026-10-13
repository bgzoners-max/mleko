import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design_system.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';

/// Prikazuje elegantan prozor ili bottom sheet za deljenje oglasa ili proizvoda
/// sa brzim opcijama za Viber, WhatsApp, kopiranje linka i sistemsko deljenje.
Future<void> showAppShareSheet(
  BuildContext context, {
  required String title,
  required String url,
  required String shareText,
  String? subject,
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
    ),
  );
}

class _ShareDialog extends StatelessWidget {
  final String title;
  final String url;
  final String shareText;
  final String? subject;

  const _ShareDialog({
    required this.title,
    required this.url,
    required this.shareText,
    this.subject,
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
                      'Podeli ponudu',
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

  const _ShareSheet({
    required this.title,
    required this.url,
    required this.shareText,
    this.subject,
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
              'Podeli ponudu',
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ShareButton(
              icon: Icons.link_rounded,
              label: 'Kopiraj link',
              color: AmazonColors.link,
              onTap: () => _copyLink(context),
            ),
            _ShareButton(
              icon: Icons.phone_in_talk_rounded,
              label: 'Viber',
              color: const Color(0xFF7360F2),
              onTap: () => _shareViber(context),
            ),
            _ShareButton(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _shareWhatsApp(context),
            ),
            _ShareButton(
              icon: Icons.more_horiz_rounded,
              label: 'Više opcija',
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              onTap: () => _shareSystem(context),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
