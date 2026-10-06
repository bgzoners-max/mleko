import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../theme_toggle_switch.dart';
import 'desktop_header.dart';

/// Glavni navigacioni omotač (Shell) sa adaptivnim BottomBar / NavigationRail / DesktopHeader prikazom.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  // Redosled mora da prati StatefulShellBranch redosled:
  // 0=Pocetna, 1=Oglasi, 2=Porudzbine, 3=Poruke, 4=Profil.
  static const _destinations = [
    (icon: Icons.cottage, label: 'Početna'),
    (icon: Icons.storefront, label: 'Oglasi'),
    (icon: Icons.receipt_long, label: 'Porudžbine'),
    (icon: Icons.chat_bubble_outline, label: 'Poruke'),
    (icon: Icons.person, label: 'Profil'),
  ];

  static const _guestDestinations = [
    (icon: Icons.cottage, label: 'Početna'),
    (icon: Icons.storefront, label: 'Oglasi'),
    (icon: Icons.login_rounded, label: 'Prijavi se'),
  ];

  static int _mapGuestBranchToDestination(int branchIndex) {
    switch (branchIndex) {
      case 0:
        return 0; // Početna
      case 1:
        return 1; // Oglasi
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int i, {required bool isGuest}) {
    if (isGuest) {
      switch (i) {
        case 0:
          context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
          context.read<ClassifiedsProvider>().clearFilters();
          navigationShell.goBranch(0, initialLocation: true);
          break;
        case 1:
          context.read<AppSettingsProvider>().setMarketMode(MarketMode.classifieds);
          navigationShell.goBranch(1, initialLocation: true);
          break;
        case 2:
          context.push('/login');
          break;
      }
      return;
    }

    switch (i) {
      case 0:
        context.read<AppSettingsProvider>().setMarketMode(MarketMode.foodMarket);
        context.read<ClassifiedsProvider>().clearFilters();
        navigationShell.goBranch(0, initialLocation: true);
        break;
      case 1:
        context.read<AppSettingsProvider>().setMarketMode(MarketMode.classifieds);
        navigationShell.goBranch(1, initialLocation: true);
        break;
      default:
        navigationShell.goBranch(i, initialLocation: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isGuest = user == null || user.isGuest;
    final destinations = isGuest ? _guestDestinations : _destinations;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= kDesktopBreakpoint;
    final isTabletRail = !isDesktop && width >= Breakpoints.phone;
    final selectedDestIndex = isGuest
        ? _mapGuestBranchToDestination(navigationShell.currentIndex)
        : navigationShell.currentIndex.clamp(0, destinations.length - 1);

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            DesktopHeader(navigationShell: navigationShell),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    if (isTabletRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedDestIndex,
              onDestinationSelected: (i) =>
                  _onDestinationSelected(context, i, isGuest: isGuest),
              labelType: NavigationRailLabelType.all,
              trailing: const Padding(
                padding: EdgeInsets.only(top: 24),
                child: ThemeToggleSwitch(),
              ),
              destinations: destinations.map((d) {
                return NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                );
              }).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedDestIndex,
        onDestinationSelected: (i) =>
            _onDestinationSelected(context, i, isGuest: isGuest),
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
