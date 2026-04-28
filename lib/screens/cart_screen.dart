import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/seller_delivery_models.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_network_image.dart';
import '../widgets/skeleton.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  Map<String, List<({ProductModel product, double quantity})>> _groupedItems = {};
  Map<String, UserModel> _sellerProfiles = {};
  Map<String, double> _sellerMinimums = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cart = context.read<CartProvider>();
    final grouped = await cart.getProductsGroupedBySeller();
    if (!mounted) return;

    if (grouped.isEmpty) {
      setState(() {
        _groupedItems = {};
        _loading = false;
      });
      return;
    }

    final sellerIds = grouped.keys.toList();
    final usersService = context.read<UsersService>();
    final deliveryService = SellerDeliveryService();

    try {
      final profiles = await usersService.getUsers(sellerIds);
      final profilesMap = {for (var p in profiles) p.id: p};

      final minsMap = <String, double>{};
      for (final sid in sellerIds) {
        final points = await deliveryService.getSellerDeliveryPoints(sid, onlyActive: true);
        double? minOrder;
        for (final p in points) {
          for (final s in p.activeSlots) {
            if (s.minOrderAmountRsd != null) {
              if (minOrder == null || s.minOrderAmountRsd! < minOrder) {
                minOrder = s.minOrderAmountRsd;
              }
            }
          }
        }
        if (minOrder != null) minsMap[sid] = minOrder;
      }

      if (!mounted) return;
      setState(() {
        _groupedItems = grouped;
        _sellerProfiles = profilesMap;
        _sellerMinimums = minsMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Silently fail for profiles, they will just show ID or placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    // If cart count changes, we might need to refresh grouped items
    // but getProductsGroupedBySeller has internal cache.
    // However, if a seller is removed completely, we should re-fetch.
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Korpa'),
        actions: [
          if (!_loading && _groupedItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Isprazni korpu?'),
                    content: const Text('Svi proizvodi će biti uklonjeni iz korpe.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Isprazni')),
                    ],
                  ),
                );
                if (ok == true) {
                  await cart.clear();
                  _loadData();
                }
              },
              child: const Text('Isprazni'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groupedItems.isEmpty
              ? _buildEmptyState()
              : _buildCartList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Vaša korpa je prazna',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Istraži proizvode'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    final isWide = Breakpoints.useTwoPaneLayout(context);
    final sellerIds = _groupedItems.keys.toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sellerIds.length,
          itemBuilder: (context, index) {
            final sellerId = sellerIds[index];
            final items = _groupedItems[sellerId] ?? [];
            final profile = _sellerProfiles[sellerId];
            final minOrder = _sellerMinimums[sellerId];
            
            return _SellerCartCard(
              sellerId: sellerId,
              sellerName: profile?.farmName ?? profile?.displayName ?? 'Prodavac',
              location: profile?.city ?? 'Nepoznata lokacija',
              items: items,
              minOrder: minOrder,
              onRefresh: _loadData,
            );
          },
        ),
      ),
    );
  }
}

class _SellerCartCard extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String location;
  final List<({ProductModel product, double quantity})> items;
  final double? minOrder;
  final VoidCallback onRefresh;

  const _SellerCartCard({
    required this.sellerId,
    required this.sellerName,
    required this.location,
    required this.items,
    this.minOrder,
    required this.onRefresh,
  });

  @override
  State<_SellerCartCard> createState() => _SellerCartCardState();
}

class _SellerCartCardState extends State<_SellerCartCard> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<({ProductModel product, double quantity})> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_SellerCartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ako se lista promenila spolja (npr. refresh), osveži lokalno stanje
    // Ali AnimatedList zahteva pažljivo rukovanje ako želimo animacije pri eksternim promenama.
    // Za sada samo sinhronizujemo ako su dužine različite bez animacije ovde.
    if (widget.items.length != _currentItems.length) {
      _currentItems = List.from(widget.items);
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _currentItems[index];
    final sellerId = widget.sellerId;
    
    // 1. Pozovi provider da ukloni iz baze/state-a
    await context.read<CartProvider>().removeFromSeller(
      sellerId: sellerId,
      productId: item.product.id,
    );

    // 2. Animacija uklanjanja
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: _CartItemTile(item: item, sellerId: sellerId, onRemove: () {}),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    // 3. Ažuriraj lokalnu listu
    setState(() {
      _currentItems.removeAt(index);
    });

    // 4. Obavesti roditelja da osveži ukupne vrednosti i minimum
    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(0, (sum, item) => sum + (item.product.pricePerKg * item.quantity));
    final progress = widget.minOrder != null ? (total / widget.minOrder!).clamp(0.0, 1.0) : 1.0;
    final remaining = widget.minOrder != null ? widget.minOrder! - total : 0.0;
    final isMet = remaining <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sellerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmClearSeller(context),
                  tooltip: 'Ukloni sve od ovog prodavca',
                ),
              ],
            ),
          ),

          // Progress Bar
          if (widget.minOrder != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMet ? 'Ispunjen minimum za porudžbinu' : 'Do minimuma za porudžbinu:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMet ? Colors.green.shade700 : Colors.orange.shade800,
                        ),
                      ),
                      if (!isMet)
                        Text(
                          'još ${remaining.toStringAsFixed(0)} RSD',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(isMet ? Colors.green : Colors.orange),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Minimalna porudžbina: ${widget.minOrder!.toStringAsFixed(0)} RSD',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

          const Divider(height: 32),

          // Items (AnimatedList)
          AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: _currentItems.length,
            itemBuilder: (context, index, animation) {
              if (index >= _currentItems.length) return const SizedBox.shrink();
              final item = _currentItems[index];
              return FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: _CartItemTile(
                    item: item,
                    sellerId: widget.sellerId,
                    onRemove: () => _removeItem(index),
                  ),
                ),
              );
            },
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ukupno:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(
                      '${total.toStringAsFixed(0)} RSD',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _goToCheckOut(context),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Naruči'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToCheckOut(BuildContext context) {
    final quantities = {for (var item in widget.items) item.product.id: item.quantity};
    context.push(
      '/checkout-seller/${widget.sellerId}',
      extra: {'productQuantities': quantities},
    );
  }

  Future<void> _confirmClearSeller(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukloni proizvode?'),
        content: Text('Svi proizvodi od prodavca "${widget.sellerName}" će biti uklonjeni.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ukloni')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CartProvider>().clearSeller(widget.sellerId);
      widget.onRefresh();
    }
  }
}

class _CartItemTile extends StatelessWidget {
  final ({ProductModel product, double quantity}) item;
  final String sellerId;
  final VoidCallback onRemove;

  const _CartItemTile({required this.item, required this.sellerId, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppNetworkImage(
              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${p.priceFormatted} × ${p.formatQuantity(item.quantity)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${(p.pricePerKg * item.quantity).toStringAsFixed(0)} RSD',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
