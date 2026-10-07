import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../../services/orders/order_services.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_error_retry.dart';
import '../../widgets/seller/seller_order_card.dart';
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
      : 'archived';
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
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Porudžbine'),
          actions: const [AppHomeButton()],
        ),
        body: const Center(child: Text('Samo za prodavce.')),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Porudžbine'),
              actions: const [AppHomeButton()],
            )
          : null,
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
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isArchive
                                ? 'Ovde su porudžbine koje ste ručno arhivirali. Arhivirane porudžbine se automatski brišu iz sistema nakon 12 meseci.'
                                : 'Aktivne porudžbine (bez arhive). Kada kupac pošalje zahtev, vi odlučujete da li ćete ga prihvatiti, poslati ili odbiti.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
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
                                  'Ista porudžbina može biti arhivirana i od kupca i od vas; ovde vidite samo vašu arhivu. Arhivirane porudžbine se automatski brišu nakon 12 meseci.',
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
                            return SellerOrderCard(
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
