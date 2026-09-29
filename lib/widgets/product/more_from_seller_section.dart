import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
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
  Future<List<ProductModel>>? _relatedProductsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _relatedProductsFuture ??= _loadRelatedProducts();
  }

  @override
  void didUpdateWidget(covariant MoreFromSellerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.sellerId != widget.product.sellerId) {
      _relatedProductsFuture = _loadRelatedProducts();
    }
  }

  Future<List<ProductModel>> _loadRelatedProducts() {
    return context.read<ProductsService>().getRelatedSellerProducts(
          sellerId: widget.product.sellerId,
          excludeProductId: widget.product.id,
          limit: 10,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<ProductModel>>(
      future: _relatedProductsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final sellerProducts = snapshot.data!;
        if (sellerProducts.isEmpty) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final initialCount = isWide ? 4 : 3;
            final visibleProducts = _expanded
                ? sellerProducts
                : sellerProducts.take(initialCount).toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: AmazonColors.link,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Još iz ovog domaćinstva',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${sellerProducts.length}',
                        style: TextStyle(
                          color: isDark
                              ? AmazonColors.darkTextPrimary
                              : AmazonColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isWide)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 76,
                    ),
                    itemCount: visibleProducts.length,
                    itemBuilder: (context, index) => _SellerProductCard(
                      product: visibleProducts[index],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final sellerProduct in visibleProducts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SellerProductCard(product: sellerProduct),
                        ),
                    ],
                  ),
                if (sellerProducts.length > initialCount)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: Icon(_expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down),
                        label: Text(
                          _expanded
                              ? 'Prikaži manje'
                              : 'Prikaži sve (${sellerProducts.length})',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SellerProductCard extends StatelessWidget {
  final ProductModel product;

  const _SellerProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrls.isEmpty
                    ? Container(
                        width: 56,
                        height: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported, size: 24),
                      )
                    : AppNetworkImage.icon(
                        imageUrl: product.imageUrls.first,
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
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.priceFormatted,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFF6B6B)
                            : AmazonColors.dealRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
