import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'search_screen.dart';
import 'seller/seller_dashboard_screen.dart';

/// Shared shell tab that can show marketplace search or seller products.
class TabSearchOrProductsScreen extends StatelessWidget {
  const TabSearchOrProductsScreen({
    super.key,
    this.initialCategory,
    this.initialQuery,
    this.openSellerProducts = false,
  });

  final String? initialCategory;
  final String? initialQuery;
  final bool openSellerProducts;

  @override
  Widget build(BuildContext context) {
    final isSeller =
        context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    if (isSeller && openSellerProducts) {
      return const SellerDashboardScreen();
    }
    return SearchScreen(
      initialCategory: initialCategory,
      initialQuery: initialQuery,
    );
  }
}
