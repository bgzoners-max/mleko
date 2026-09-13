import 'package:flutter/material.dart';

import '../../core/design_system.dart';
import '../../models/product_model.dart';
import '../app_network_image.dart';

class CartItemTile extends StatelessWidget {
  final ({ProductModel product, double quantity}) item;
  final String sellerId;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.sellerId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spaceL, vertical: AppDesign.spaceS),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppNetworkImage.icon(
              imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : '',
              width: 50,
              height: 50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
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
            icon: const Icon(Icons.remove_circle_outline,
                size: 20, color: Colors.grey),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
