import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/rustic_illustration.dart';

/// Prazno stanje pretrage — izvučeno iz SearchScreen da se smanji veličina ekrana.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    required this.hasFilters,
    required this.onResetFilters,
  });

  final bool hasFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final subtitle = hasFilters
        ? 'Probaj da ukloniš aktivne filtere ili promeniš pojam pretrage.'
        : 'Probaj drugi naziv ili pogledaj celu ponudu.';
    return AppEmptyState(
      motif: RusticMotif.search,
      icon: Icons.search_off,
      title: 'Ništa nismo pronašli',
      subtitle: subtitle,
      ctaLabel: 'Pogledaj sve proizvode',
      ctaIcon: Icons.list,
      onCtaPressed: onResetFilters,
    );
  }
}

/// Karta proizvoda iz rezultata pretrage — izvučeno iz SearchScreen.
class SearchProductCard extends StatelessWidget {
  const SearchProductCard({
    super.key,
    required this.product,
    required this.user,
    this.isPopular = false,
    this.avgRating,
    this.reviewCount,
  });

  final ProductModel product;
  final UserModel? user;
  final bool isPopular;
  final double? avgRating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final rating = avgRating;
    return user != null && !user!.isGuest
        ? Selector<FavoritesProvider, bool>(
            selector: (_, fav) => fav.isFavorite(p.id),
            builder: (_, isFavorite, __) {
              final favorites = context.read<FavoritesProvider>();
              return ProductCard(
                product: p,
                isFavorite: isFavorite,
                onFavoriteToggle: () => favorites.toggle(user!.id, p.id),
                isPopular: isPopular,
                avgRating: rating,
                reviewCount: reviewCount,
              );
            },
          )
        : ProductCard(
            product: p,
            isFavorite: null,
            onFavoriteToggle: null,
            isPopular: isPopular,
            avgRating: rating,
            reviewCount: reviewCount,
          );
  }
}
