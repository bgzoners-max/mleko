import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/utils/action_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../models/order_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../models/user_model.dart';
import '../../services/communication/communication_services.dart';
import '../../services/orders/order_services.dart';
import '../../widgets/cancel_order_dialog.dart';
import 'seller_order_delivery_rows.dart';
import '../../widgets/order_status_audit_log_section.dart';
import '../../widgets/order_status_timeline.dart';
import 'seller_order_actions.dart';
import 'seller_order_details.dart';

/// Kartica jedne porudžbine u listi prodavca (izdvojeno iz ekrana).
class SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  final UserModel user;
  final bool isArchivedList;
  final VoidCallback onRefresh;

  const SellerOrderCard({
    super.key,
    required this.order,
    required this.user,
    required this.isArchivedList,
    required this.onRefresh,
  });

  Future<void> _updateStatus(
      BuildContext context, String orderId, OrderStatus status) async {
    await context.read<OrdersService>().updateOrderStatus(orderId, status);
    onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: ${status.dbValue}.')),
      );
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final ordersService = context.read<OrdersService>();
    final reason = await CancelOrderDialog.show(context);
    if (reason == null || !context.mounted) return;
    await ordersService.cancelOrderBySeller(orderId, reason);
    onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Porudžbina je otkazana.')));
    }
  }

  Future<void> _archiveOrder(BuildContext context) async {
    final ordersService = context.read<OrdersService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arhiviraj porudžbinu?'),
        content: const Text(
          'Arhivirana porudžbina više neće biti u listi aktivnih porudžbina.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Arhiviraj'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ordersService.archiveOrderBySeller(user.id, order.id);
    onRefresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Porudžbina je arhivirana.')),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final o = order;
    try {
      final convId = await context
          .read<ChatService>()
          .getOrCreateConversation(
            o.buyerId,
            user.id,
            orderId: o.id,
            productId: o.productId,
          );
      if (context.mounted) {
        unawaited(context.push('/chat/$convId'));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _statusHint(OrderStatus status) {
    return switch (status) {
      OrderStatus.sent =>
        'Porudžbina je poslata – na vama je da je prihvatite ili odbijete.',
      OrderStatus.accepted =>
        'Prihvatili ste porudžbinu – pošaljite je kupcu kada bude spremna.',
      OrderStatus.shipped =>
        'Označili ste porudžbinu kao poslatu – čeka se potvrda kupca.',
      OrderStatus.delivered =>
        'Kupac je potvrdio prijem – možete ostaviti recenziju kupca.',
      OrderStatus.rejected => 'Odbili ste ovu porudžbinu.',
      OrderStatus.cancelledBySeller => 'Otkazali ste ovu porudžbinu.',
      OrderStatus.archived => 'Porudžbina je u arhivi.',
    };
  }

  String _cardHint(OrderStatus status) {
    return switch (status) {
      OrderStatus.sent =>
        'Ovo je nova porudžbina. Prihvatite je ili je odbijte.',
      OrderStatus.accepted =>
        'Porudžbina je potvrđena. Kada bude spremna, označite je kao poslatu.',
      OrderStatus.shipped =>
        'Porudžbina je na putu. Kupac će je potvrditi po prijemu.',
      OrderStatus.delivered =>
        'Porudžbina je isporučena. Možete ostaviti recenziju kupca.',
      OrderStatus.rejected => 'Odbili ste ovu porudžbinu.',
      OrderStatus.cancelledBySeller => 'Otkazali ste ovu porudžbinu.',
      OrderStatus.archived => 'Porudžbina je u arhivi.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    final buyerName = o.counterpartyName ?? 'Kupac';
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
                  child: Icon(Icons.person, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/buyer/${o.buyerId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          buyerName,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                SellerOrderStatusChip(label: o.statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            OrderStatusTimeline(status: o.status),
            const SizedBox(height: 8),
            _SellerHintRow(text: _statusHint(o.status)),
            const SizedBox(height: 8),
            _SellerHintBox(text: _cardHint(o.status)),
            SellerOrderItemsSection(orderId: o.id),
            if (o.totalAmount != null)
              SellerOrderDetailRow(
                icon: Icons.payments_outlined,
                label: 'Ukupno',
                value: formatRsdAmount(o.totalAmount) ?? '',
              ),
            SellerOrderDeliveryRows(order: o),
            if (o.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Napomena',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text(o.note,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (!o.isArchived) ...[
              const SizedBox(height: 12),
              SellerOrderActions(
                order: o,
                buyerName: buyerName,
                sellerId: user.id,
                isArchivedList: isArchivedList,
                onUpdateStatus: (s) => _updateStatus(context, o.id, s),
                onCancel: () => _cancelOrder(context, o.id),
                onArchive: () => _archiveOrder(context),
                onRefresh: onRefresh,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: o.buyerPhone.isNotEmpty
                          ? () =>
                              ActionUtils.launchCall(context, o.buyerPhone)
                          : null,
                      child: const Text('Pozovi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat, size: 18),
                      label: const Text('Poruka'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            OrderStatusAuditLogSection(orderId: o.id),
            SellerOrderDeliveredBadge(status: o.status),
          ],
        ),
      ),
    );
  }
}

class _SellerHintRow extends StatelessWidget {
  final String text;
  const _SellerHintRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _SellerHintBox extends StatelessWidget {
  final String text;
  const _SellerHintBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Zeleni bedž potvrde za prihvaćene/poslate/isporučene porudžbine.
class SellerOrderDeliveredBadge extends StatelessWidget {
  final OrderStatus status;
  const SellerOrderDeliveredBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status != OrderStatus.accepted &&
        status != OrderStatus.shipped &&
        status != OrderStatus.delivered) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2F21) : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark
                  ? const Color(0xFF2E633B)
                  : Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle,
                color: isDark
                    ? AmazonColors.lightGreen
                    : Colors.green.shade700,
                size: 24),
            const SizedBox(width: 8),
            Text(
              status == OrderStatus.delivered
                  ? 'Isporučeno'
                  : status == OrderStatus.shipped
                      ? 'Poslato kupcu - ceka potvrdu kupca'
                      : 'Potvrđeno',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AmazonColors.lightGreen
                    : Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



