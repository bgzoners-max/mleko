import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../add_buyer_review_dialog.dart';
import 'seller_order_review_button.dart';

/// Akcije nad porudžbinom prema statusu (Prihvati/Odbij, Poslato/Otkaži...).
class SellerOrderActions extends StatelessWidget {
  final OrderModel order;
  final String buyerName;
  final String sellerId;
  final bool isArchivedList;
  final ValueChanged<OrderStatus> onUpdateStatus;
  final VoidCallback onCancel;
  final VoidCallback onArchive;
  final VoidCallback onRefresh;

  const SellerOrderActions({
    super.key,
    required this.order,
    required this.buyerName,
    required this.sellerId,
    required this.isArchivedList,
    required this.onUpdateStatus,
    required this.onCancel,
    required this.onArchive,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Column(
      children: [
        if (o.status == OrderStatus.sent) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => onUpdateStatus(OrderStatus.accepted),
                  child: const Text('Prihvati'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Odbij porudžbinu?'),
                        content: const Text(
                            'Kupac će biti obavešten da ste odbili porudžbinu.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Odustani'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Odbij'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      onUpdateStatus(OrderStatus.rejected);
                    }
                  },
                  child: const Text('Odbij'),
                ),
              ),
            ],
          ),
        ] else if (o.status == OrderStatus.accepted) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => onUpdateStatus(OrderStatus.shipped),
                  child: const Text('Poslato'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Otkaži'),
                ),
              ),
            ],
          ),
        ] else if (o.status == OrderStatus.shipped) ...[
          Row(
            children: [
              const Expanded(
                child: Chip(
                  label: Text('Čeka potvrdu kupca'),
                  avatar: Icon(Icons.schedule, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Otkaži'),
                ),
              ),
            ],
          ),
        ] else if (o.status == OrderStatus.delivered) ...[
          CanSellerReviewBuyerButton(
            key: ValueKey('canreviewbuyer-${o.id}'),
            sellerId: sellerId,
            order: o,
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AddBuyerReviewDialog(
                sellerId: sellerId,
                buyerId: o.buyerId,
                orderId: o.id,
                buyerName: buyerName,
                onSubmitted: onRefresh,
              ),
            ),
          ),
        ],
        if (!isArchivedList && o.canSellerManuallyArchive) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Arhiviraj'),
            ),
          ),
        ],
      ],
    );
  }
}
