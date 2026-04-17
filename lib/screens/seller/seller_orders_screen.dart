import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../core/utils/action_utils.dart';
import '../../providers/app_state.dart';
import '../../services/communication/communication_services.dart';
import '../../services/orders/order_services.dart';
import '../../services/social/social_services.dart';
import '../../widgets/add_buyer_review_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/cancel_order_dialog.dart';
import '../../widgets/order_delivery_summary.dart';
import '../../widgets/order_status_audit_log_section.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/skeleton.dart';

/// Posebna sekcija Porudžbine za prodavca – pregledna lista sa svim detaljima
class SellerOrdersScreen extends StatefulWidget {
  final bool showAppBar;

  const SellerOrdersScreen({super.key, this.showAppBar = true});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final _refreshController = StreamController<void>.broadcast();

  Stream<List<OrderModel>>? _ordersStream;
  String? _streamKey;

  final List<OrderModel> _olderOrders = [];
  bool _hasMore = true;
  bool _loadingMore = false;

  int _segmentIndex = 0;
  String get _statusFilter => _segmentIndex == 0
      ? OrdersService.statusFilterActiveNonArchived
      : 'arhivirano';
  bool get _isArchive => _segmentIndex == 1;

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _initStream(String userId) {
    final key = '$userId|$_statusFilter';
    if (_streamKey == key) return;
    _streamKey = key;
    _olderOrders.clear();
    _hasMore = true;
    _ordersStream = context.read<OrdersService>().getOrdersBySeller(
      userId,
      refreshTrigger: _refreshController.stream,
      statusFilter: _statusFilter,
    );
  }

