import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../core/haptic.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import 'cart_item_tile.dart';

class CartSellerGroupCard extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String location;
  final List<({ProductModel product, double quantity})> items;
  final double? minOrder;
  final VoidCallback onRefresh;

  const CartSellerGroupCard({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.location,
    required this.items,
    this.minOrder,
    required this.onRefresh,
  });

  @override
  State<CartSellerGroupCard> createState() => _CartSellerGroupCardState();
}

class _CartSellerGroupCardState extends State<CartSellerGroupCard> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<({ProductModel product, double quantity})> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(CartSellerGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != _currentItems.length) {
      _currentItems = List.from(widget.items);
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _currentItems[index];
    final sellerId = widget.sellerId;

    unawaited(AppHaptics.light());
    await context.read<CartProvider>().removeFromSeller(
          sellerId: sellerId,
          productId: item.product.id,
        );

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(
          opacity: animation,
          child: CartItemTile(item: item, sellerId: sellerId, onRemove: () {}),
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    setState(() {
      _currentItems.removeAt(index);
    });

    widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.fold<double>(
        0, (sum, item) => sum + (item.product.pricePerKg * item.quantity));
    final progress = widget.minOrder != null
        ? (total / widget.minOrder!).clamp(0.0, 1.0)
        : 1.0;
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.location,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
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
          if (widget.minOrder != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDesign.spaceL,
                  AppDesign.spaceL, AppDesign.spaceL, AppDesign.spaceS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isMet ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMet
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMet
                              ? Icons.check_circle_outline
                              : Icons.info_outline,
                          size: 16,
                          color: isMet
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMet
                                ? 'Minimalni iznos je dostignut. Možeš nastaviti sa porudžbinom.'
                                : 'Još ti fali ${remaining.toStringAsFixed(0)} RSD da dostigneš minimum za ovu porudžbinu.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isMet
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMet
                            ? 'Ispunjen minimum za porudžbinu'
                            : 'Do minimuma za porudžbinu:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isMet
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                      if (!isMet)
                        Text(
                          'još ${remaining.toStringAsFixed(0)} RSD',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800),
                        ),
                    ],
                  ),
                  AppDesign.boxS,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isMet ? Colors.green : Colors.orange),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesign.spaceL, 0, AppDesign.spaceL, AppDesign.spaceS),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.18),
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
                      'Minimum označava najmanji iznos za jednu porudžbinu. Kad dostigneš cilj, dugme „Naruči“ postaje dostupno za nastavak.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppDesign.spaceL),
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
                  child: CartItemTile(
                    item: item,
                    sellerId: widget.sellerId,
                    onRemove: () => _removeItem(index),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: AppDesign.paddingL,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ukupno:',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text(
                      '${total.toStringAsFixed(0)} RSD',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _goToCheckOut(context),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Naruči'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
    final quantities = {
      for (var item in widget.items) item.product.id: item.quantity
    };
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
        content: Text(
            'Svi proizvodi od prodavca "${widget.sellerName}" će biti uklonjeni.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ukloni')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CartProvider>().clearSeller(widget.sellerId);
      widget.onRefresh();
    }
  }
}
