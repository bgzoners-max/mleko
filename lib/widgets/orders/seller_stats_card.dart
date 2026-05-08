import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:mleko/services/services.dart';

class SellerStatsCard extends StatelessWidget {
  final BuyerSellerStats stats;
  final VoidCallback onReorder;

  const SellerStatsCard({super.key, required this.stats, required this.onReorder});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('sr');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(Icons.store, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/seller/${stats.sellerId}'),
                    child: Text(
                      stats.sellerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  '${stats.orderCount} ${stats.orderCount == 1 ? 'porudžbina' : (stats.orderCount >= 2 && stats.orderCount <= 4 ? 'porudžbine' : 'porudžbina')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.payments_outlined,
                    size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Prosečan račun: ${fmt.format(stats.averageOrder.round())} RSD',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onReorder,
              icon: const Icon(Icons.replay, size: 20),
              label: const Text('Ponovi porudžbinu'),
            ),
          ],
        ),
      ),
    );
  }
}
