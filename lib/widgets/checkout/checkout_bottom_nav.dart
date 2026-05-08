import 'package:flutter/material.dart';

class CheckoutBottomNav extends StatelessWidget {
  final bool isEmpty;
  final String totalRsd;
  final bool canSubmit;
  final bool sending;
  final bool hasUnavailableItems;
  final VoidCallback onSubmit;

  const CheckoutBottomNav({
    super.key,
    required this.isEmpty,
    required this.totalRsd,
    required this.canSubmit,
    required this.sending,
    required this.hasUnavailableItems,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ukupno:',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '$totalRsd RSD',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(hasUnavailableItems
                      ? 'Nedostupno'
                      : 'Pošalji porudžbinu'),
            ),
          ],
        ),
      ),
    );
  }
}
