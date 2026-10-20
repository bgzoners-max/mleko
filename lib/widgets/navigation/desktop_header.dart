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
    final isAbout = currentPath == '/about';
    final currentIndex = navigationShell?.currentIndex ?? 0;
    final isFoodMarket = (currentIndex == 0 && appSettings.marketMode == MarketMode.foodMarket && !isSellersMap && !isAbout);
    final isClassifieds = ((currentIndex == 1 || appSettings.marketMode == MarketMode.classifieds) && !isSellersMap && !isAbout);

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
          // 1. GORNJA INFORMATIVNA TRAKA (Top Utility Strip - Slogan, Lokacija, Kontakt)
          DesktopTopUtilityStrip(
            isDark: isDark,
            selectedRegion: selectedRegion,
          ),

          // 2. GLAVNI HEADER (Brand, Velika Centralna Pretraga, Akcije i Korpa)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    // Brand / Logo
                    _buildBrandLogo(context, isDark: isDark),

                    const SizedBox(width: 24),

                    // Integrisana Desktop Pretraga (Prostrana, ne sudara se sa korpom)
                    Expanded(
                      child: DesktopHeaderSearch(
                        isDark: isDark,
                        selectedRegion: selectedRegion,
                        onSearchSubmitted: (q) => _handleSearchSubmit(context, q),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Desni klaster akcija (Korpa, Notifikacije, Poruke, Tema, Profil, CTA)
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

          // 3. SEKUNDARNI NAVIGACIONI BAR (Primarni Tabovi i brzi filteri - Amazon/KP stil)
          _buildSubNavBar(
            context,
            isDark: isDark,
            isFoodMarket: isFoodMarket,
            isClassifieds: isClassifieds,
            isSellersMap: isSellersMap,
            isAbout: isAbout,
            selectedRegion: selectedRegion,
          ),
        ],
      ),
    );
  }

  Widget _buildSubNavBar(
    BuildContext context, {
    required bool isDark,
    required bool isFoodMarket,
    required bool isClassifieds,
    required bool isSellersMap,
    required bool isAbout,
    required String? selectedRegion,
  }) {
    final subBarBg = isDark ? const Color(0xFF131D15) : const Color(0xFFF7FAF7);
    final subBarBorder = isDark ? const Color(0xFF1F2E22) : const Color(0xFFE2E8E2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: subBarBg,
        border: Border(
          top: BorderSide(color: subBarBorder, width: 1.0),
          bottom: BorderSide(color: subBarBorder, width: 1.0),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
            child: Row(
              children: [
                // Navigacioni Tabovi (Objedinjena Kapsula za Domaću Hranu & Gazdinstva + Oglasi + O nama)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: _buildNavTabs(
                      context,
                      isDark: isDark,
                      isFoodMarket: isFoodMarket,
                      isClassifieds: isClassifieds,
                      isSellersMap: isSellersMap,
                      isAbout: isAbout,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Brzi birač regiona u podnavigaciji
                InkWell(
                  onTap: () => openLocationDialog(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: isDark ? AmazonColors.lightGreen : AmazonColors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          selectedRegion != null ? 'Region: $selectedRegion' : 'Srbija: Svi regioni',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AmazonColors.darkNavy,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    required bool isDark,
    required bool isFoodMarket,
    required bool isClassifieds,
    required bool isSellersMap,
    required bool isAbout,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. ZAJEDNIČKI OKVIR / KAPSULA (Pijaca hrane + Seoska gazdinstva kao jedna celina)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF142418) : const Color(0xFFEAF4EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF23442A) : const Color(0xFFCCE4D0),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DesktopNavTab(
                label: 'Pijaca hrane',
                icon: Icons.storefront_outlined,
                isActive: isFoodMarket,
                isCapsule: true,
                onTap: () => _onNavigateTo(context, 0, route: '/', mode: MarketMode.foodMarket),
              ),
              const SizedBox(width: 3),
              DesktopNavTab(
                label: 'Seoska gazdinstva',
                icon: Icons.map_outlined,
                isActive: isSellersMap,
                isCapsule: true,
                onTap: () => context.go('/sellers-map'),
              ),
            ],
          ),
        ),

        // 2. DISKRETAN RAZDELNIK
        Container(
          height: 22,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: isDark ? const Color(0xFF2E3E32) : const Color(0xFFD6E0D6),
        ),

        // 3. MALI OGLASI
        DesktopNavTab(
          label: 'Mali oglasi',
          icon: Icons.campaign_outlined,
          isActive: isClassifieds,
          badge: 'NOVO',
          onTap: () => _onNavigateTo(context, 1, route: '/classifieds', mode: MarketMode.classifieds),
        ),

        const SizedBox(width: 6),

        // 4. O NAMA
        DesktopNavTab(
          label: 'O nama',
          icon: Icons.info_outline_rounded,
          isActive: isAbout,
          onTap: () => context.push('/about'),
        ),
      ],
    );
  }
}
