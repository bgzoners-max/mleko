import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design_system.dart';
import '../core/responsive.dart';
import '../models/order_model.dart';
import '../providers/app_state.dart';
import '../services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/skeleton.dart';

import '../widgets/orders/buyer_order_card.dart';
import '../widgets/orders/by_seller_tab.dart';
import '../widgets/orders/orders_sidebar_tile.dart';

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
                  OrdersSidebarTile(
                    icon: Icons.receipt_long,
                    label: 'U toku',
                    selected: _segmentIndex == 0,
                    onTap: () => _selectSegment(0),
                  ),
                  const SizedBox(height: 8),
                  OrdersSidebarTile(
                    icon: Icons.archive_outlined,
                    label: 'Arhiva',
                    selected: _segmentIndex == 1,
                    onTap: () => _selectSegment(1),
                  ),
                  const SizedBox(height: 8),
                  OrdersSidebarTile(
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
      return BySellerTab(userId: userId, onRefresh: _onRefresh);
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
          return AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: _isArchive
                ? 'Još nema arhiviranih porudžbina.'
                : 'Još nema porudžbina.',
            subtitle: _isArchive
                ? 'Kada ručno arhivirate porudžbinu, pojaviće se ovde.'
                : 'Kreni od pregleda proizvoda i pošalji prvu porudžbinu.',
            ctaLabel: _isArchive ? null : 'Pronađi proizvode',
            onCtaPressed: _isArchive ? null : () => context.go('/'),
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
              return BuyerOrderCard(
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
}
