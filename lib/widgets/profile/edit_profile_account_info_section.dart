import 'package:flutter/material.dart';

/// Sekcija „Informacije o nalogu" — email (zaključan, primarni identifikator)
/// i opcioni zahtev za reset lozinke.
///
/// Izdvojena iz EditProfileForm radi održavanja fajla ispod limita od
/// 700 linija (tool/check_file_size.dart).
class EditProfileAccountInfoSection extends StatelessWidget {
  final String? email;
  final bool sendingPasswordReset;
  final VoidCallback? onSendPasswordReset;

  const EditProfileAccountInfoSection({
    super.key,
    required this.email,
    required this.sendingPasswordReset,
    required this.onSendPasswordReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined,
                  size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Email: ${email ?? 'Nije unet'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Tooltip(
                message: 'Email je primarni identifikator naloga',
                child: Icon(Icons.lock_outline,
                    size: 16, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Želite da promenite lozinku?',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      sendingPasswordReset ? null : onSendPasswordReset,
                  icon: sendingPasswordReset
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : const Icon(Icons.key_outlined, size: 16),
                  label: const Text('Resetuj lozinku',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
