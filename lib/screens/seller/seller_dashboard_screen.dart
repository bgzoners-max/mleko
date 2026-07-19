import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../../widgets/app_error_retry.dart';
import '../../widgets/seller_product_card.dart';
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
    final user = context.read<AppState>().user;
    if (user != null) {
      setState(() {
        _statsFuture = context.read<OrdersService>().getSellerStats(user.id);
      });
    }
    _refreshController.add(null);
    // Mala pauza za bolji UX (prikaz spinner-a)
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
    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moji proizvodi'),
        actions: isTwoPaneLayout
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Dodaj novi proizvod',
                  onPressed: goToAddProduct,
                ),
              ],
      ),
      floatingActionButton: isTwoPaneLayout
          ? null
          : FloatingActionButton.extended(
              onPressed: goToAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj proizvod'),
            ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                isTwoPaneLayout ? Breakpoints.dataContentWidth(context) : 800,
          ),
          child: isTwoPaneLayout
              ? _buildDesktopLayout(context)
              : _buildMobileLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final productsService = context.read<ProductsService>();
    return Column(
      children: [
        FutureBuilder<SellerStats>(
          future: _statsFuture,
          builder: (context, statsSnap) {
            final stats = statsSnap.data;
            if (stats == null) return const SizedBox.shrink();
            return Column(
              children: [
                Card(
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
                            label: 'Ukupno',
                            value: '${stats.totalCount}',
                            icon: Icons.receipt_long),
                        _StatItem(
                            label: 'Prihod',
                            value: '${stats.revenue.toStringAsFixed(0)} RSD',
                            icon: Icons.monetization_on),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.2),
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
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Brojke prikazuju stanje vaših proizvoda i zahteve kupaca. „Dodaj proizvod“ otvara formu za novu ponudu.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        minHeight: MediaQuery.of(context).size.height - 300,
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
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Dodajte prvi proizvod da počnete da se pojavljujete kupcima.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => context.go('/add-product'),
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
                    return SellerProductCard(
                      product: list[i],
                      productsService: productsService,
                      onRefresh: () => _refreshController.add(null),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final productsService = context.read<ProductsService>();
    final sidebarWidth = Breakpoints.desktopSidebarWidth(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar sa statistikom i brzim akcijama
        SizedBox(
          width: sidebarWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistika prodaje',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<SellerStats>(
                          future: _statsFuture,
                          builder: (context, snap) {
                            if (!snap.hasData) {
                              return const LinearProgressIndicator();
                            }
                            final s = snap.data!;
                            return Column(
                              children: [
                                _SidebarStatRow(
                                  label: 'Na čekanju',
                                  value: '${s.pendingCount}',
                                  icon: Icons.pending_actions,
                                ),
                                const Divider(height: 24),
                                _SidebarStatRow(
                                  label: 'Ukupno',
                                  value: '${s.totalCount}',
                                  icon: Icons.receipt_long,
                                ),
                                const Divider(height: 24),
                                _SidebarStatRow(
                                  label: 'Prihod',
                                  value: '${s.revenue.toStringAsFixed(0)} RSD',
                                  icon: Icons.monetization_on,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dodavanje proizvoda odmah ga čini vidljivim kupcima i otvara novu ponudu.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/add-product'),
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj novi proizvod'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Glavna lista proizvoda
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return AppErrorRetry(
                  message: 'Greška pri učitavanju proizvoda.',
                  onRetry: _onRefresh,
                );
              }
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const SellerProductListSkeleton();
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return const Center(child: Text('Nema proizvoda.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  return SellerProductCard(
                    product: list[i],
                    productsService: productsService,
                    onRefresh: () => _refreshController.add(null),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SidebarStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SidebarStatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
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
