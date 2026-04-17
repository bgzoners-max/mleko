import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../../widgets/app_error_retry.dart';
import '../../widgets/skeleton.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final _refreshController = StreamController<void>.broadcast();

  Future<SellerStats>? _statsFuture;
  // Stream se čuva kao polje — sprečava re-kreiranje kanala na svakom buildu.
  Stream<List<ProductModel>>? _productsStream;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && user.isSeller && user.id != _lastUserId) {
      _lastUserId = user.id;
      _statsFuture = context.read<OrdersService>().getSellerStats(user.id);
      _productsStream = context.read<ProductsService>().getProductsBySeller(
        user.id,
        refreshTrigger: _refreshController.stream,
      );
    }
  }

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
        appBar: AppBar(title: const Text('Moji proizvodi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Niste još prodavac.',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Da biste upravljali proizvodima, prvo otvorite svoj prodajni profil.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/becoming-seller'),
                  icon: const Icon(Icons.store_mall_directory_outlined),
                  label: const Text('Postani prodavac'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    void goToAddProduct() => context.go('/add-product');
    final productsService = context.read<ProductsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji proizvodi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj novi proizvod',
            onPressed: goToAddProduct,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: goToAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj proizvod'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    Breakpoints.horizontalPadding(context),
                    12,
                    Breakpoints.horizontalPadding(context),
                    4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Pregled prodaje',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brzi pregled aktivnih porudžbina, ukupnog broja i prihoda.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              FutureBuilder<SellerStats>(
                future: _statsFuture,
                builder: (context, statsSnap) {
                  final stats = statsSnap.data;
                  if (stats == null) return const SizedBox.shrink();
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatItem(
                              label: 'Na čekanju',
                              value: '${stats.pendingCount}',
                              icon: Icons.pending_actions),
                          _StatItem(
                              label: 'Ukupno porudžbina',
                              value: '${stats.totalCount}',
                              icon: Icons.receipt_long),
                          _StatItem(
                              label: 'Prihod',
                              value: '${stats.revenue.toStringAsFixed(0)} RSD',
                              icon: Icons.monetization_on),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: StreamBuilder<List<ProductModel>>(
                  stream: _productsStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return AppErrorRetry(
                        message: 'Greška pri učitavanju proizvoda.',
                        detail: snap.error?.toString(),
                        onRetry: _onRefresh,
                      );
                    }

                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const SellerProductListSkeleton();
                    }

                    final list = snap.data ?? [];

                    if (list.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height - 200,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 80, color: Colors.grey.shade300),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Još nema proizvoda.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dodaj prvi proizvod i pojaviće se u pretrazi kupaca i na tvom prodajnom profilu.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: Colors.grey.shade600),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: goToAddProduct,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Dodaj proizvod'),
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
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final p = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: p.imageUrls.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: p.imageUrls.first,
                                      width: 56,
                                      memCacheWidth: 120,
                                      memCacheHeight: 120,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image_not_supported),
                              title: Text(p.name),
                              subtitle:
                                  Text('${p.priceFormatted} · ${p.location}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Tooltip(
                                    message: p.availableNow
                                        ? 'Dostupno sada – uključeno'
                                        : 'Nedostupno danas – isključeno',
                                    child: Switch(
                                      value: p.availableNow,
                                      onChanged: (v) async {
                                        await productsService
                                            .updateAvailableNow(p.id, v);
                                        _refreshController.add(null);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        context.push('/product/edit/${p.id}'),
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/product/${p.id}'),
                            ),
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
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}
