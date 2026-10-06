import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../models/user_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import '../../providers/classifieds_provider.dart';
import '../../providers/location_provider.dart';
import '../beta_announcement_banner.dart';
import '../guest_auth_prompt.dart';
import '../theme_toggle_switch.dart';

/// Glavni Desktop Header i Mega Navigacija za Domaći Market po svetskim standardima.
///
/// Pruža:
/// 1. Gornju informativnu traku (lokacija, slogan, kontakt, instagram, beta status)
/// 2. Glavni navigacioni bar (brend, pretraga sa brzim biračem lokacije, primarni tabovi,
///    korpa, notifikacije, poruke, porudžbine, profil, i istaknuto CTA dugme "+ Postavi oglas")
/// 3. Mega-nav strip sa brzim pristupom top kategorijama hrane i malih oglasa
class DesktopHeader extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final bool isStandalone;

  const DesktopHeader({
    super.key,
    this.navigationShell,
    this.isStandalone = false,
  });

  @override
  State<DesktopHeader> createState() => _DesktopHeaderState();
}

class _DesktopHeaderState extends State<DesktopHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onNavigateTo(int branchIndex, {required String route, MarketMode? mode}) {
    if (mode != null) {
      context.read<AppSettingsProvider>().setMarketMode(mode);
    }
    if (mode == MarketMode.foodMarket) {
      context.read<ClassifiedsProvider>().clearFilters();
    }
    if (widget.navigationShell != null) {
      widget.navigationShell!.goBranch(branchIndex, initialLocation: true);
      if (route == '/' || route == '/classifieds') {
        context.go(route);
      }
    } else {
      context.go(route);
    }
  }

  void _handleSearchSubmit(String query) {
    final trimmed = query.trim();
    final marketMode = context.read<AppSettingsProvider>().marketMode;

    if (marketMode == MarketMode.classifieds ||
        (widget.navigationShell?.currentIndex == 1)) {
      context.read<ClassifiedsProvider>().search(trimmed.isEmpty ? null : trimmed);
      if (widget.navigationShell?.currentIndex != 1) {
        _onNavigateTo(1, route: '/classifieds', mode: MarketMode.classifieds);
      }
    } else {
      if (trimmed.isNotEmpty) {
        context.push('/search?q=${Uri.encodeComponent(trimmed)}');
      } else {
        context.push('/search');
      }
    }
  }

  Future<void> _openLocationDialog(BuildContext context) async {
    final loc = context.read<LocationProvider>();
    final currentRegion = loc.selectedRegion;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: isDark ? AmazonColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AmazonColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AmazonColors.green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Izaberite region u Srbiji',
                              style: AppFonts.display(
                                isDark ? Colors.white : AmazonColors.darkNavy,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Prikazujte ponude domaćih gazdinstava u vašoj blizini',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => Navigator.pop(ctx, ''),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: currentRegion == null
                            ? AmazonColors.green.withValues(alpha: isDark ? 0.2 : 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: currentRegion == null
                              ? AmazonColors.green
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🇷🇸', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cela Srbija (Svi regioni)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : AmazonColors.darkNavy,
                                  ),
                                ),
                                Text(
                                  'Prikaz svih domaćih proizvođača bez geografskog filtera',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentRegion == null)
                            const Icon(Icons.check_circle_rounded,
                                color: AmazonColors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.regions.map((reg) {
                      final isSel = currentRegion == reg;
                      return InkWell(
                        onTap: () => Navigator.pop(ctx, reg),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AmazonColors.green.withValues(alpha: isDark ? 0.25 : 0.1)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAF8)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel
                                  ? AmazonColors.green
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin_drop_outlined,
                                size: 16,
                                color: isSel ? AmazonColors.green : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                reg,
                                style: TextStyle(
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                  color: isSel
                                      ? AmazonColors.green
                                      : (isDark ? Colors.white : AmazonColors.darkNavy),
                                ),
                              ),
                              if (isSel) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check, size: 16, color: AmazonColors.green),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selected != null && context.mounted) {
      if (selected.isEmpty) {
        unawaited(loc.clearRegion());
      } else {
        await loc.setRegion(selected);
      }
    }
  }

  void _onCategoryItemTap(String label) {
    if (label.contains('Sve kategorije')) {
      context.push('/categories');
      return;
    }

    if (label.contains('Mehanizacija') || label.contains('životinje')) {
      // Pređi na male oglase
      _onNavigateTo(1, route: '/classifieds', mode: MarketMode.classifieds);
      return;
    }

    // Za hranu
    _onNavigateTo(0, route: '/', mode: MarketMode.foodMarket);
    context.push('/search?category=${Uri.encodeComponent(label)}');
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
    final currentIndex = widget.navigationShell?.currentIndex ?? 0;
    final isFoodMarket = (currentIndex == 0 && appSettings.marketMode == MarketMode.foodMarket && !isSellersMap);
    final isClassifieds = ((currentIndex == 1 || appSettings.marketMode == MarketMode.classifieds) && !isSellersMap);

    final bgMain = isDark ? AmazonColors.darkCard : Colors.white;
    final borderMain = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;
    final bgSub = isDark ? const Color(0xFF131B15) : const Color(0xFFF9FAF8);
    final borderSub = isDark ? const Color(0xFF222C24) : const Color(0xFFE8ECE8);

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
          _buildTopUtilityStrip(
            context,
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
                      isDark: isDark,
                      isFoodMarket: isFoodMarket,
                      isClassifieds: isClassifieds,
                      isSellersMap: isSellersMap,
                    ),

                    const SizedBox(width: 16),

                    // Integrisana Desktop Pretraga
                    Expanded(
                      child: _buildSearchBox(
                        context,
                        isDark: isDark,
                        selectedRegion: selectedRegion,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Desni klaster akcija (Notifikacije, Korpa, Poruke, Tema, Profil, CTA)
                    _buildActionsCluster(
                      context,
                      isDark: isDark,
                      isGuest: isGuest,
                      user: user,
                      cartCount: cartCount,
                      unreadCount: unreadCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. SUB-NAV MEGA STRIP (Brze kategorije hrane i oglasa)
          Container(
            decoration: BoxDecoration(
              color: bgSub,
              border: Border(
                top: BorderSide(color: borderSub, width: 1.0),
                bottom: BorderSide(color: borderSub, width: 1.0),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: _buildCategoriesStrip(context, isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. Top Utility Strip ---
  Widget _buildTopUtilityStrip(
    BuildContext context, {
    required bool isDark,
    required String? selectedRegion,
  }) {
    return Container(
      color: isDark ? const Color(0xFF0F1711) : const Color(0xFF1E3A27),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Row(
            children: [
              // Poruka poverenja
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '100% domaća hrana i proizvodi direktno od poljoprivrednih gazdinstava širom Srbije',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Lokacija brzi selektor
              InkWell(
                onTap: () => _openLocationDialog(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AmazonColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        selectedRegion != null ? 'Region: $selectedRegion' : 'Srbija: Svi regioni',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Email
              InkWell(
                onTap: () => launchUrl(Uri.parse('mailto:kontakt@domacimarket.rs')),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Text(
                        'kontakt@domacimarket.rs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Instagram
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.instagram.com/domacimarket.rs'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Text(
                        '@domacimarket.rs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. Logo / Brend ---
  Widget _buildBrandLogo(BuildContext context, {required bool isDark}) {
    return InkWell(
      onTap: () => _onNavigateTo(0, route: '/', mode: MarketMode.foodMarket),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2F21) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E4D38) : const Color(0xFFC8E6C9),
                  width: 1.2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: AmazonColors.green,
                  size: 22,
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
                        fontWeight: FontWeight.w900,
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

  // --- 3. Navigacioni Tabovi ---
  Widget _buildNavTabs(
    BuildContext context, {
    required bool isDark,
    required bool isFoodMarket,
    required bool isClassifieds,
    required bool isSellersMap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DesktopNavTab(
          label: 'Pijaca hrane',
          icon: Icons.storefront_outlined,
          isActive: isFoodMarket,
          onTap: () => _onNavigateTo(0, route: '/', mode: MarketMode.foodMarket),
        ),
        const SizedBox(width: 6),
        _DesktopNavTab(
          label: 'Mali oglasi',
          icon: Icons.campaign_outlined,
          badge: 'NOVO',
          isActive: isClassifieds,
          onTap: () => _onNavigateTo(1, route: '/classifieds', mode: MarketMode.classifieds),
        ),
        const SizedBox(width: 6),
        _DesktopNavTab(
          label: 'Seoska gazdinstva',
          icon: Icons.map_outlined,
          isActive: isSellersMap,
          onTap: () {
            context.go('/sellers-map');
          },
        ),
        const SizedBox(width: 6),
        _DesktopNavTab(
          label: 'O nama',
          icon: Icons.info_outline_rounded,
          isActive: false,
          onTap: () => context.push('/about'),
        ),
      ],
    );
  }

  // --- 4. Integrisana Pretraga sa biračem lokacije ---
  Widget _buildSearchBox(
    BuildContext context, {
    required bool isDark,
    required String? selectedRegion,
  }) {
    return Container(
      height: 42,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2B21) : const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _isSearchFocused
              ? AmazonColors.green
              : (isDark ? const Color(0xFF2C3E2F) : const Color(0xFFD6DFD6)),
          width: _isSearchFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: _isSearchFocused ? AmazonColors.green : (isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleSearchSubmit,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : AmazonColors.darkNavy,
              ),
              decoration: InputDecoration(
                hintText: 'Pretraži sir, med, voće, traktore, oglase...',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                _searchController.clear();
                _handleSearchSubmit('');
              },
            ),
          // Birač lokacije unutar pretrage
          InkWell(
            onTap: () => _openLocationDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 13, color: AmazonColors.green),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      selectedRegion ?? 'Srbija',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AmazonColors.darkNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Desni Klaster Akcija ---
  Widget _buildActionsCluster(
    BuildContext context, {
    required bool isDark,
    required bool isGuest,
    required UserModel? user,
    required int cartCount,
    required int unreadCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Korpa
        _HeaderIconButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Korpa za narudžbine',
          badgeCount: cartCount,
          badgeColor: AmazonColors.amber,
          onTap: () => context.push('/cart'),
        ),

        // Ako korisnik nije gost: Notifikacije, Poruke, Porudžbine
        if (!isGuest) ...[
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Obaveštenja',
            badgeCount: unreadCount,
            badgeColor: AmazonColors.dealRed,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Poruke',
            onTap: () => _onNavigateTo(3, route: '/conversations'),
          ),
          const SizedBox(width: 4),
          _HeaderIconButton(
            icon: Icons.receipt_long_outlined,
            tooltip: 'Moje porudžbine',
            onTap: () => _onNavigateTo(2, route: '/orders'),
          ),
        ],

        const SizedBox(width: 8),
        const ThemeToggleSwitch(),
        const SizedBox(width: 12),

        // Profil / Prijavi se
        if (isGuest)
          OutlinedButton.icon(
            onPressed: () => context.push('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              side: BorderSide(
                color: isDark ? Colors.white24 : AmazonColors.green,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(
              Icons.person_outline,
              size: 16,
              color: isDark ? Colors.white : AmazonColors.green,
            ),
            label: Text(
              'Prijavi se',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: isDark ? Colors.white : AmazonColors.green,
              ),
            ),
          )
        else
          PopupMenuButton<int>(
            tooltip: 'Korisnički meni',
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Korisnik',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    if (user?.email != null)
                      Text(
                        user!.email!,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    const Divider(height: 12),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18),
                    SizedBox(width: 10),
                    Text('Moj profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Moje porudžbine'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 3,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Razgovori & Poruke'),
                  ],
                ),
              ),
              if (user?.isSeller == true)
                const PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.agriculture_rounded, size: 18, color: AmazonColors.green),
                      SizedBox(width: 10),
                      Text('Gazdinstvo / Prodavnica', style: TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 5,
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Odjavi se', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 1) _onNavigateTo(4, route: '/profile');
              if (val == 2) _onNavigateTo(2, route: '/orders');
              if (val == 3) _onNavigateTo(3, route: '/conversations');
              if (val == 4) context.push('/seller-dashboard');
              if (val == 5) {
                unawaited(context.read<AppState>().authService.signOut());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFC8E6C9),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AmazonColors.green,
                    child: Text(
                      ((user?.displayName?.isNotEmpty == true) ? user!.displayName![0] : 'U').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      user?.displayName ?? 'Nalog',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AmazonColors.darkNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),

        const SizedBox(width: 14),

        // Hero CTA Dugme: "+ Postavi oglas"
        ElevatedButton.icon(
          onPressed: () {
            if (isGuest) {
              showGuestAuthPrompt(
                context,
                title: 'Postavljanje oglasa',
                message: 'Prijavite se ili se besplatno registrujte da biste besplatno postavili oglas ili ponudili domaće proizvode.',
                icon: Icons.campaign_rounded,
              );
            } else {
              context.push('/classifieds/new');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AmazonColors.amber,
            foregroundColor: AmazonColors.darkNavy,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
          label: const Text(
            'Postavi oglas',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // --- 6. Sub-Nav Mega Strip (Kategorije) ---
  Widget _buildCategoriesStrip(BuildContext context, {required bool isDark}) {
    final categories = const [
      ('🥛', 'Mleko & Sirevi'),
      ('🍯', 'Med & Pčelarstvo'),
      ('🥩', 'Meso & Prerađevine'),
      ('🍓', 'Voće & Povrće'),
      ('🫙', 'Zimnica & Džemovi'),
      ('🍷', 'Domaća pića'),
      ('🚜', 'Poljoprivreda & Mehanizacija'),
      ('🐾', 'Domaće životinje'),
      ('📂', 'Sve kategorije →'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: categories.map((cat) {
          final isAll = cat.$2.contains('Sve kategorije');
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _onCategoryItemTap(cat.$2),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.$1, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isAll ? FontWeight.w800 : FontWeight.w600,
                        color: isAll
                            ? AmazonColors.green
                            : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Pojedinačni tab u desktop navigaciji sa hover efektom i aktivnim indikatorom.
class _DesktopNavTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _DesktopNavTab({
    required this.label,
    required this.icon,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  State<_DesktopNavTab> createState() => _DesktopNavTabState();
}

class _DesktopNavTabState extends State<_DesktopNavTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const activeColor = AmazonColors.green;
    final inactiveColor = isDark ? Colors.white70 : AmazonColors.darkNavy;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (isDark ? const Color(0xFF1B2F21) : const Color(0xFFE8F5E9))
                : (_isHovered
                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F2))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive
                  ? (isDark ? const Color(0xFF2E4D38) : const Color(0xFFC8E6C9))
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: AmazonColors.darkNavy,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Akciono dugme sa ikonicom i opcionim bedžom brojača.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int? badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.badgeCount,
    this.badgeColor = AmazonColors.amber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showBadge = badgeCount != null && badgeCount! > 0;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        icon: Badge(
          isLabelVisible: showBadge,
          label: Text(
            '$badgeCount',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: badgeColor,
          child: Icon(
            icon,
            size: 21,
            color: isDark ? Colors.white70 : AmazonColors.darkNavy,
          ),
        ),
      ),
    );
  }
}
