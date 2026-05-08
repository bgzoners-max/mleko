import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../providers/favorites_provider.dart';
import '../product_card.dart';

class HomeProductItem extends StatelessWidget {
  final ProductModel product;
  final int salesCount;
  final bool canFavorite;
  final String? userId;
  final double? avgRating;
  final int? reviewCount;

  const HomeProductItem({
    super.key,
    required this.product,
    required this.salesCount,
    required this.canFavorite,
    required this.userId,
    this.avgRating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCard(
      product: product,
      isPopular: salesCount >= AppConstants.popularProductMinSales,
      isFavorite: canFavorite
          ? context
              .select<FavoritesProvider, bool>((f) => f.isFavorite(product.id))
          : null,
      onFavoriteToggle: canFavorite
          ? () => context.read<FavoritesProvider>().toggle(userId!, product.id)
          : null,
      avgRating: avgRating,
      reviewCount: reviewCount,
    );
  }
}
