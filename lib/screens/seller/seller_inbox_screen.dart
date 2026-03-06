import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/seller_inbox_item.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/chat_service.dart';
import '../../services/orders_service.dart';
import '../../services/seller_inbox_service.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/cancel_order_dialog.dart';
import '../../widgets/skeleton.dart';

/// Jedinstveni inbox za prodavca – porudžbine i razgovori u jednoj listi
class SellerInboxScreen extends StatefulWidget {
  /// Samo razgovori (bez porudžbina bez razgovora) – za tab Razgovori
  final bool showOnlyConversations;
  final bool showAppBar;

  const SellerInboxScreen({super.key, this.showOnlyConversations = false, this.showAppBar = true});

  @override
  State<SellerInboxScreen> createState() => _SellerInboxScreenState();
}

class _SellerInboxScreenState extends State<SellerInboxScreen> {
  final _refreshController = StreamController<void>.broadcast();

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || !user.isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: const Center(child: Text('Samo za prodavce.')),
      );
    }
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Razgovori')) : null,
      body: StreamBuilder<List<SellerInboxItem>>(
        stream: SellerInboxService().watchInbox(user.id, refreshTrigger: _refreshController.stream),
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju inbox-a.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const OrderListSkeleton();
          }
          var list = snap.data ?? [];
          if (widget.showOnlyConversations) {
            list = list.where((i) => i.type == SellerInboxItemType.conversation).toList();
          }
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          widget.showOnlyConversations ? 'Nema razgovora.' : 'Nema upita ni poruka.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final item = list[i];
                return item.type == SellerInboxItemType.order
                    ? _OrderInboxCard(
                        item: item,
                        user: user,
                        onRefresh: () => _refreshController.add(null),
                      )
                    : _ConversationInboxCard(item: item);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderInboxCard extends StatelessWidget {
  final SellerInboxItem item;
  final UserModel user;
  final VoidCallback onRefresh;

  const _OrderInboxCard({required this.item, required this.user, required this.onRefresh});

  Future<void> _launchCall(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _updateStatus(BuildContext context, String orderId, OrderStatus status) async {
    await OrdersService().updateOrderStatus(orderId, status);
    onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status: ${status == OrderStatus.accepted ? 'Prihvaćeno' : status == OrderStatus.rejected ? 'Odbijeno' : status == OrderStatus.cancelledBySeller ? 'Otkazano' : 'Isporučeno'}.')),
      );
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId) async {
    final reason = await CancelOrderDialog.show(context);
    if (reason == null || !context.mounted) return;
    await OrdersService().cancelOrderBySeller(orderId, reason);
    onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Porudžbina je otkazana.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = item;
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
                  backgroundImage: o.otherPartyImageUrl != null && o.otherPartyImageUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(o.otherPartyImageUrl!)
                      : null,
                  child: o.otherPartyImageUrl == null || o.otherPartyImageUrl!.isEmpty
                      ? Icon(Icons.person, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          if (o.buyerId != null)
                            InkWell(
                              onTap: () => context.push('/buyer/${o.buyerId}'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(o.otherPartyName ?? 'Kupac', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                                ],
                              ),
                            )
                          else
                            Text(o.otherPartyName ?? 'Kupac', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(o.productName ?? '', style: Theme.of(context).textTheme.bodyMedium),
                      if (o.quantityKg != null) Text(ProductModel.formatQuantityWithUnit(o.quantityKg!, o.unitType ?? ProductModel.unitKg)),
                      if (o.buyerCity != null && o.buyerCity!.isNotEmpty)
                        Text(o.buyerCity!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      if (o.note != null && o.note!.isNotEmpty)
                        Text('Napomena: ${o.note}', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade700), maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (o.buyerPhone != null && o.buyerPhone!.isNotEmpty)
                        Row(children: [Icon(Icons.phone, size: 14, color: Colors.green.shade700), const SizedBox(width: 4), Text(o.buyerPhone!, style: const TextStyle(fontSize: 13))]),
                      Text('Status: ${o.statusLabel}', style: TextStyle(fontWeight: FontWeight.w500, color: _statusColor(o.statusLabel))),
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
                  onPressed: () => _launchCall(o.buyerPhone),
                  child: const Text('Pozovi'),
                ),
                OutlinedButton.icon(
                  onPressed: o.buyerId == null
                      ? null
                      : () async {
                          try {
                            final convId = await ChatService().getOrCreateConversation(
                              o.buyerId!, user.id,
                              orderId: o.orderId,
                            );
                            if (context.mounted) context.push('/chat/$convId');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Poruka'),
                ),
                if (_isSent(o.statusLabel)) ...[
                  FilledButton(
                    onPressed: () => _updateStatus(context, o.orderId!, OrderStatus.accepted),
                    child: const Text('Prihvati'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Odbij porudžbinu?'),
                          content: const Text('Kupac će biti obavešten da ste odbili porudžbinu.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Odustani'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text('Odbij'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await _updateStatus(context, o.orderId!, OrderStatus.rejected);
                      }
                    },
                    child: const Text('Odbij'),
                  ),
                ],
                if (_isAccepted(o.statusLabel)) ...[
                  FilledButton(
                    onPressed: () => _updateStatus(context, o.orderId!, OrderStatus.delivered),
                    child: const Text('Isporučeno'),
                  ),
                  OutlinedButton(
                    onPressed: () => _cancelOrder(context, o.orderId!),
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

  bool _isSent(String? s) => s == 'Poslato';
  bool _isAccepted(String? s) => s == 'Prihvaćeno';

  Color _statusColor(String? s) {
    switch (s) {
      case 'Poslato': return Colors.orange;
      case 'Prihvaćeno': return Colors.blue;
      case 'Odbijeno': return Colors.red;
      case 'Isporučeno': return Colors.green;
      case 'Otkazano': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class _ConversationInboxCard extends StatelessWidget {
  final SellerInboxItem item;

  const _ConversationInboxCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          backgroundImage: c.otherPartyImageUrl != null && c.otherPartyImageUrl!.isNotEmpty
              ? CachedNetworkImageProvider(c.otherPartyImageUrl!)
              : null,
          child: c.otherPartyImageUrl == null || c.otherPartyImageUrl!.isEmpty
              ? Icon(Icons.person, color: Colors.grey.shade600)
              : null,
        ),
        title: Row(
          children: [
            Icon(Icons.chat, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: c.buyerId != null
                  ? InkWell(
                      onTap: () => context.push('/buyer/${c.buyerId}'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.otherPartyName ?? 'Kupac',
                            style: TextStyle(
                              fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.person_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    )
                  : Text(
                      c.otherPartyName ?? 'Kupac',
                      style: TextStyle(
                        fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.productName != null) Text('${c.productName}${c.quantityKg != null ? ' · ${ProductModel.formatQuantityWithUnit(c.quantityKg!, c.unitType ?? ProductModel.unitKg)}' : ''}'),
            Text(
              c.lastMessageBody ?? 'Nema poruka',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            if (c.statusLabel != null) Text(c.statusLabel!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: c.unreadCount > 0
            ? Badge(
                label: Text('${c.unreadCount}'),
                child: const Icon(Icons.chevron_right, size: 20),
              )
            : const Icon(Icons.chevron_right),
        onTap: () {
          if (c.conversationId != null) context.push('/chat/${c.conversationId}');
        },
      ),
    );
  }
}
