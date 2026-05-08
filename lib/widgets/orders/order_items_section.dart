import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_item_model.dart';
import '../../models/product_model.dart';
import 'package:mleko/services/services.dart';

class OrderItemsSection extends StatelessWidget {
  final String orderId;

  const OrderItemsSection({super.key, required this.orderId});

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
            if (totalLabel.isNotEmpty) ...[
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
            ],
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
                                  fontSize: 12, color: Colors.grey.shade600)),
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
