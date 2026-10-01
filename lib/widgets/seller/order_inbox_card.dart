import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/ui_strings.dart';
import '../../core/utils/action_utils.dart';
import '../../models/app_error.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import '../app_network_image.dart';
import '../cancel_order_dialog.dart';
import '../error_dialog.dart';
import '../home/seller_inbox_item.dart';
import '../order_status_audit_log_section.dart';
import '../order_status_timeline.dart';

class OrderInboxCard extends StatefulWidget {
  final SellerInboxItem item;
  final UserModel user;
  final VoidCallback onRefresh;

  const OrderInboxCard({
    super.key,
    required this.item,
    required this.user,
    required this.onRefresh,
  });

  @override
  State<OrderInboxCard> createState() => _OrderInboxCardState();
}

class _OrderInboxCardState extends State<OrderInboxCard> {
  bool _isProcessing = false;

  Future<void> _updateStatus(
      BuildContext context, String orderId, OrderStatus status) async {
    setState(() => _isProcessing = true);
    final ordersService = context.read<OrdersService>();
    try {
      await ordersService.updateOrderStatus(orderId, status);
      widget.onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Status uspešno ažuriran: ${_statusDisplayName(status)}.'),
          ),
        );
      }
    } catch (e, stack) {
      if (context.mounted) {
        LoggerService.error(
          'Greška pri ažuriranju statusa porudžbine',
          e,
          stackTrace: stack,
          extra: {'orderId': orderId, 'status': status.name},
        );
        ErrorSnackBar.show(context, error: AppError.from(e));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final ordersService = context.read<OrdersService>();
    final reason = await CancelOrderDialog.show(context);
    if (reason == null || !context.mounted) return;

    setState(() => _isProcessing = true);
    try {
      await ordersService.cancelOrderBySeller(orderId, reason);
      widget.onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Porudžbina je otkazana.')),
        );
      }
    } catch (e, stack) {
      if (context.mounted) {
        LoggerService.error(
          'Greška pri otkazivanju porudžbine',
          e,
          stackTrace: stack,
          extra: {
            'orderId': orderId,
            'reason': reason,
            'userId': widget.user.id,
          },
        );
        ErrorSnackBar.show(context, error: AppError.from(e));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleCall(String? phone) async {
    try {
      await ActionUtils.launchCall(context, phone);
    } catch (e, stack) {
      if (mounted) {
        LoggerService.error(
          'Greška pri pokretanju poziva iz inbox-a',
          e,
          stackTrace: stack,
          extra: {'phone': phone, 'orderId': widget.item.orderId},
        );
        ErrorSnackBar.show(context,
            error:
                AppError.from(e, userMessage: 'Neuspelo pokretanje poziva.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.item;
    final status = o.status ?? OrderStatus.sent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                o.otherPartyImageUrl != null && o.otherPartyImageUrl!.isNotEmpty
                    ? ClipOval(
                        child: AppNetworkImage.profileSmall(
                          imageUrl: o.otherPartyImageUrl!,
                          width: 40,
                          height: 40,
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Icon(Icons.person,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          if (o.buyerId != null)
                            InkWell(
                              onTap: () => context.push('/buyer/${o.buyerId}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(o.otherPartyName ?? 'Kupac',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.person_outline,
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                ],
                              ),
                            )
                          else
                            Text(o.otherPartyName ?? 'Kupac',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(o.productName ?? '',
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (o.quantityKg != null)
                        Text(ProductModel.formatQuantityWithUnit(
                            o.quantityKg!, o.unitType ?? ProductModel.unitKg)),
                      if (o.buyerCity != null && o.buyerCity!.isNotEmpty)
                        Text(o.buyerCity!,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      if (o.note != null && o.note!.isNotEmpty)
                        Text('Napomena: ${o.note}',
                            style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      if (o.buyerPhone != null && o.buyerPhone!.isNotEmpty)
                        Row(children: [
                          Icon(Icons.phone,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(o.buyerPhone!,
                              style: const TextStyle(fontSize: 13))
                        ]),
                      Text('Status: ${o.statusLabel}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _statusColor(context, status))),
                      if (o.statusLabel != null) ...[
                        const SizedBox(height: 8),
                        OrderStatusTimeline(
                          status: status,
                        ),
                      ],
                      if (o.orderId != null) ...[
                        const SizedBox(height: 8),
                        OrderStatusAuditLogSection(orderId: o.orderId!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed:
                      _isProcessing ? null : () => _handleCall(o.buyerPhone),
                  child: const Text('Pozovi'),
                ),
                OutlinedButton.icon(
                  onPressed: (o.buyerId == null || _isProcessing)
                      ? null
                      : () async {
                          try {
                            final chatService = context.read<ChatService>();
                            final convId =
                                await chatService.getOrCreateConversation(
                              o.buyerId!,
                              widget.user.id,
                              orderId: o.orderId,
                              productId: o.productId,
                              adId: o.adId,
                            );
                            if (context.mounted) unawaited(context.push('/chat/$convId'));
                          } catch (e, stack) {
                            if (context.mounted) {
                              LoggerService.error(
                                'Neuspešno otvaranje konverzacije iz inbox-a',
                                e,
                                stackTrace: stack,
                                extra: {
                                  'buyerId': o.buyerId,
                                  'orderId': o.orderId,
                                },
                              );
                              ErrorSnackBar.show(
                                context,
                                error: AppError.from(
                                  e,
                                  userMessage:
                                      UiStrings.errorOpenConversationFailed,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text(UiStrings.actionMessage),
                ),
                if (status == OrderStatus.sent ||
                    status == OrderStatus.rejected) ...[
                  FilledButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus(
                            context, o.orderId!, OrderStatus.accepted),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const SizedBox.shrink(),
                    label: const Text('Prihvati'),
                  ),
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Odbij porudžbinu?'),
                                content: const Text(
                                    'Kupac će biti obavešten da ste odbili porudžbinu.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(UiStrings.actionCancel),
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
                              await _updateStatus(
                                  context, o.orderId!, OrderStatus.rejected);
                            }
                          },
                    child: const Text('Odbij'),
                  ),
                ],
                if (status == OrderStatus.accepted) ...[
                  FilledButton.tonal(
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus(
                            context, o.orderId!, OrderStatus.shipped),
                    child: const Text('Poslato'),
                  ),
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _cancelOrder(context, o.orderId!),
                    child: const Text('Otkaži'),
                  ),
                ],
                if (status == OrderStatus.shipped) ...[
                  const Chip(
                    label: Text('Ceka potvrdu kupca'),
                    avatar: Icon(Icons.schedule, size: 16),
                  ),
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _cancelOrder(context, o.orderId!),
                    child: const Text('Otkaži'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Pomoćna metoda za prikaz naziva statusa u UI porukama (SnackBar).
  String _statusDisplayName(OrderStatus status) {
    return status.displayName;
  }

  Color _statusColor(BuildContext context, OrderStatus status) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case OrderStatus.sent:
        return Colors.orange.shade700;
      case OrderStatus.shipped:
        return Colors.teal.shade600;
      case OrderStatus.accepted:
        return Colors.blue.shade600;
      case OrderStatus.rejected:
      case OrderStatus.cancelledBySeller:
        return Colors.red;
      case OrderStatus.delivered:
      case OrderStatus.archived:
        return scheme.primary;
    }
  }
}
