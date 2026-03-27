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
    return isSeller
        ? const SellerDashboardScreen()
        : SearchScreen(initialCategory: initialCategory);
  }
}
