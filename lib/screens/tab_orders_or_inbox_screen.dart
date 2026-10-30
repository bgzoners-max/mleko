import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../widgets/app_back_button.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final animationsEnabled = context.watch<AppSettingsProvider>().animationsEnabled;
    const children = [
      SellerOrdersScreen(showAppBar: false),
      SellerInboxScreen(showOnlyConversations: true, showAppBar: false),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Porudžbine'),
        actions: const [AppHomeButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const maxContent = 800.0;
              final avail = constraints.maxWidth;
              final leftPad = ((avail - maxContent) / 2).clamp(0.0, double.infinity);
              return Padding(
                padding: EdgeInsets.only(left: leftPad),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  onTap: (_) => HapticFeedback.selectionClick(),
                  labelColor: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  unselectedLabelColor: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                  indicatorColor: AmazonColors.getGreen(context),
                  tabs: const [
                    Tab(text: 'Porudžbine', icon: Icon(Icons.receipt_long)),
                    Tab(text: 'Razgovori', icon: Icon(Icons.chat)),
                  ],
                ),
              );
            },
          ),
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
