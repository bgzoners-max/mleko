import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_messages.dart';
import '../../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../app_error_retry.dart';
import '../skeleton.dart';
import 'seller_stats_card.dart';

class BySellerTab extends StatefulWidget {
  final String userId;
  final VoidCallback onRefresh;

  const BySellerTab({super.key, required this.userId, required this.onRefresh});

  @override
  State<BySellerTab> createState() => _BySellerTabState();
}

class _BySellerTabState extends State<BySellerTab> {
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
            itemBuilder: (_, i) => SellerStatsCard(
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
      unawaited(context.push('/checkout-seller/${stats.sellerId}'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }
}
