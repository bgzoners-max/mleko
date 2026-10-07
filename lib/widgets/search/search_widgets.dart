import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../widgets/product_card.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/rustic_illustration.dart';

/// Prazno stanje pretrage — izvučeno iz SearchScreen da se smanji veličina ekrana.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key, required this.screen});

  final dynamic screen;

  @override
  Widget build(BuildContext context) {
    final hasFilters = screen._category != null ||
        screen._region != null ||
        screen._availableNow == true;
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
      onCtaPressed: () {
        screen._searchController.clear();
        screen.setState(() {
          screen._category = null;
          screen._region = null;
          screen._availableNow = null;
          screen._debouncedQuery = '';
        });
        screen._loadFirstPage();
      },
    );
  }
}

/// Karta proizvoda iz rezultata pretrage — izvučeno iz SearchScreen.
class SearchProductCard extends StatelessWidget {
  const SearchProductCard({
    super.key,
    required this.screen,
    required this.i,
    required this.user,
  });

  final dynamic screen;
  final int i;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final p = screen._products[i];
    final rating = screen._ratings[p.id];
    return user != null && !user.isGuest
        ? Selector<FavoritesProvider, bool>(
            selector: (_, fav) => fav.isFavorite(p.id),
            builder: (_, isFavorite, __) {
              final favorites = context.read<FavoritesProvider>();
              return ProductCard(
                product: p,
                isFavorite: isFavorite,
                onFavoriteToggle: () => favorites.toggle(user.id, p.id),
                isPopular: (screen._salesCounts[p.id] ?? 0) >=
                    AppConstants.popularProductMinSales,
                avgRating: rating?.avg,
                reviewCount: rating?.count,
              );
            },
          )
        : ProductCard(
            product: p,
            isFavorite: null,
            onFavoriteToggle: null,
            isPopular: (screen._salesCounts[p.id] ?? 0) >=
                AppConstants.popularProductMinSales,
            avgRating: rating?.avg,
            reviewCount: rating?.count,
          );
  }
}