  Future<void> _onRefresh() async {
    _olderOrders.clear();
    _hasMore = true;
    _refreshController.add(null);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  Future<void> _loadMore(String userId, int currentCount) async {
    if (_loadingMore || !_hasMore) return;
    final ordersService = context.read<OrdersService>();
    setState(() => _loadingMore = true);
    try {
      final more = await ordersService.fetchMoreOrdersBySeller(
        userId,
        offset: currentCount + _olderOrders.length,
        statusFilter: _statusFilter,
      );
      if (mounted) {
        setState(() {
          _olderOrders.addAll(more);
          if (more.length < 20) _hasMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Greška pri učitavanju starijih porudžbina.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || !user.isSeller) {
      return Scaffold(
        appBar: AppBar(title: const Text('Porudžbine')),
        body: const Center(child: Text('Samo za prodavce.')),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar:
          widget.showAppBar ? AppBar(title: const Text('Porudžbine')) : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                        value: 0,
                        label: Text('Aktivne'),
                        icon: Icon(Icons.receipt_long)),
                    ButtonSegment(
                        value: 1,
                        label: Text('Arhiva'),
                        icon: Icon(Icons.archive_outlined)),
                  ],
                  selected: {_segmentIndex},
                  onSelectionChanged: (s) => setState(() {
                    _segmentIndex = s.first;
                    _streamKey = null;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    _isArchive
                        ? 'Ovde su porudžbine koje ste ručno arhivirali. Brisanje nakon isteka roka čuvanja (expires_at), ako je podešeno.'
                        : 'Aktivne porudžbine (bez arhive). Završene — isporučeno, odbijeno ili otkazano — možete arhivirati da nestanu sa ove liste.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<OrderModel>>(
                    stream: _ordersStream,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const OrderListSkeleton();
                      }
                      if (snap.hasError) {
                        return AppErrorRetry(
                          message: 'Greška pri učitavanju porudžbina.',
                          detail: snap.error?.toString(),
                          onRetry: _onRefresh,
                        );
                      }
                      final recent = snap.data ?? [];
                      final orders = [...recent, ..._olderOrders];
                      if (orders.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height - 260,
                              child: AppEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: _isArchive
                                    ? 'Nema arhiviranih porudžbina'
                                    : 'Nemate porudžbina',
                                subtitle: _isArchive
                                    ? 'Kada arhivirate porudžbinu, pojaviće se ovde.'
                                    : 'Kada kupci pošalju upit, porudžbine će se pojaviti ovde.',
                                ctaLabel:
                                    _isArchive ? null : 'Pregledaj proizvode',
                                ctaIcon: Icons.storefront_outlined,
                                onCtaPressed:
                                    _isArchive ? null : () => context.go('/'),
                              ),
                            ),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 16 + MediaQuery.of(context).padding.bottom,
                          ),
                          itemCount: (_isArchive ? 1 : 0) +
                              orders.length +
                              (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (_isArchive && i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Ista porudžbina može biti arhivirana i od kupca i od vas; ovde vidite samo vašu arhivu.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              );
                            }
                            final listIndex = _isArchive ? i - 1 : i;
                            if (listIndex == orders.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: _loadingMore
                                      ? const CircularProgressIndicator()
                                      : OutlinedButton(
                                          onPressed: () =>
                                              _loadMore(user.id, recent.length),
                                          child: const Text('Učitaj starije'),
                                        ),
                                ),
                              );
                            }
                            return _SellerOrderCard(
                              order: orders[listIndex],
                              user: user,
                              isArchivedList: _isArchive,
                              onRefresh: () => _refreshController.add(null),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  final UserModel user;
  final bool isArchivedList;
  final VoidCallback onRefresh;

  const _SellerOrderCard({
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
        SnackBar(
          content: Text(
              'Status: ${status == OrderStatus.accepted ? 'Prihvaćeno' : status == OrderStatus.shipped ? 'Poslato' : status == OrderStatus.rejected ? 'Odbijeno' : status == OrderStatus.cancelledBySeller ? 'Otkazano' : 'Isporučeno'}.'),
        ),
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

  @override
  Widget build(BuildContext context) {
    final o = order;
    // counterpartyName je batch-učitan u servisu — nema N+1 FutureBuilder
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
                                  color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                _statusChip(context, o.statusLabel),
              ],
            ),
            const SizedBox(height: 10),
            OrderStatusTimeline(status: o.status),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    switch (o.status) {
                      OrderStatus.sent =>
                        'Porudžbina je poslata – na vama je da je prihvatite ili odbijete.',
                      OrderStatus.accepted =>
                        'Prihvatili ste porudžbinu – pošaljite je kupcu kada bude spremna.',
                      OrderStatus.shipped =>
                        'Označili ste porudžbinu kao poslatu – čeka se potvrda kupca.',
                      OrderStatus.delivered =>
                        'Kupac je potvrdio prijem – možete ostaviti recenziju kupca.',
                      OrderStatus.rejected => 'Odbili ste ovu porudžbinu.',
                      OrderStatus.cancelledBySeller =>
                        'Otkazali ste ovu porudžbinu.',
                      OrderStatus.archived => 'Porudžbina je u arhivi.',
                    },
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OrderStatusAuditLogSection(orderId: o.id),
            if (o.status == OrderStatus.accepted ||
                o.status == OrderStatus.shipped ||
                o.status == OrderStatus.delivered)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.green.shade700, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        o.status == OrderStatus.delivered
                            ? 'Isporučeno'
                            : o.status == OrderStatus.shipped
                                ? 'Poslato kupcu - ceka potvrdu kupca'
                                : 'Potvrđeno',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (o.hasMultipleItems)
              _SellerOrderItemsSection(orderId: o.id)
            else ...[
              _DetailRow(
                  icon: Icons.inventory_2,
                  label: 'Proizvod',
                  value: o.productName ?? ''),
              _DetailRow(
                  icon: Icons.scale,
                  label: 'Količina',
                  value: ProductModel.formatQuantityWithUnit(
                      o.quantityKg ?? 0, o.unitType ?? ProductModel.unitKg)),
            ],
            if (o.buyerCity.isNotEmpty)
              _DetailRow(
                  icon: Icons.location_on, label: 'Grad', value: o.buyerCity),
            if (o.hasSellerDelivery) OrderDeliverySummary(order: o),
            if (o.buyerPhone.isNotEmpty)
              _DetailRow(
                icon: Icons.phone,
                label: 'Telefon',
                value: o.buyerPhone,
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () =>
                      ActionUtils.launchCall(context, o.buyerPhone),
                  tooltip: 'Pozovi',
                ),
              ),
            if (o.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              Text(o.note,
                                  style: const TextStyle(
                                      fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (!o.isArchived) ...[
              const SizedBox(height: 12),
              Column(
                children: [
                  // Status-specific buttons (Prihvati/Odbij, Poslato/Otkaži, etc.)
                  if (o.status == OrderStatus.sent) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _updateStatus(
                                context, o.id, OrderStatus.accepted),
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
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                                await _updateStatus(
                                    context, o.id, OrderStatus.rejected);
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
                            onPressed: () => _updateStatus(
                                context, o.id, OrderStatus.shipped),
                            child: const Text('Poslato'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _cancelOrder(context, o.id),
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
                            onPressed: () => _cancelOrder(context, o.id),
                            child: const Text('Otkaži'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (o.status == OrderStatus.delivered) ...[
                    _CanSellerReviewBuyerButton(
                      key: ValueKey('canreviewbuyer-${o.id}'),
                      sellerId: user.id,
                      order: o,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => AddBuyerReviewDialog(
                          sellerId: user.id,
                          buyerId: o.buyerId,
                          orderId: o.id,
                          buyerName: buyerName,
                          onSubmitted: onRefresh,
                        ),
                      ),
                    ),
                  ],
                  // Archive button (if applicable)
                  if (!isArchivedList && o.canSellerManuallyArchive) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _archiveOrder(context),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('Arhiviraj'),
                      ),
                    ),
                  ],
                  // Call and Message buttons
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
                          onPressed: () async {
                            try {
                              final convId =
                                  await context.read<ChatService>().getOrCreateConversation(
                                o.buyerId,
                                user.id,
                                orderId: o.id,
                              );
                              if (context.mounted) {
                                context.push('/chat/$convId');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Greška: $e'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Poruka'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String label) {
    final color = switch (label) {
      'Na čekanju' => Colors.orange,
      'Poslato' => Colors.teal,
      'Prihvaćeno' => Colors.blue,
      'Odbijeno' => Colors.red,
      'Isporučeno' => Colors.green,
      'Otkazano' => Colors.grey,
      'Arhivirano' => Colors.brown,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _SellerOrderItemsSection extends StatelessWidget {
  final String orderId;

  const _SellerOrderItemsSection({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderItemModel>>(
      future: context.read<OrdersService>().getOrderItems(orderId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        final totalLabel = OrderItemModel.totalQuantityLabel(items);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalLabel.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                ),
              ),
            ],
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.inventory_2,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                              ProductModel.formatQuantityWithUnit(
                                  item.quantityKg, item.unitType),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _CanSellerReviewBuyerButton extends StatefulWidget {
  final String sellerId;
  final OrderModel order;
  final VoidCallback onPressed;

  const _CanSellerReviewBuyerButton({
    super.key,
    required this.sellerId,
    required this.order,
    required this.onPressed,
  });

  @override
  State<_CanSellerReviewBuyerButton> createState() =>
      _CanSellerReviewBuyerButtonState();
}

class _CanSellerReviewBuyerButtonState
    extends State<_CanSellerReviewBuyerButton> {
  Future<bool>? _canReviewFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canReviewFuture ??= context.read<ReviewsService>().canSellerReviewBuyer(widget.sellerId, widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canReviewFuture,
      builder: (ctx, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.star_outline, size: 18),
          label: const Text('Oceni kupca'),
          onPressed: widget.onPressed,
        );
      },
    );
  }
}
