import 'package:flutter/material.dart';
import '../../../core/design_system.dart';
import '../../../models/classified_ad_model.dart';
import '../../../core/haptic.dart';

class ClassifiedActionButtons extends StatelessWidget {
  final ClassifiedAdModel ad;
  final bool isOwner;
  final bool hasPhone;
  final ColorScheme colorScheme;
  final bool isDark;
  
  final bool isLoadingPhone;
  final String? currentPhone;
  final bool isPhoneRevealed;
  
  final VoidCallback onEdit;
  final VoidCallback onMarkAsSold;
  final VoidCallback onPhoneReveal;
  final VoidCallback onPhoneTap;
  final VoidCallback onChatTap;

  const ClassifiedActionButtons({
    super.key,
    required this.ad,
    required this.isOwner,
    required this.hasPhone,
    required this.colorScheme,
    required this.isDark,
    required this.isLoadingPhone,
    required this.currentPhone,
    required this.isPhoneRevealed,
    required this.onEdit,
    required this.onMarkAsSold,
    required this.onPhoneReveal,
    required this.onPhoneTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Izmeni oglas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: ad.isSold ? null : onMarkAsSold,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(ad.isSold ? 'Već prodat' : 'Označi prodato'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!isOwner && !ad.isAvailable) {
      final message = ad.isSold
          ? 'Ovaj oglas je označen kao prodat.'
          : ad.isRejected
              ? 'Ovaj oglas je uklonjen nakon moderacije.'
              : 'Ovaj oglas više nije aktivan.';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 20, color: colorScheme.error),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        if (hasPhone) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isLoadingPhone
                  ? null
                  : () {
                      AppHaptics.medium();
                      if (isPhoneRevealed) {
                        onPhoneTap();
                      } else {
                        onPhoneReveal();
                      }
                    },
              icon: isLoadingPhone
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPhoneRevealed ? Icons.phone_in_talk_rounded : Icons.phone_outlined,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
              label: Text(
                isLoadingPhone
                    ? 'Učitavanje...'
                    : (isPhoneRevealed ? (currentPhone ?? '') : 'Prikaži broj'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
                side: BorderSide(
                  color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: hasPhone ? 1 : 2,
          child: ElevatedButton.icon(
            onPressed: () {
              AppHaptics.medium();
              onChatTap();
            },
            icon: const Icon(Icons.chat_bubble_outline, color: AmazonColors.darkNavy, size: 18),
            label: const Text(
              'Pošalji poruku',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AmazonColors.darkNavy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AmazonColors.amberLight,
              foregroundColor: AmazonColors.darkNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AmazonColors.amberDark, width: 0.9),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
