import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

class ChatOrderContextCard extends StatelessWidget {
  final OrderModel order;

  const ChatOrderContextCard({super.key, required this.order});

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => context.go('/orders'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.shopping_bag,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      order.productName ??
                          (order.hasMultipleItems
                              ? 'Više proizvoda'
                              : 'Porudžbina'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                      order.hasMultipleItems
                          ? order.statusLabel
                          : '${ProductModel.formatQuantityWithUnit(order.quantityKg ?? 0, order.unitType ?? ProductModel.unitKg)} · ${order.statusLabel}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(BuildContext context) {
    if (order.status != OrderStatus.sent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleAction(context, OrderStatus.rejected),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Odbij'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _handleAction(context, OrderStatus.accepted),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Prihvati'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, OrderStatus status) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == OrderStatus.accepted
            ? 'Prihvati porudžbinu?'
            : 'Odbij porudžbinu?'),
        content: Text(status == OrderStatus.accepted
            ? 'Da li ste sigurni da želite da prihvatite ovu porudžbinu?'
            : 'Da li ste sigurni da želite da odbijete ovu porudžbinu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: status == OrderStatus.accepted
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
            child: Text(status == OrderStatus.accepted ? 'Prihvati' : 'Odbij'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await context.read<OrdersService>().updateOrderStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == OrderStatus.accepted
                ? 'Porudžbina prihvaćena.'
                : 'Porudžbina odbijena.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isSeller = user?.id == order.sellerId;

    return Column(
      children: [
        _buildCard(context),
        if (isSeller) _buildOrderActions(context),
      ],
    );
  }
}
