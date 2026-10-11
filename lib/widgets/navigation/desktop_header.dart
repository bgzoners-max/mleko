import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../providers/classifieds_provider.dart';
import '../../providers/location_provider.dart';
import '../beta_announcement_banner.dart';
import 'desktop_header_actions.dart';
import 'desktop_header_search.dart';
import 'desktop_nav_tab.dart';
import 'desktop_top_utility_strip.dart';

/// Glavni Desktop Header i Navigacija za Domaći Market po svetskim standardima.
///
/// Pruža:
/// 1. Gornju informativnu traku (lokacija, slogan, kontakt, instagram, beta status)
/// 2. Glavni navigacioni bar (brend, primarni tabovi, integrisana pretraga sa biračem regiona,
///    korpa, notifikacije, poruke, porudžbine, profil, i istaknuto CTA dugme "+ Postavi oglas").
class DesktopHeader extends StatelessWidget {
  final StatefulNavigationShell? navigationShell;
  final bool isStandalone;

  const DesktopHeader({
    super.key,
    this.navigationShell,
    this.isStandalone = false,
  });

  void _onNavigateTo(BuildContext context, int branchIndex, {required String route, MarketMode? mode}) {
    if (mode != null) {
      context.read<AppSettingsProvider>().setMarketMode(mode);
    }
    if (mode == MarketMode.foodMarket) {
      context.read<ClassifiedsProvider>().clearFilters();
    }
    if (navigationShell != null) {
      navigationShell!.goBranch(branchIndex, initialLocation: true);
      if (route == '/' || route == '/classifieds') {
        context.go(route);
      }
    } else {
      context.go(route);
    }
  }

  void _handleSearchSubmit(BuildContext context, String query) {
    final trimmed = query.trim();
    final marketMode = context.read<AppSettingsProvider>().marketMode;

    if (marketMode == MarketMode.classifieds || (navigationShell?.currentIndex == 1)) {
      context.read<ClassifiedsProvider>().search(trimmed.isEmpty ? null : trimmed);
      if (navigationShell?.currentIndex != 1) {
        _onNavigateTo(context, 1, route: '/classifieds', mode: MarketMode.classifieds);
      }
    } else {
      if (trimmed.isNotEmpty) {
        context.push('/search?q=${Uri.encodeComponent(trimmed)}');
      } else {
        context.push('/search');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appSettings = context.watch<AppSettingsProvider>();
    final cartCount = context.watch<CartProvider>().count;
    final user = context.watch<AppState>().user;
    final isGuest = user == null || user.isGuest;
    final unreadCount = context.select<AppState, int>((s) => s.unreadNotificationCount);
    final selectedRegion = context.select<LocationProvider, String?>((p) => p.selectedRegion);

    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {
      try {
        currentPath = GoRouter.of(context).routeInformationProvider.value.uri.path;
      } catch (_) {
        currentPath = '';
      }
    }

    final isSellersMap = currentPath == '/sellers-map';
    final currentIndex = navigationShell?.currentIndex ?? 0;
    final isFoodMarket = (currentIndex == 0 && appSettings.marketMode == MarketMode.foodMarket && !isSellersMap);
    final isClassifieds = ((currentIndex == 1 || appSettings.marketMode == MarketMode.classifieds) && !isSellersMap);

    final bgMain = isDark ? AmazonColors.darkCard : Colors.white;
    final borderMain = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    return Container(
      decoration: BoxDecoration(
        color: bgMain,
        border: Border(bottom: BorderSide(color: borderMain, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. GORNJA TRAKA (Top Utility Strip)
          DesktopTopUtilityStrip(
            isDark: isDark,
            selectedRegion: selectedRegion,
          ),

          // 2. GLAVNI HEADER (Brand, Navigacija, Pretraga, Akcije, CTA)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Brand / Logo
                    _buildBrandLogo(context, isDark: isDark),

                    const SizedBox(width: 20),

                    // Primarni Navigacioni Tabovi ("Pijaca hrane", "Mali oglasi", "Seoska gazdinstva", "O nama")
                    _buildNavTabs(
                      context,
                      isFoodMarket: isFoodMarket,
                      isClassifieds: isClassifieds,
                      isSellersMap: isSellersMap,
                    ),

                    const SizedBox(width: 16),

                    // Integrisana Desktop Pretraga
                    Expanded(
                      child: DesktopHeaderSearch(
                        isDark: isDark,
                        selectedRegion: selectedRegion,
                        onSearchSubmitted: (q) => _handleSearchSubmit(context, q),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Desni klaster akcija (Notifikacije, Korpa, Poruke, Tema, Profil, CTA)
                    DesktopHeaderActions(
                      isDark: isDark,
                      isGuest: isGuest,
                      user: user,
                      cartCount: cartCount,
                      unreadCount: unreadCount,
                      onNavigateTo: (branch, {required route}) =>
                          _onNavigateTo(context, branch, route: route),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(BuildContext context, {required bool isDark}) {
    return InkWell(
      onTap: () => _onNavigateTo(context, 0, route: '/', mode: MarketMode.foodMarket),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/domaci_market_logo_v2.png',
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2F21) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AmazonColors.green,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Domaći Market',
                      style: AppFonts.display(
                        isDark ? Colors.white : const Color(0xFF162A1D),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const BetaBadge(showInfoIcon: false),
                  ],
                ),
                Text(
                  'Pijaca hrane & Mali oglasi',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: isDark ? Colors.white60 : const Color(0xFF5A6B5F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabs(
    BuildContext context, {
    required bool isFoodMarket,
    required bool isClassifieds,
    required bool isSellersMap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesktopNavTab(
          label: 'Pijaca hrane',
          icon: Icons.storefront_outlined,
          isActive: isFoodMarket,
          onTap: () => _onNavigateTo(context, 0, route: '/', mode: MarketMode.foodMarket),
        ),
        const SizedBox(width: 6),
        DesktopNavTab(
          label: 'Mali oglasi',
          icon: Icons.campaign_outlined,
          isActive: isClassifieds,
          onTap: () => _onNavigateTo(context, 1, route: '/classifieds', mode: MarketMode.classifieds),
        ),
        const SizedBox(width: 6),
        DesktopNavTab(
          label: 'Seoska gazdinstva',
          icon: Icons.map_outlined,
          isActive: isSellersMap,
          onTap: () => context.go('/sellers-map'),
        ),
        const SizedBox(width: 6),
        DesktopNavTab(
          label: 'O nama',
          icon: Icons.info_outline_rounded,
          isActive: false,
          onTap: () => context.push('/about'),
        ),
      ],
    );
  }
}
