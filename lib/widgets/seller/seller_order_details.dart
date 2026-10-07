import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_item_model.dart';
import '../../models/product_model.dart';
import '../../services/orders/order_services.dart';

/// Status bedž porudžbine prodavca.
class SellerOrderStatusChip extends StatelessWidget {
  final String label;

  const SellerOrderStatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Na čekanju' => Colors.orange,
      'Poslato' => Colors.teal,
      'Prihvaćeno' => Colors.blue,
      'Odbijeno' => Colors.red,
      'Isporučeno' => Colors.green,
      'Otkazano' => Colors.grey,
      'Arhivirano' => Colors.brown,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}

/// Jedan red detalja porudžbine (adresa, grad, telefon...).
class SellerOrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const SellerOrderDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Stavke porudžbine (lazy load po orderId).
class SellerOrderItemsSection extends StatelessWidget {
  final String orderId;

  const SellerOrderItemsSection({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderItemModel>>(
      future: context.read<OrdersService>().getOrderItems(orderId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!;
        final totalLabel = OrderItemModel.totalQuantityLabel(items);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (totalLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  totalLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                ),
              ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.inventory_2,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName,
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text(
                            ProductModel.formatQuantityWithUnit(
                                item.quantityKg, item.unitType),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
