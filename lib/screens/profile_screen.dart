import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/profile/become_seller_cta_card.dart';
import '../widgets/profile/buyer_stats_card.dart';
import '../widgets/profile/panel_placeholder.dart';
import '../widgets/profile/profile_data_card.dart';
import '../widgets/profile/seller_gallery_section.dart';
import '../widgets/profile/seller_profile_photo_section.dart';
import '../widgets/profile/profile_account_section.dart';
import '../widgets/profile/profile_classifieds_section.dart';
import '../widgets/profile/profile_guest_prompt.dart';
import '../widgets/profile/profile_market_section.dart';
import '../widgets/profile/profile_reviews_section.dart';
import 'edit_profile_screen.dart';
import 'seller/becoming_seller_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _panelNavKey = GlobalKey<NavigatorState>();
  String? _activeSection;

  void _showInPanel(String section, Widget screen) {
    setState(() => _activeSection = section);
    _panelNavKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _push(String route) => context.push(route);
  void _openPanel(String section, Widget screen,
      {required bool isWide, String? route}) {
    if (isWide) {
      _showInPanel(section, screen);
    } else {
      _push(route ??
          switch (section) {
            'favorites' => '/favorites',
            'favorite-sellers' => '/favorite-sellers',
            'saved-searches' => '/classifieds/saved-searches',
            'messages' => '/conversations',
            'notifications' => '/notifications',
            'settings' => '/settings',
            'becoming-seller' => '/becoming-seller',
            'edit-profile' => '/profile/edit',
            'seller-settings' => '/seller-settings',
            'orders' => '/orders',
            'my-classifieds' => '/classifieds/my',
            'new-classified' => '/classifieds/new',
            'support' => '/support',
            'about' => '/about',
            _ => '/',
          });
    }
  }

  bool _isActive(String section, bool isWide) =>
      isWide && _activeSection == section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return const ProfileGuestPrompt();
    }
    final isWide = Breakpoints.useTwoPaneLayout(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isWide ? 44 : 46,
        centerTitle: !isWide,
        backgroundColor:
            isDark ? const Color(0xFF1E3424) : theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: isDark
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
        leading: const AppBackButton(fallbackRoute: '/'),
        title: Text(
          'Profil',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1B201C),
          ),
        ),
        actions: const [AppHomeButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child:
              isWide ? _buildWide(context, user) : _buildNarrow(context, user),
        ),
      ),
    );
  }

  Widget _buildWide(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 350),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (!user.isGuest) ...[
                    SellerProfilePhotoSection(user: user),
                    const SizedBox(height: 6),
                  ],
                  if (user.isSeller) ...[
                    SellerGallerySection(user: user),
                    const SizedBox(height: 6),
                  ],
                  ProfileDataCard(
                    user: user,
                    onEdit: () => _openPanel(
                        'edit-profile', const EditProfileScreen(),
                        isWide: true),
                  ),
                  const SizedBox(height: 6),
                  if (!user.isGuest) ...[
                    BuyerStatsCard(user: user),
                    const SizedBox(height: 6),
                  ],
                  if (!user.isGuest && !user.isSeller) ...[
                    BecomeSellerCtaCard(
                      isSelected: _isActive('becoming-seller', true),
                      onTap: () => _openPanel(
                        'becoming-seller',
                        const BecomingSellerScreen(),
                        isWide: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // SEKCIJA 1: MINI PIJACA (sa blago zelenkastom pozadinom)
                  ProfileMarketSection(
                    user: user,
                    isWide: true,
                    onOpenPanel: _openPanel,
                    isActiveSection: _isActive,
                  ),
                  const SizedBox(height: 8),
                  // SEKCIJA 2: OGLASNIK (sve stavke oglasnika na jednom mestu)
                  ProfileClassifiedsSection(
                    user: user,
                    isWide: true,
                    onOpenPanel: _openPanel,
                    isActiveSection: _isActive,
                  ),
                  const SizedBox(height: 8),
                  // SEKCIJA 3: RECENZIJE I OCENE (zajednički ugled)
                  ProfileReviewsSection(
                    user: user,
                    isWide: true,
                    onOpenPanel: _openPanel,
                    isActiveSection: _isActive,
                  ),
                  const SizedBox(height: 8),
                  // SEKCIJA 4: NALOG I PODEŠAVANJA
                  ProfileAccountSection(
                    user: user,
                    isWide: true,
                    onOpenPanel: _openPanel,
                    isActiveSection: _isActive,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Flexible(
          flex: 7,
          child: HeroControllerScope.none(
            child: Theme(
              data: theme.copyWith(
                appBarTheme: theme.appBarTheme.copyWith(
                  toolbarHeight: 44,
                  centerTitle: false,
                  backgroundColor: isDark
                      ? const Color(0xFF1E3424)
                      : theme.colorScheme.surface,
                  foregroundColor:
                      isDark ? Colors.white : theme.colorScheme.onSurface,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  shape: isDark
                      ? null
                      : const Border(
                          bottom:
                              BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                  iconTheme: IconThemeData(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  actionsIconTheme: IconThemeData(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    size: 20,
                  ),
                  titleTextStyle: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: isDark ? Colors.white : const Color(0xFF1B201C),
                  ),
                ),
                tabBarTheme: theme.tabBarTheme.copyWith(
                  labelColor: isDark ? Colors.white : const Color(0xFF245938),
                  unselectedLabelColor:
                      isDark ? Colors.white60 : const Color(0xFF555E57),
                  indicatorColor: isDark
                      ? theme.colorScheme.secondary
                      : const Color(0xFF245938),
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: isDark ? null : const Color(0xFFE5E7EB),
                  labelStyle: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: Navigator(
                key: _panelNavKey,
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => const PanelPlaceholder(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context, UserModel user) {
    final isSmallTablet = Breakpoints.isSmallTablet(context);
    final profileCards = [
      if (!user.isGuest) SellerProfilePhotoSection(user: user),
      if (user.isSeller) SellerGallerySection(user: user),
      ProfileDataCard(user: user),
      if (!user.isGuest) BuyerStatsCard(user: user),
      if (!user.isGuest && !user.isSeller)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: BecomeSellerCtaCard(
            isSelected: false,
            onTap: () => _push('/becoming-seller'),
          ),
        ),
    ];
    return ListView(
      padding: EdgeInsets.all(isSmallTablet ? 12 : 8),
      children: [
        ...profileCards,
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 1: MINI PIJACA (sa blago zelenkastom pozadinom)
        ProfileMarketSection(
          user: user,
          isWide: false,
          onOpenPanel: _openPanel,
          isActiveSection: _isActive,
        ),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 2: OGLASNIK (sve stavke oglasnika na jednom mestu)
        ProfileClassifiedsSection(
          user: user,
          isWide: false,
          onOpenPanel: _openPanel,
          isActiveSection: _isActive,
        ),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 3: RECENZIJE I OCENE (zajednički ugled)
        ProfileReviewsSection(
          user: user,
          isWide: false,
          onOpenPanel: _openPanel,
          isActiveSection: _isActive,
        ),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 4: NALOG I PODEŠAVANJA
        ProfileAccountSection(
          user: user,
          isWide: false,
          onOpenPanel: _openPanel,
          isActiveSection: _isActive,
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
