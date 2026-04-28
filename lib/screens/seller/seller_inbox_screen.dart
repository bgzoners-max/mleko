import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/app_error.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/seller_inbox_item.dart';
import '../../core/utils/action_utils.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../../core/ui_strings.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/cancel_order_dialog.dart';
import '../../widgets/order_status_audit_log_section.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/app_network_image.dart';

/// Jedinstveni inbox za prodavca – porudžbine i razgovori u jednoj listi
class SellerInboxScreen extends StatefulWidget {
  /// Samo razgovori (bez porudžbina bez razgovora) – za tab Razgovori
  final bool showOnlyConversations;
  final bool showAppBar;

  const SellerInboxScreen(
      {super.key, this.showOnlyConversations = false, this.showAppBar = true});

  @override
  State<SellerInboxScreen> createState() => _SellerInboxScreenState();
}

class _SellerInboxScreenState extends State<SellerInboxScreen>
    with AutomaticKeepAliveClientMixin {
  final _refreshController = StreamController<void>.broadcast();
  final SellerInboxService _sellerInboxService = SellerInboxService();
  final ScrollController _scrollController = ScrollController();
  Stream<List<SellerInboxItem>>? _inboxStream;
  String? _inboxUserId;
  int _limit = 20;
  bool _loadingMore = false;
  bool _hasMore = true;
  List<SellerInboxItem>? _lastItems;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && user.isSeller && _inboxUserId != user.id) {
      _inboxUserId = user.id;
      _initStream(user.id);
    }
  }

  void _initStream(String userId) {
    _inboxStream = _sellerInboxService.watchInbox(
      userId,
      refreshTrigger: _refreshController.stream,
    );
  }

  void _onScroll() {
    // Ako smo blizu dna liste (300px od kraja) i ima još podataka, učitaj sledeću "stranu"
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_inboxUserId == null || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    setState(() {
      _limit += 20;
      _initStream(_inboxUserId!);
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _limit = 20;
      _hasMore = true;
    });
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AppState>().user;
    if (user == null || !user.isSeller) {
      _inboxStream = null;
      _inboxUserId = null;
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: AppEmptyState(
          icon: Icons.store_mall_directory_outlined,
          title: 'Samo za prodavce.',
          subtitle: user == null
              ? 'Prijavite se i aktivirajte prodavca da biste koristili inbox.'
              : 'Ova sekcija je dostupna samo prodavcima.',
          ctaLabel: user == null ? 'Prijavi se' : null,
          ctaIcon: Icons.login,
          onCtaPressed: user == null ? () => context.go('/login') : null,
        ),
      );
    }

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: const Text('Razgovori')) : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: StreamBuilder<List<SellerInboxItem>>(
              stream: _inboxStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return AppErrorRetry(
                    message: 'Greška pri učitavanju inbox-a.',
                    detail: snap.error?.toString(),
                    onRetry: () => _refreshController.add(null),
                  );
                }

                if (snap.hasData) {
                  _lastItems = snap.data;
                }

                if (snap.connectionState != ConnectionState.waiting) {
                  _loadingMore = false;
                }

                if (snap.connectionState == ConnectionState.waiting &&
                    (_lastItems == null || _lastItems!.isEmpty)) {
                  return const OrderListSkeleton();
                }

                var list = snap.data ?? _lastItems ?? [];
                if (widget.showOnlyConversations) {
                  list = list
                      .where((i) => i.type == SellerInboxItemType.conversation)
                      .toList();
                }

                // Ažuriramo _hasMore van build faze u stream listeneru ili ovde preko post frame callback-a
                if (list.length < _limit && _hasMore) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _hasMore = false);
                  });
                }

                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 200,
                        child: AppEmptyState(
                          icon: Icons.chat_outlined,
                          title: widget.showOnlyConversations
                              ? 'Nema razgovora'
                              : 'Nema upita ni poruka',
                          subtitle: widget.showOnlyConversations
                              ? 'Kada kupci pošalju poruku, pojaviće se ovde.'
                              : 'Upiti i poruke od kupaca će se pojaviti ovde kada počnu da naručuju.',
                          ctaLabel: 'Pregledaj proizvode',
                          ctaIcon: Icons.storefront_outlined,
                          onCtaPressed: () => context.go('/'),
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == list.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = list[i];
                      return item.type == SellerInboxItemType.order
                          ? _OrderInboxCard(
                              item: item,
                              user: user,
                              onRefresh: () => _refreshController.add(null),
                            )
                          : _ConversationInboxCard(
                              item: item,
                              onRefresh: () => _refreshController.add(null),
                            );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderInboxCard extends StatefulWidget {
  final SellerInboxItem item;
  final UserModel user;
  final VoidCallback onRefresh;

  const _OrderInboxCard(
      {required this.item, required this.user, required this.onRefresh});

  @override
  State<_OrderInboxCard> createState() => _OrderInboxCardState();
}

class _OrderInboxCardState extends State<_OrderInboxCard> {
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
                            );
                            if (context.mounted) context.push('/chat/$convId');
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
    return status.displayName; // Pretpostavka: dodati extension na OrderStatus
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

class _ConversationInboxCard extends StatefulWidget {
  final SellerInboxItem item;
  final VoidCallback onRefresh;

  const _ConversationInboxCard({
    required this.item,
    required this.onRefresh,
  });

  @override
  State<_ConversationInboxCard> createState() => _ConversationInboxCardState();
}

class _ConversationInboxCardState extends State<_ConversationInboxCard> {
  bool _isProcessing = false;

  Future<void> _toggleFavorite() async {
    final cid = widget.item.conversationId;
    if (cid == null) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<ChatService>().setConversationUserPrefs(
            cid,
            isFavorite: !widget.item.isFavorite,
          );
      widget.onRefresh();
    } catch (e, stack) {
      if (!mounted) return;
      LoggerService.error(
        'Greška pri promeni favorite statusa konverzacije',
        e,
        stackTrace: stack,
        extra: {
          'conversationId': cid,
          'isFavorite': !widget.item.isFavorite,
        },
      );
      ErrorSnackBar.show(context, error: AppError.from(e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmHide(BuildContext context) async {
    final chatService = context.read<ChatService>();
    final cid = widget.item.conversationId;
    if (cid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukloni sa liste?'),
        content: const Text(
          'Razgovor neće biti prikazan u inbox-u. Istorija ostaje — ponovo će se pojaviti kada otvoriš chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    setState(() => _isProcessing = true);
    try {
      await chatService.setConversationUserPrefs(cid, hidden: true);
      widget.onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Razgovor je uklonjen sa liste.')),
        );
      }
    } catch (e, stack) {
      if (context.mounted) {
        LoggerService.error(
          'Greška pri sakrivanju konverzacije',
          e,
          stackTrace: stack,
          extra: {
            'conversationId': cid,
          },
        );
        ErrorSnackBar.show(context, error: AppError.from(e));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item;
    final cid = c.conversationId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                if (cid != null) context.push('/chat/$cid');
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              c.otherPartyImageUrl != null && c.otherPartyImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: AppNetworkImage.profileSmall(
                        imageUrl: c.otherPartyImageUrl!,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        if (c.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.star,
                                size: 14, color: Colors.amber.shade700),
                          ),
                        Expanded(
                          child: c.buyerId != null
                              ? InkWell(
                                  onTap: () =>
                                      context.push('/buyer/${c.buyerId}'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          c.otherPartyName ?? 'Kupac',
                                          style: TextStyle(
                                            fontWeight: c.unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.person_outline,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ],
                                  ),
                                )
                              : Text(
                                  c.otherPartyName ?? 'Kupac',
                                  style: TextStyle(
                                    fontWeight: c.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (c.productName != null)
                      Text(
                        '${c.productName}${c.quantityKg != null ? ' · ${ProductModel.formatQuantityWithUnit(c.quantityKg!, c.unitType ?? ProductModel.unitKg)}' : ''}',
                      ),
                    Text(
                      c.lastMessageBody ?? 'Nema poruka',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.unreadCount > 0
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (c.statusLabel != null)
                      Text(
                        c.statusLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (cid != null) ...[
                IconButton(
                  tooltip: _isProcessing
                      ? null
                      : (c.isFavorite ? 'Ukloni iz omiljenih' : 'Omiljeni'),
                  icon: Icon(
                    c.isFavorite ? Icons.star : Icons.star_outline,
                    color: c.isFavorite ? Colors.amber.shade700 : null,
                  ),
                  onPressed: _isProcessing ? null : _toggleFavorite,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) async {
                    if (_isProcessing) return;
                    if (v == 'fav') {
                      await _toggleFavorite();
                    } else if (v == 'hide') {
                      await _confirmHide(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'fav',
                      child: Text(
                        c.isFavorite
                            ? 'Ukloni iz omiljenih'
                            : 'Označi kao omiljeni',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Text('Ukloni sa liste'),
                    ),
                  ],
                ),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (c.unreadCount > 0)
                    Badge(
                      label: Text('${c.unreadCount}'),
                      child: const Icon(Icons.chevron_right, size: 20),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
