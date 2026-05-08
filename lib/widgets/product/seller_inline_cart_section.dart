import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/haptic.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';

class SellerInlineCartSection extends StatelessWidget {
  final String sellerId;

  const SellerInlineCartSection({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest || user.id == sellerId) {
      return const SizedBox.shrink();
    }

    final cart = context.read<CartProvider>();
    return Selector<CartProvider, String>(
      selector: (_, c) {
        final draft = c.getSellerDraft(sellerId);
        if (draft.isEmpty) return '';
        final entries = draft.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        // Stabilan fingerprint: rebuild samo kad se stvarno promeni draft ovog prodavca.
        return entries.map((e) => '${e.key}:${e.value}').join('|');
      },
      builder: (context, draftKey, _) {
        if (draftKey.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<({ProductModel product, double quantity})>>(
          future: cart.getProductsBySeller(sellerId),
          builder: (context, snap) {
            final items = snap.data ?? [];
            if (items.isEmpty) return const SizedBox.shrink();

            final total = items.fold<double>(
              0,
              (sum, e) => sum + e.product.pricePerKg * e.quantity,
            );

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tvoja korpa kod ovog domaćinstva',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...items.take(3).map((e) {
                    final p = e.product;
                    final step = p.quantityStep;
                    final minQty = p.minOrderKg;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.formatQuantity(e.quantity),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Smanji količinu',
                            icon: const Icon(Icons.remove, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: e.quantity <= minQty
                                ? null
                                : () {
                                    AppHaptics.selection();
                                    final next = e.quantity - step;
                                    if (next < minQty) return;
                                    cart.setQuantityForSeller(
                                      sellerId: sellerId,
                                      productId: p.id,
                                      quantity: next,
                                    );
                                  },
                          ),
                          IconButton(
                            tooltip: 'Povećaj količinu',
                            icon: const Icon(Icons.add, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              AppHaptics.selection();
                              final next = e.quantity + step;
                              cart.setQuantityForSeller(
                                sellerId: sellerId,
                                productId: p.id,
                                quantity: next,
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Ukloni iz korpe',
                            icon: const Icon(Icons.close, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              cart.removeFromSeller(
                                sellerId: sellerId,
                                productId: p.id,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  if (items.length > 3)
                    Text(
                      '+${items.length - 3} proizvoda',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Ukupno za proizvode: ${total.toStringAsFixed(0)} RSD + dostava',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.push('/checkout-seller/$sellerId'),
                    child: const Text('Pošalji porudžbinu prodavcu'),
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
