import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import 'orders_screen.dart';
import 'seller/seller_inbox_screen.dart';
import 'seller/seller_orders_screen.dart';

/// Tab 2: Porudžbine (kupac) ili Porudžbine + Razgovori (prodavac).
class TabOrdersOrInboxScreen extends StatelessWidget {
  const TabOrdersOrInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSeller = context.watch<AppState>().user?.isSeller ?? false;
    if (isSeller) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Porudžbine'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Porudžbine', icon: Icon(Icons.receipt_long)),
                Tab(text: 'Razgovori', icon: Icon(Icons.chat)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              SellerOrdersScreen(showAppBar: false),
              SellerInboxScreen(showOnlyConversations: true, showAppBar: false),
            ],
          ),
        ),
      );
    }
    return const OrdersScreen();
  }
}
