import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product_model.dart';
import '../services/services.dart';
import 'app_network_image.dart';

class SellerProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRefresh;
  final ProductsService productsService;

  const SellerProductCard({
    super.key,
    required this.product,
    required this.onRefresh,
    required this.productsService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.imageUrls.isNotEmpty
              ? AppNetworkImage.thumbnail(
                  imageUrl: product.imageUrls.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${product.priceFormatted} · ${product.location}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Dostupno', style: TextStyle(fontSize: 10)),
                Switch(
                  value: product.availableNow,
                  onChanged: (v) async {
                    await productsService.updateAvailableNow(product.id, v);
                    onRefresh();
                  },
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/product/edit/${product.id}'),
              tooltip: 'Izmeni proizvod',
            ),
          ],
        ),
        onTap: () => context.push('/product/${product.id}'),
      ),
    );
  }
}
