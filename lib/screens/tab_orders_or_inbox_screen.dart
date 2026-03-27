import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import 'orders_screen.dart';
import 'seller/seller_inbox_screen.dart';
import 'seller/seller_orders_screen.dart';

/// Tab 2: Porudžbine (kupac) ili Porudžbine + Razgovori (prodavac).
class TabOrdersOrInboxScreen extends StatelessWidget {
  const TabOrdersOrInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSeller = context.select<AppState, bool>((s) => s.user?.isSeller ?? false);
    if (isSeller) {
      return _SellerOrdersInboxTabs();
    }
    return const OrdersScreen();
  }
}

class _SellerOrdersInboxTabs extends StatefulWidget {
  @override
  State<_SellerOrdersInboxTabs> createState() => _SellerOrdersInboxTabsState();
}

class _SellerOrdersInboxTabsState extends State<_SellerOrdersInboxTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = context.watch<AppSettingsProvider>().animationsEnabled;
    final children = const [
      SellerOrdersScreen(showAppBar: false),
      SellerInboxScreen(showOnlyConversations: true, showAppBar: false),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Porudžbine'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: 'Porudžbine', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Razgovori', icon: Icon(Icons.chat)),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: animationsEnabled ? 250 : 0),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey<int>(_tabController.index),
          child: children[_tabController.index],
        ),
      ),
    );
  }
}
