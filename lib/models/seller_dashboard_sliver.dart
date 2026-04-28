import 'package:flutter/material.dart';
import '../services/services.dart';

/// Dashboard za prodavca na Home ekranu
class SellerDashboardSliver extends StatelessWidget {
  final Future<SellerStats>? statsFuture;

  const SellerDashboardSliver({super.key, this.statsFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<SellerStats>(
          future: statsFuture,
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            if (stats == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SellerStatItem(
                        label: 'Na čekanju',
                        value: '${stats.pendingCount}',
                        icon: Icons.pending_actions),
                    _SellerStatItem(
                        label: 'Ukupno',
                        value: '${stats.totalCount}',
                        icon: Icons.assignment_turned_in_outlined),
                    _SellerStatItem(
                        label: 'Prihod',
                        value: '${stats.revenue.toStringAsFixed(0)} RSD',
                        icon: Icons.account_balance_wallet_outlined),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SellerStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SellerStatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}
