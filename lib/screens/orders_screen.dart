import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../models/order_item_model.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/add_review_dialog.dart';
import '../models/seller_delivery_models.dart';
import '../widgets/order_delivery_summary.dart';
import '../widgets/order_status_audit_log_section.dart';
import '../widgets/order_status_timeline.dart';
import '../widgets/skeleton.dart';

/// Posebna sekcija Porudžbine za kupca – pregledna lista naručenih proizvoda
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _refreshController = StreamController<void>.broadcast();
  OrdersService? _ordersService;

  Stream<List<OrderModel>>? _ordersStream;
  String? _streamKey;

  final List<OrderModel> _olderOrders = [];
  bool _hasMore = true;
  bool _loadingMore = false;

  /// 0 = Aktivne (sent), 1 = Arhiva (arhivirano), 2 = Po prodavcima
  int _segmentIndex = 0;
  int _statusChipIndex = 0;

  String? get _statusFilter {
    if (_segmentIndex == 1) return 'arhivirano';
    if (_segmentIndex != 0) return null;
    switch (_statusChipIndex) {
      case 1:
        return 'sent';
      case 2:
        return 'accepted';
      case 3:
        return 'shipped';
      case 4:
        return 'rejected';
      case 5:
        return 'delivered';
      case 6:
        return 'cancelled_by_seller';
      default:
        return OrdersService.statusFilterActiveNonArchived;
    }
  }

  bool get _isArchive => _segmentIndex == 1;
  bool get _isBySeller => _segmentIndex == 2;

  String get _segmentDescription {
    if (_segmentIndex == 0) {
      return 'Aktivna lista: sve što nije u tvojoj arhivi. Završene porudžbine možeš ručno da arhiviraš.';
    }
    if (_segmentIndex == 1) {
      return 'U arhivi su samo porudžbine koje ste vi ručno arhivirali.';
    }
    return 'Koliko često poručuješ i koliki ti je prosečan račun kod svakog prodavca.';
  }

  String get _panelTitle {
    if (_segmentIndex == 1) return 'Arhivirane porudžbine';
    if (_segmentIndex == 2) return 'Pregled po prodavcima';
    return 'Aktivne porudžbine';
  }

  void _selectSegment(int value) {
    setState(() {
      _segmentIndex = value;
      _statusChipIndex = 0;
      _streamKey = null;
    });
  }

  void _selectStatusChip(int value) {
    setState(() {
      _statusChipIndex = value;
      _streamKey = null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ordersService ??= context.read<OrdersService>();
  }

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _initStream(String userId) {
    if (_isBySeller) return;
    final key = '$userId|$_segmentIndex|$_statusChipIndex';
    if (_streamKey == key) return;
    _streamKey = key;
    _olderOrders.clear();
    _hasMore = true;
    _ordersStream = _ordersService!.getOrdersByBuyer(
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
    setState(() => _loadingMore = true);
    try {
      final more = await _ordersService!.fetchMoreOrdersByBuyer(
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

  Widget _buildSegmentedControl(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('U toku'),
          icon: Icon(Icons.receipt_long),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Arhiva'),
          icon: Icon(Icons.archive_outlined),
        ),
        ButtonSegment(
          value: 2,
          label: Text('Prodavci'),
          icon: Icon(Icons.store),
        ),
      ],
      selected: {_segmentIndex},
      onSelectionChanged: (selection) => _selectSegment(selection.first),
    );
  }

  Widget _buildStatusFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Sve'),
          selected: _statusChipIndex == 0,
          onSelected: (_) => _selectStatusChip(0),
        ),
        FilterChip(
          label: const Text('Čeka prodavca'),
          selected: _statusChipIndex == 1,
          onSelected: (_) => _selectStatusChip(1),
        ),
        FilterChip(
          label: const Text('Prihvaćene'),
          selected: _statusChipIndex == 2,
          onSelected: (_) => _selectStatusChip(2),
        ),
        FilterChip(
          label: const Text('Poslate'),
          selected: _statusChipIndex == 3,
          onSelected: (_) => _selectStatusChip(3),
        ),
        FilterChip(
          label: const Text('Odbijene'),
          selected: _statusChipIndex == 4,
          onSelected: (_) => _selectStatusChip(4),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final cardPadding = Breakpoints.cardPadding(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Porudžbine',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _segmentDescription,
                    style: Breakpoints.supportingTextStyle(
                      context,
                      Theme.of(context).textTheme.bodyMedium,
                      phone: 13,
                      largeTabletValue: 14,
                      desktop: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Osveži prikaz'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: Breakpoints.panelGap(context)),
          Card(
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sekcije',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OrdersSidebarTile(
                    icon: Icons.receipt_long,
                    label: 'U toku',
                    selected: _segmentIndex == 0,
                    onTap: () => _selectSegment(0),
                  ),
                  const SizedBox(height: 8),
                  _OrdersSidebarTile(
                    icon: Icons.archive_outlined,
                    label: 'Arhiva',
                    selected: _segmentIndex == 1,
                    onTap: () => _selectSegment(1),
                  ),
                  const SizedBox(height: 8),
                  _OrdersSidebarTile(
                    icon: Icons.store,
                    label: 'Prodavci',
                    selected: _segmentIndex == 2,
                    onTap: () => _selectSegment(2),
                  ),
                ],
              ),
            ),
          ),
          if (_segmentIndex == 0) ...[
            SizedBox(height: Breakpoints.panelGap(context)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Status filter',
                      style: Breakpoints.sectionTitleStyle(
                        context,
                        Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusFilters(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersPanel(BuildContext context, String userId) {
    if (_isBySeller) {
      return _BySellerTab(userId: userId, onRefresh: _onRefresh);
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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
        final list = [...recent, ..._olderOrders];
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 220,
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isArchive
                              ? 'Još nema arhiviranih porudžbina.'
                              : 'Još nema porudžbina.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isArchive
                              ? 'Kada ručno arhivirate porudžbinu, pojaviće se ovde.'
                              : 'Kreni od pregleda proizvoda i pošalji prvu porudžbinu.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (!_isArchive)
                          FilledButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.search),
                            label: const Text('Pronađi proizvode'),
                          ),
                      ],
                    ),
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
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: (_isArchive ? 1 : 0) + list.length + (_hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (_isArchive && i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Porudžbina prelazi u arhivu tek kada je vi arhivirate.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                );
              }
              final listIndex = _isArchive ? i - 1 : i;
              if (listIndex == list.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: _loadingMore
                        ? const CircularProgressIndicator()
                        : OutlinedButton(
                            onPressed: () => _loadMore(userId, recent.length),
                            child: const Text('Učitaj starije'),
                          ),
                  ),
                );
              }
              return _BuyerOrderCard(
                order: list[listIndex],
                user: context.read<AppState>().user,
                refreshController: _refreshController,
                isArchived: _isArchive,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Moje porudžbine')),
        body: const Center(child: Text('Prijavite se da vidite porudžbine.')),
      );
    }

    _initStream(user.id);
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final panelGap = Breakpoints.panelGap(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Moje porudžbine')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                isTwoPaneLayout ? Breakpoints.dataContentWidth(context) : 800,
          ),
          child: isTwoPaneLayout
              ? Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: Breakpoints.desktopSidebarWidth(context),
                        child: _buildDesktopSidebar(context),
                      ),
                      SizedBox(width: panelGap),
                      Expanded(
                        child: Card(
                          margin: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  Breakpoints.cardPadding(context),
                                  Breakpoints.cardPadding(context),
                                  Breakpoints.cardPadding(context),
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _panelTitle,
                                            style:
                                                Breakpoints.sectionTitleStyle(
                                              context,
                                              Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _segmentDescription,
                                            style:
                                                Breakpoints.supportingTextStyle(
                                              context,
                                              Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              phone: 13,
                                              largeTabletValue: 14,
                                              desktop: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: _buildOrdersPanel(context, user.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Breakpoints.horizontalPadding(context),
                        8,
                        Breakpoints.horizontalPadding(context),
                        4,
                      ),
                      child: _buildSegmentedControl(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _segmentDescription,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ),
                    if (_segmentIndex == 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildStatusFilters(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildOrdersPanel(context, user.id),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static Future<void> _maybeShowReview(BuildContext context, dynamic user,
      OrderModel order, StreamController<void> refreshController) async {
    final reviewsService = context.read<ReviewsService>();
    final ordersService = context.read<OrdersService>();
    final canReview = await reviewsService.canReviewOrder(user.id, order.id);
    if (!context.mounted) return;
    if (!canReview) return;

    String? productId = order.productId;
    String? productName = order.productName;

    // Multi-item porudzbine nemaju product_id na order-u, pa uzimamo prvu stavku.
    if (productId == null ||
        productName == null ||
        productName.trim().isEmpty) {
      final items = await ordersService.getOrderItems(order.id);
      if (items.isNotEmpty) {
        productId = items.first.productId;
        productName = items.first.productName;
      }
    }

    if (!context.mounted) return;
    if (productId == null ||
        productName == null ||
        productName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nije moguće ostaviti recenziju za ovu porudžbinu.')),
      );
      return;
    }

    final resolvedProductId = productId;
    final resolvedProductName = productName;

    await showDialog(
      context: context,
      builder: (ctx) => AddReviewDialog(
        buyerId: user.id,
        sellerId: order.sellerId,
        productId: resolvedProductId,
        orderId: order.id,
        productName: resolvedProductName,
        onSubmitted: () => refreshController.add(null),
      ),
    );
  }
}

class _OrdersSidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrdersSidebarTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: selected ? colorScheme.primary : null),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BySellerTab extends StatefulWidget {
  final String userId;
  final VoidCallback onRefresh;

  const _BySellerTab({required this.userId, required this.onRefresh});

  @override
  State<_BySellerTab> createState() => _BySellerTabState();
}

class _BySellerTabState extends State<_BySellerTab> {
  Future<List<BuyerSellerStats>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<OrdersService>().getOrdersByBuyerForSellerStats(widget.userId);
  }

  void _refresh() {
    setState(() {
      _future = context.read<OrdersService>().getOrdersByBuyerForSellerStats(widget.userId);
    });
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BuyerSellerStats>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const OrderListSkeleton();
        }
        if (snap.hasError) {
          return AppErrorRetry(
            message: 'Greška pri učitavanju porudžbina.',
            detail: snap.error?.toString(),
            onRetry: _refresh,
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 220,
                ),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.store_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Još nema porudžbina po prodavcima.',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kada počneš da poručuješ, ovde ćeš videti koliko često kupuješ kod svakog prodavca.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.search),
                          label: const Text('Istraži proizvode'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _SellerStatsCard(
              stats: list[i],
              onReorder: () => _reorder(context, list[i]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _reorder(BuildContext context, BuyerSellerStats stats) async {
    try {
      final items = await context.read<OrdersService>().getOrderItems(stats.lastOrderId);
      if (items.isEmpty || !context.mounted) return;
      await context
          .read<CartProvider>()
          .setOrderItemsForSeller(stats.sellerId, items);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Porudžbina dodata u korpu. Možete izmeniti količine u korpi.'),
        ),
      );
      context.push('/checkout-seller/${stats.sellerId}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _SellerStatsCard extends StatelessWidget {
  final BuyerSellerStats stats;
  final VoidCallback onReorder;

  const _SellerStatsCard({required this.stats, required this.onReorder});

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

class _BuyerOrderCard extends StatelessWidget {
  final OrderModel order;
  final dynamic user;
  final StreamController<void> refreshController;
  final bool isArchived;

  const _BuyerOrderCard({
    required this.order,
    required this.user,
    required this.refreshController,
    this.isArchived = false,
  });

  Future<void> _archiveOrder(BuildContext context) async {
    final ordersService = context.read<OrdersService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arhiviraj porudžbinu?'),
        content: const Text(
          'Arhivirana porudžbina više neće biti u aktivnim porudžbinama.',
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

    await ordersService.archiveOrderByBuyer(
      user.id as String,
      order.id,
    );
    refreshController.add(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Porudžbina je arhivirana.')),
    );
  }

  Future<void> _confirmReceipt(BuildContext context) async {
    final ordersService = context.read<OrdersService>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda prijema'),
        content: const Text(
          'Da li potvrđujete da ste primili porudžbinu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Da, primio/la sam'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await ordersService.confirmOrderReceivedByBuyer(order.id);
    refreshController.add(null);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prijem porudžbine je potvrđen.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    // counterpartyName je batch-učitan u servisu — nema N+1 FutureBuilder
    final sellerName = o.counterpartyName ?? 'Prodavac';
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
                    onTap: () => context.push('/seller/${o.sellerId}'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sellerName,
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
                        'Porudžbina je poslata – čeka se odgovor prodavca.',
                      OrderStatus.accepted =>
                        'Prodavac je prihvatio porudžbinu – čeka slanje.',
                      OrderStatus.shipped =>
                        'Prodavac je poslao porudžbinu – nakon isporuke potvrdi prijem.',
                      OrderStatus.delivered =>
                        'Porudžbina je isporučena – možeš da je arhiviraš i ostaviš recenziju.',
                      OrderStatus.rejected => 'Prodavac je odbio porudžbinu.',
                      OrderStatus.cancelledBySeller =>
                        'Prodavac je otkazao porudžbinu.',
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
                      Expanded(
                        child: Text(
                          o.status == OrderStatus.delivered
                              ? 'Porudžbina je isporučena'
                              : o.status == OrderStatus.shipped
                                  ? 'Prodavac je označio porudžbinu kao poslatu'
                                  : 'Prodavac je potvrdio porudžbinu',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (o.status == OrderStatus.cancelledBySeller)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cancel,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prodavac je otkazao porudžbinu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            if (o.cancellationReason != null &&
                                o.cancellationReason!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                o.cancellationReason!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade900),
                              ),
                            ],
                          ],
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
              _OrderItemsSection(orderId: o.id)
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
            if (o.totalAmount != null)
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Ukupno',
                value: formatRsdAmount(o.totalAmount) ?? '',
              ),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Datum',
              value: DateFormat('dd.MM.yyyy. HH:mm', 'sr').format(o.createdAt),
            ),
            if (!o.hasSellerDelivery)
              _DetailRow(
                icon: switch (o.deliveryMethod) {
                  DeliveryMethod.courier => Icons.local_shipping,
                  DeliveryMethod.pickup => Icons.store,
                  _ => Icons.handshake,
                },
                label: 'Dostava',
                value: o.deliveryMethodLabel,
              ),
            if (o.buyerAddress != null && o.buyerAddress!.isNotEmpty)
              _DetailRow(
                  icon: Icons.location_on,
                  label: 'Adresa',
                  value: o.buyerAddress!),
            if (o.buyerCity.isNotEmpty)
              _DetailRow(
                  icon: Icons.location_city,
                  label: 'Grad',
                  value: o.buyerCity),
            if (o.hasSellerDelivery) OrderDeliverySummary(order: o),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final convId =
                          await context.read<ChatService>().getOrCreateConversation(
                        user.id,
                        o.sellerId,
                        orderId: o.id,
                      );
                      if (context.mounted) context.push('/chat/$convId');
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(friendlyError(e)),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Poruka prodavcu'),
                ),
                if (o.status == OrderStatus.delivered ||
                    o.status == OrderStatus.archived)
                  _CanReviewOrderButton(
                    key: ValueKey('canreview-${o.id}'),
                    userId: user.id,
                    order: o,
                    onPressed: () => _OrdersScreenState._maybeShowReview(
                        context, user, o, refreshController),
                  ),
                if (!isArchived && o.status == OrderStatus.shipped)
                  FilledButton.icon(
                    onPressed: () => _confirmReceipt(context),
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Potvrdi prijem'),
                  ),
                if (!isArchived && o.canBuyerManuallyArchive)
                  FilledButton.tonalIcon(
                    onPressed: () => _archiveOrder(context),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Arhiviraj'),
                  ),
              ],
            ),
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

class _OrderItemsSection extends StatelessWidget {
  final String orderId;

  const _OrderItemsSection({required this.orderId});

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

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
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
        ],
      ),
    );
  }
}

class _CanReviewOrderButton extends StatefulWidget {
  final String userId;
  final OrderModel order;
  final VoidCallback onPressed;

  const _CanReviewOrderButton({
    super.key,
    required this.userId,
    required this.order,
    required this.onPressed,
  });

  @override
  State<_CanReviewOrderButton> createState() => _CanReviewOrderButtonState();
}

class _CanReviewOrderButtonState extends State<_CanReviewOrderButton> {
  Future<bool>? _canReviewFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _canReviewFuture ??= context.read<ReviewsService>().canReviewOrder(widget.userId, widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canReviewFuture,
      builder: (ctx, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.star_outline, size: 20),
          label: const Text('Ostavi recenziju'),
          onPressed: widget.onPressed,
        );
      },
    );
  }
}
