import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/design_system.dart';

/// Prikazuje moderan dijalog sa opcijama za kontakt:
/// 1. Slanje tiketa podršci kroz aplikaciju (/support)
/// 2. Kopiranje email adrese uz vizuelnu potvrdu
/// 3. Otvaranje podrazumevane email aplikacije
Future<void> showContactOptionsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const ContactOptionsDialog(),
  );
}

class ContactOptionsDialog extends StatelessWidget {
  const ContactOptionsDialog({super.key});

  static const String contactEmail = 'kontakt@domacimarket.rs';

  static void copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: contactEmail));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Email adresa $contactEmail je kopirana!')),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A27) : const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, color: AmazonColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Kontakt & Podrška',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imate pitanje ili vam je potrebna pomoć? Javite nam se na način koji vam najviše odgovara:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            // Opcija 1: Forma / Tiket podrške
            Material(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF6F8F6),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/support');
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AmazonColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.rate_review_outlined, color: AmazonColors.green, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pošalji poruku kroz aplikaciju',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Direktno administratorima platforme',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Opcija 2: Email sa ikonicom za kopiranje i otvaranje
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, size: 20, color: AmazonColors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email adresa:',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey),
                        ),
                        SelectableText(
                          contactEmail,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: 'Kopiraj email adresu',
                    child: IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 19),
                      onPressed: () => copyEmail(context),
                    ),
                  ),
                  Tooltip(
                    message: 'Otvori u email aplikaciji',
                    child: IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 19),
                      onPressed: () => launchUrl(Uri.parse('mailto:$contactEmail')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }
}
