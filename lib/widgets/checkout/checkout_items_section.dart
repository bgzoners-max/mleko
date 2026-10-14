import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import 'checkout_item_card.dart';

/// Prikaz liste artikala i praznog stanja u Checkout formi.
class CheckoutItemsSection extends StatelessWidget {
  final String sellerId;
  final List<({ProductModel product, double quantity})> items;
  final GlobalKey<AnimatedListState> listKey;
  final bool hasSellerDeliveryOptions;
  final void Function(int index, double quantity) onQuantityChanged;
  final void Function(int index) onRemove;

  const CheckoutItemsSection({
    super.key,
    required this.sellerId,
    required this.items,
    required this.listKey,
    required this.hasSellerDeliveryOptions,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  static String formatTotalQuantity(
      List<({ProductModel product, double quantity})> items) {
    double totalKg = 0;
    double totalL = 0;
    double totalGkg = 0;
    double totalPieces = 0;
    double totalVeza = 0;
    double totalPak = 0;

    for (final e in items) {
      final p = e.product;
      switch (p.unitType) {
        case ProductModel.unitL:
          totalL += e.quantity;
          break;
        case ProductModel.unitG:
          totalGkg += e.quantity;
          break;
        case ProductModel.unitPiece:
          totalPieces += e.quantity;
          break;
        case ProductModel.unitVeza:
          totalVeza += e.quantity;
          break;
        case ProductModel.unitPak:
          totalPak += e.quantity;
          break;
        default:
          totalKg += e.quantity;
      }
    }

    final parts = <String>[];
    if (totalKg > 0) {
      parts.add(
          ProductModel.formatQuantityWithUnit(totalKg, ProductModel.unitKg));
    }
    if (totalL > 0) {
      parts
          .add(ProductModel.formatQuantityWithUnit(totalL, ProductModel.unitL));
    }
    if (totalGkg > 0) {
      parts.add(
          ProductModel.formatQuantityWithUnit(totalGkg, ProductModel.unitG));
    }
    if (totalPieces > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalPieces, ProductModel.unitPiece));
    }
    if (totalVeza > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalVeza, ProductModel.unitVeza));
    }
    if (totalPak > 0) {
      parts.add(ProductModel.formatQuantityWithUnit(
          totalPak, ProductModel.unitPak));
    }
    if (parts.isEmpty) return '';
    return 'Ukupno količina: ${parts.join(' + ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Nema stavki. Dodaj proizvode kod prodavca.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/seller/$sellerId'),
              icon: const Icon(Icons.store, size: 20),
              label: const Text('Nazad kod prodavca'),
            ),
          ],
        ),
      );
    }

    final totalQuantityLabel = formatTotalQuantity(items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedList(
          key: listKey,
          initialItemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index, animation) {
            return CheckoutItemCard(
              item: items[index],
              animation: animation,
              onQuantityChanged: (q) => onQuantityChanged(index, q),
              onRemove: () => onRemove(index),
            );
          },
        ),
        const SizedBox(height: 8),
        if (totalQuantityLabel.isNotEmpty)
          Text(
            totalQuantityLabel,
            style:
                theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        Text(
          hasSellerDeliveryOptions
              ? 'Prodavac nudi i ličnu dostavu na izabranim lokacijama i terminima.'
              : 'Napomena: Cena dostave se dogovara sa domaćinom.',
          style:
              theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
