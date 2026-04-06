import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'search_screen.dart';
import 'seller/seller_dashboard_screen.dart';

/// Tab 1: Pretraga (kupac) ili Moji proizvodi (prodavac).
class TabSearchOrProductsScreen extends StatelessWidget {
  const TabSearchOrProductsScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  Widget build(BuildContext context) {
    final isSeller = context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    // Prodavac vidi dashboard samo kada nema filtera kategorije.
    // Kada klikne na kategoriju, prikazuje se marketplace pretraga.
    if (isSeller && initialCategory == null) {
      return const SellerDashboardScreen();
    }
    return SearchScreen(initialCategory: initialCategory);
  }
}
