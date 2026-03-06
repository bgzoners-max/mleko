import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../services/orders_service.dart';
import '../../services/products_service.dart';
import '../../widgets/skeleton.dart';

/// Predefinisane grupe za brzi filter „Danas nemam…” – više internih kategorija pod jednim naslovom.
const _availabilityFilterGroups = <String, List<String>>{
  'Mleko i mlečni proizvodi': ['mleko', 'sir', 'kiselo', 'pavlaka', 'kajmak', 'jogurt', 'vrhnje', 'mlečn', 'kačkavalj', 'sirevi'],
  'Meso i suhomesnato': ['meso', 'suhomesnat', 'šunka', 'kobasica', 'pršut', 'mesn'],
};

bool _productMatchesGroup(ProductModel p, List<String> keywords) {
  final cat = p.category.toLowerCase();
  return keywords.any((k) => cat.contains(k));
}

List<ProductModel> _filterByCategoryOrGroup(
  List<ProductModel> products,
  String? activeFilter,
) {
  if (activeFilter == null || activeFilter.isEmpty) return products;
  if (activeFilter.startsWith('grupa:')) {
    final label = activeFilter.substring(6);
    final keywords = _availabilityFilterGroups[label];
    if (keywords == null) return products;
    return products.where((p) => _productMatchesGroup(p, keywords)).toList();
  }
  return products.where((p) => p.category == activeFilter).toList();
}

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
      _statsFuture = OrdersService().getSellerStats(user.id);
      _productsStream = ProductsService().getProductsBySeller(
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
                Icon(Icons.storefront_outlined, size: 72, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Niste još prodavac.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Da biste upravljali proizvodima, prvo otvorite svoj prodajni profil.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
    final productsService = ProductsService();  // samo za switch toggle

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pregled prodaje',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Brzi pregled aktivnih porudžbina, ukupnog broja i prihoda.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
                      _StatItem(label: 'Na čekanju', value: '${stats.pendingCount}', icon: Icons.pending_actions),
                      _StatItem(label: 'Ukupno porudžbina', value: '${stats.totalCount}', icon: Icons.receipt_long),
                      _StatItem(label: 'Prihod', value: '${stats.revenue.toStringAsFixed(0)} RSD', icon: Icons.monetization_on),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      snap.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
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
            );
          }

          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
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
                    minHeight: MediaQuery.of(context).size.height - 200,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 24),
                          Text(
                            'Još nema proizvoda.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Dodaj prvi proizvod i pojaviće se u pretrazi kupaca i na tvojoj stranici proizvođača.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
              itemCount: list.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brzo ažuriranje zaliha',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ako danas nemaš određene proizvode, isključi ih jednom prečicom umesto da ulaziš u svaki proizvod posebno. Ova radnja samo gasi opciju „Dostupno sada“ – sutra je možeš ponovo uključiti.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Tooltip(
                              message: 'Brzo isključi proizvode koje danas nemaš (po kategoriji ili sve odjednom)',
                              child: FilledButton.tonalIcon(
                                onPressed: () => _openQuickAvailabilitySheet(context, list, productsService),
                                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                                label: const Text('Danas nemam…'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final p = list[i - 1];
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
                    subtitle: Text('${p.priceFormatted} · ${p.location}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: p.availableNow ? 'Dostupno sada – uključeno' : 'Nedostupno danas – isključeno',
                          child: Switch(
                            value: p.availableNow,
                            onChanged: (v) async {
                              await productsService.updateAvailableNow(p.id, v);
                              _refreshController.add(null);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => context.push('/product/edit/${p.id}'),
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
    );
  }

  Future<void> _openQuickAvailabilitySheet(
    BuildContext context,
    List<ProductModel> products,
    ProductsService productsService,
  ) async {
    if (products.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final availableProducts = products;
        var selected = <String>{
          for (final p in availableProducts)
            if (p.availableNow) p.id,
        };
        String? activeFilter;
        return StatefulBuilder(
          builder: (ctx, setState) {
            final visibleProducts = _filterByCategoryOrGroup(availableProducts, activeFilter);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Danas nemam…',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Izaberi grupu ili kategoriju, označi proizvode koje danas nemaš – za njih će se isključiti „Dostupno sada“. Kasnije možeš ponovo uključiti po proizvodu.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Sve kategorije'),
                          selected: activeFilter == null,
                          onSelected: (_) => setState(() => activeFilter = null),
                        ),
                        const SizedBox(width: 8),
                        ..._availabilityFilterGroups.entries
                            .where((e) => availableProducts.any((p) => _productMatchesGroup(p, e.value)))
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(e.key),
                                  selected: activeFilter == 'grupa:${e.key}',
                                  onSelected: (_) => setState(() => activeFilter = 'grupa:${e.key}'),
                                ),
                              ),
                            ),
                        ...availableProducts
                            .map((p) => p.category)
                            .toSet()
                            .take(6)
                            .map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: activeFilter == cat,
                                  onSelected: (_) => setState(() => activeFilter = cat),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.5,
                    child: ListView.builder(
                      itemCount: visibleProducts.length,
                      itemBuilder: (_, i) {
                        final p = visibleProducts[i];
                        final isSelected = selected.contains(p.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(p.id);
                              } else {
                                selected.remove(p.id);
                              }
                            });
                          },
                          title: Text(p.name),
                          subtitle: Text(p.category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selected
                              ..clear()
                              ..addAll(visibleProducts.map((p) => p.id));
                          });
                        },
                        child: const Text('Sve u listi'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => selected.clear()),
                        child: const Text('Ništa'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () async {
                                Navigator.of(ctx).pop();
                                for (final id in selected) {
                                  await productsService.updateAvailableNow(id, false);
                                }
                                _refreshController.add(null);
                              },
                        child: const Text('Isključi označene danas'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}
