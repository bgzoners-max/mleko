import 'package:flutter/material.dart';

/// Sekcija „Informacije o nalogu" — email (zaključan, primarni identifikator)
/// i opcioni zahtev za reset lozinke u kompaktnoj traci.
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 460;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email: ${email ?? 'Nije unet'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Tooltip(
                      message: 'Email je primarni identifikator naloga',
                      child: Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed:
                          sendingPasswordReset ? null : onSendPasswordReset,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      icon: sendingPasswordReset
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.key_outlined, size: 14),
                      label: const Text('Resetuj lozinku',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ],
            );
          }

          return Row(
            children: [
              Icon(Icons.email_outlined,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Email: ${email ?? 'Nije unet'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Email je primarni identifikator naloga',
                      child: Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (email != null && email!.isNotEmpty)
                TextButton.icon(
                  onPressed: sendingPasswordReset ? null : onSendPasswordReset,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                  icon: sendingPasswordReset
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.key_outlined, size: 15),
                  label: const Text('Resetuj lozinku',
                      style: TextStyle(fontSize: 12)),
                ),
            ],
          );
        },
      ),
    );
  }
}
