import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/product_card.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Map<String, List<({dynamic product, double quantity})>>? _lastGrouped;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Porudžbine po prodavcu'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Isprazni korpu?'),
                    content: const Text('Svi proizvodi će biti uklonjeni iz nacrta porudžbine.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Odustani'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Isprazni'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await cart.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nacrt porudžbine je ispražnjena.')));
                  }
                }
              },
              child: const Text('Isprazni sve'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Korpa je prazna',
              subtitle: 'Dodajte proizvode sa stranice prodavca ili sa detalja proizvoda, pa pošaljite upit.',
              ctaLabel: 'Pretraži proizvode',
              ctaIcon: Icons.search,
              onCtaPressed: () => context.go('/'),
            )
          : FutureBuilder<Map<String, List<({dynamic product, double quantity})>>>(
              future: cart.getProductsGroupedBySeller(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return AppErrorRetry(
                    message: 'Greška pri učitavanju korpe.',
                    detail: snap.error?.toString(),
                    onRetry: () => setState(() {}),
                  );
                }
                if (snap.hasData) _lastGrouped = snap.data;
                final grouped = snap.data ?? _lastGrouped;
                if (grouped == null) return const Center(child: CircularProgressIndicator());
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    final sellerId = entry.key;
                    final items = entry.value;
                    return _CartSellerGroup(
                      sellerId: sellerId,
                      items: items,
                      cart: cart,
                      onCheckoutOne: (item) => context.push('/checkout/${item.product.id}', extra: {'quantity': item.quantity}),
                      onCheckoutAll: () => context.push('/checkout-seller/$sellerId'),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }
}

class _CartSellerGroup extends StatelessWidget {
  final String sellerId;
  final List<({dynamic product, double quantity})> items;
  final CartProvider cart;
  final void Function(({dynamic product, double quantity}) item) onCheckoutOne;
  final VoidCallback onCheckoutAll;

  const _CartSellerGroup({
    required this.sellerId,
    required this.items,
    required this.cart,
    required this.onCheckoutOne,
    required this.onCheckoutAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = items.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMultiple)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.store, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${items.length} proizvoda od istog prodavca',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CartItemCard(
                product: item.product,
                quantity: item.quantity,
                onQuantityChanged: (qty) => cart.setQuantityForSeller(
                  sellerId: sellerId,
                  productId: item.product.id,
                  quantity: qty,
                ),
                onRemove: () => cart.removeFromSeller(
                  sellerId: sellerId,
                  productId: item.product.id,
                ),
                onCheckout: hasMultiple ? null : () => onCheckoutOne(item),
              ),
            )),
        if (hasMultiple)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: items.any((i) => !(i.product as dynamic).isAvailable)
                    ? null
                    : onCheckoutAll,
                icon: const Icon(Icons.send, size: 20),
                label: Text(
                  items.any((i) => !(i.product as dynamic).isAvailable)
                      ? 'Neki proizvodi su nedostupni'
                      : 'Pošalji upit za sve (${items.length} proizvoda)',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final dynamic product;
  final double quantity;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onCheckout;

  const _CartItemCard({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onCheckout,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.quantity.toStringAsFixed(widget.quantity.truncateToDouble() == widget.quantity ? 0 : 1));
  }

  @override
  void didUpdateWidget(_CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _qtyController.text = widget.quantity.toStringAsFixed(widget.quantity.truncateToDouble() == widget.quantity ? 0 : 1);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final minQty = p.minOrderKg;
    final step = p.quantityStep;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!p.isAvailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Text('Nedostupno', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange.shade800)),
                    ],
                  ),
                ),
              ),
            Builder(
              builder: (ctx) {
                final user = ctx.watch<AppState>().user;
                final canFavorite = user != null && !user.isGuest;
                if (!canFavorite) {
                  return ProductCard(
                    product: p,
                    isFavorite: null,
                    onFavoriteToggle: null,
                  );
                }
                return Selector<FavoritesProvider, bool>(
                  selector: (_, fav) => fav.isFavorite(p.id),
                  builder: (_, isFavorite, __) {
                    final favorites = ctx.read<FavoritesProvider>();
                    return ProductCard(
                      product: p,
                      isFavorite: isFavorite,
                      onFavoriteToggle: () => favorites.toggle(user.id, p.id),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.scale, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text('Količina (${p.quantityUnitLabel}):', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filled(
                  onPressed: () {
                    final next = widget.quantity - step;
                    if (next < minQty) return;
                    widget.onQuantityChanged(next);
                  },
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: p.quantityUnitLabel,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (v) {
                      final qty = double.tryParse(v.replaceAll(',', '.'));
                      if (qty != null && qty >= minQty) {
                        widget.onQuantityChanged(qty);
                      } else {
                        _qtyController.text = widget.quantity.toStringAsFixed(1);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final newQty = widget.quantity + step;
                    widget.onQuantityChanged(newQty);
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Ukloni'),
                ),
                if (widget.onCheckout != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: p.isAvailable ? widget.onCheckout : null,
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(p.isAvailable ? 'Pošalji upit' : 'Nedostupno'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
