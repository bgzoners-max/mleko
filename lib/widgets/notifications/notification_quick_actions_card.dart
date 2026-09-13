import 'package:flutter/material.dart';

import '../../core/responsive.dart';

class NotificationQuickActionsCard extends StatelessWidget {
  final int totalCount;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllAsRead;

  const NotificationQuickActionsCard({
    super.key,
    required this.totalCount,
    required this.onRefresh,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Breakpoints.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Brze radnje',
              style: Breakpoints.sectionTitleStyle(
                context,
                Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ukupno obaveštenja: $totalCount',
              style: Breakpoints.supportingTextStyle(
                context,
                Theme.of(context).textTheme.bodyMedium,
                phone: 13,
                largeTabletValue: 14,
                desktop: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Osveži'),
                ),
                OutlinedButton.icon(
                  onPressed: onMarkAllAsRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Pročitaj sve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
