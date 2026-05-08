import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../services/services.dart';
import '../app_network_image.dart';

class MoreFromSellerSection extends StatefulWidget {
  final ProductModel product;

  const MoreFromSellerSection({super.key, required this.product});

  @override
  State<MoreFromSellerSection> createState() => _MoreFromSellerSectionState();
}

class _MoreFromSellerSectionState extends State<MoreFromSellerSection> {
  bool _expanded = false;
  Stream<List<ProductModel>>? _productsStream;
  String? _lastSellerId;

  void _ensureStream(String sellerId) {
    if (_lastSellerId == sellerId) return;
    _lastSellerId = sellerId;
    _productsStream =
        context.read<ProductsService>().getProductsBySeller(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    _ensureStream(p.sellerId);
    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final all =
            (snap.data ?? []).where((other) => other.id != p.id).toList();
        if (all.isEmpty) return const SizedBox.shrink();

        final visible = _expanded ? all : all.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Još iz ovog domaćinstva',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${all.length})',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: visible
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/product/${item.id}'),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrls.isEmpty
                                  ? Container(
                                      width: 56,
                                      height: 56,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 24,
                                      ),
                                    )
                                  : AppNetworkImage.icon(
                                      imageUrl: item.imageUrls.first,
                                      width: 56,
                                      height: 56,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.priceFormatted,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (all.length > 3)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Prikaži manje' : 'Prikaži sve'),
                ),
              ),
          ],
        );
      },
    );
  }
}
