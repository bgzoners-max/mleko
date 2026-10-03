import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'favorite_sellers_screen.dart';
import 'notifications_screen.dart';
import 'conversations_screen.dart';
import 'seller/becoming_seller_screen.dart';
import 'seller/seller_reviews_screen.dart';
import 'classifieds/saved_searches_screen.dart';
import '../providers/classifieds_provider.dart';

import '../widgets/profile/mini_store_card.dart';
import '../widgets/profile/buyer_stats_card.dart';
import '../widgets/profile/seller_profile_photo_section.dart';
import '../widgets/profile/seller_gallery_section.dart';
import '../widgets/profile/profile_data_card.dart';
import '../widgets/profile/panel_placeholder.dart';
import '../widgets/app_back_button.dart';
import '../widgets/guest_auth_prompt.dart';
import 'edit_profile_screen.dart';

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
  void _openPanel(String section, Widget screen, {required bool isWide}) {
    if (isWide) {
      _showInPanel(section, screen);
    } else {
      _push(switch (section) {
        'favorites' => '/favorites',
        'favorite-sellers' => '/favorite-sellers',
        'saved-searches' => '/classifieds/saved-searches',
        'messages' => '/conversations',
        'notifications' => '/notifications',
        'settings' => '/settings',
        'becoming-seller' => '/becoming-seller',
        'edit-profile' => '/profile/edit',
        _ => '/',
      });
    }
  }

  bool _isActive(String section, bool isWide) =>
      isWide && _activeSection == section;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Prijava'),
          actions: const [AppHomeButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Za pristup profilu, oglasima i porudžbinama potrebno je da se prijavite na svoj nalog ili registrujete.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Prijavi se'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final isWide = Breakpoints.useTwoPaneLayout(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Profil'),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 430),
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
                  ProfileDataCard(user: user),
                  const SizedBox(height: 8),
                  if (!user.isGuest) ...[
                    BuyerStatsCard(user: user),
                    const SizedBox(height: 8),
                  ],
                  // SEKCIJA 1: MINI PIJACA (sa blago zelenkastom pozadinom)
                  _buildMiniPijacaSection(context, user, isWide: true),
                  const SizedBox(height: 10),
                  // SEKCIJA 2: OGLASNIK (sve stavke oglasnika na jednom mestu)
                  _buildOglasnikSection(context, user, isWide: true),
                  const SizedBox(height: 10),
                  // SEKCIJA 3: RECENZIJE I OCENE (zajednički ugled)
                  _buildReviewsSection(context, user, isWide: true),
                  const SizedBox(height: 10),
                  // SEKCIJA 4: NALOG I PODEŠAVANJA
                  _buildAccountSection(context, user, isWide: true),
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
            child: Navigator(
              key: _panelNavKey,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const PanelPlaceholder(),
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
    ];
    return ListView(
      padding: EdgeInsets.all(isSmallTablet ? 12 : 8),
      children: [
        ...profileCards,
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 1: MINI PIJACA (sa blago zelenkastom pozadinom)
        _buildMiniPijacaSection(context, user, isWide: false),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 2: OGLASNIK (sve stavke oglasnika na jednom mestu)
        _buildOglasnikSection(context, user, isWide: false),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 3: RECENZIJE I OCENE (zajednički ugled)
        _buildReviewsSection(context, user, isWide: false),
        SizedBox(height: isSmallTablet ? 10 : 8),

        // SEKCIJA 4: NALOG I PODEŠAVANJA
        _buildAccountSection(context, user, isWide: false),
        const SizedBox(height: 60),
      ],
    );
  }

  /// SEKCIJA 1: Sve što ima veze sa Mini pijacom (hrana, gazdinstva, porudžbine)
  /// Upakovano zajedno sa blago zelenkastom pozadinom!
  Widget _buildMiniPijacaSection(BuildContext context, UserModel user,
      {required bool isWide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Blago zelenkasta pozadina prilagođena temi (prirodni ton domaćinstva i hrane)
    final bgColor = isDark ? const Color(0xFF132B1D) : const Color(0xFFEFF8F2);
    final borderColor =
        isDark ? const Color(0xFF1E462E) : const Color(0xFFC7E7D1);
    final headerColor =
        isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ZAGLAVLJE MINI PIJACE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.storefront_rounded,
                      size: 20, color: headerColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MINI PIJACA',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: headerColor,
                        ),
                      ),
                      Text(
                        'Domaća hrana, porudžbine i gazdinstvo',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12, thickness: 0.8),

          // Ako je korisnik prodavac: kartica za njegovu mini prodavnicu
          if (user.isSeller) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: MiniStoreCard(user: user),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.location_on_outlined, color: headerColor),
              title: const Text('Moja lokacija i isporuke na mapi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Podešavanje adrese i tačaka isporuke hrane'),
              onTap: () => _push('/seller-settings'),
            ),
          ],

          // Kupovina na mini pijaci (porudžbine i omiljeno)
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.shopping_bag_outlined, color: headerColor),
            title: const Text('Moje porudžbine hrane',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Praćenje statusa i istorija porudžbina'),
            onTap: () => _push('/orders'),
          ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.favorite_outline, color: headerColor),
            title: const Text('Omiljeni proizvodi'),
            subtitle: const Text('Brzi pristup najdražim proizvodima sa pijace'),
            selected: _isActive('favorites', isWide),
            onTap: () => _openPanel('favorites', const FavoritesScreen(),
                isWide: isWide),
          ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.people_outline, color: headerColor),
            title: const Text('Pratim gazdinstva i prodavce'),
            subtitle: const Text('Obaveštenja o novoj ponudi proizvođača'),
            selected: _isActive('favorite-sellers', isWide),
            onTap: () => _openPanel(
                'favorite-sellers', const FavoriteSellersScreen(),
                isWide: isWide),
          ),

          // Ako korisnik još nije prodavac: ponuda da otvori gazdinstvo
          if (!user.isGuest && !user.isSeller)
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.add_business_outlined, color: headerColor),
              title: const Text('Postani prodavac / Otvori gazdinstvo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle:
                  const Text('Organizovana prodaja domaće hrane na mini pijaci'),
              selected: _isActive('becoming-seller', isWide),
              onTap: () => _openPanel(
                  'becoming-seller', const BecomingSellerScreen(),
                  isWide: isWide),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// SEKCIJA 2: Sve što ima veze sa Oglasnikom
  /// Svi mali oglasi grupisani zajedno i blizu jedno drugog!
  Widget _buildOglasnikSection(BuildContext context, UserModel user,
      {required bool isWide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ZAGLAVLJE OGLASNIKA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.campaign_outlined, size: 20, color: headerColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OGLASNIK',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: headerColor,
                        ),
                      ),
                      Text(
                        'Mali oglasi, ponude i potražnja',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12, thickness: 0.8),

          // Moji oglasi
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.format_list_bulleted_rounded, color: headerColor),
            title: const Text('Moji oglasi',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Pregled, izmena i status objavljenih oglasa'),
            onTap: () {
              if (user.isGuest) {
                showGuestAuthPrompt(
                  context,
                  title: 'Moji oglasi',
                  message:
                      'Kao gost možete slobodno pregledati sve oglase. Da biste upravljali sopstvenim oglasima, potrebno je da se prijavite.',
                  icon: Icons.campaign_outlined,
                );
                return;
              }
              _push('/classifieds/my');
            },
          ),

          // Postavi novi oglas
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.add_circle_outline, color: headerColor),
            title: const Text('Postavi novi oglas',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Besplatna objava novog malog oglasa'),
            onTap: () {
              if (user.isGuest) {
                showGuestAuthPrompt(
                  context,
                  title: 'Postavljanje oglasa',
                  message:
                      'Kao gost možete slobodno pregledati sve oglase. Da biste postavili svoj oglas, potrebno je da se prijavite.',
                  icon: Icons.add_circle_outline,
                );
                return;
              }
              _push('/classifieds/new');
            },
          ),

          // Praćene kategorije i pretrage (sa brojačem)
          ListTile(
            visualDensity: VisualDensity.compact,
            leading:
                Icon(Icons.notifications_active_outlined, color: headerColor),
            title: const Text('Praćene kategorije i pretrage',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Obaveštenja o novim oglasima koji vas zanimaju'),
            selected: _isActive('saved-searches', isWide),
            trailing: () {
              final count =
                  context.watch<ClassifiedsProvider>().subscriptions.length;
              if (count == 0) return null;
              return Badge.count(
                count: count,
                backgroundColor: headerColor,
              );
            }(),
            onTap: () {
              if (user.isGuest) {
                showGuestAuthPrompt(
                  context,
                  title: 'Praćene pretrage',
                  message:
                      'Da biste sačuvali pretrage i dobijali obaveštenja o novim oglasima, potrebno je da se prijavite.',
                  icon: Icons.notifications_active_outlined,
                );
                return;
              }
              _openPanel('saved-searches', const SavedSearchesScreen(),
                  isWide: isWide);
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  /// SEKCIJA 3: Ocene i recenzije (zajednički ugled prodavca i kupca)
  Widget _buildReviewsSection(BuildContext context, UserModel user,
      {required bool isWide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const headerColor = Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.star_outline_rounded,
                    size: 20, color: headerColor),
                SizedBox(width: 8),
                Text(
                  'OCENE I RECENZIJE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: headerColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8, thickness: 0.8),
          if (user.isSeller)
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.rate_review_outlined),
              title: const Text('Recenzije kupaca',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Utisci kupaca za proizvode i male oglase'),
              selected: _isActive('reviews', isWide),
              onTap: () => _openPanel(
                  'reviews', SellerReviewsScreen(sellerId: user.id),
                  isWide: isWide),
            ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.reviews_outlined),
            title: const Text('Moje date recenzije'),
            subtitle: const Text('Utisci koje ste ostavili drugim prodavcima'),
            onTap: () => _push('/buyer/${user.id}/reviews'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// SEKCIJA 4: Nalog i podešavanja
  Widget _buildAccountSection(BuildContext context, UserModel user,
      {required bool isWide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.manage_accounts_outlined,
                    size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'NALOG I PODEŠAVANJA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8, thickness: 0.8),
          if (!user.isGuest) ...[
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Moji lični podaci / Uredi profil',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Izmena imena, broja telefona, grada i adrese'),
              selected: _isActive('edit-profile', isWide),
              onTap: () => _openPanel(
                  'edit-profile', const EditProfileScreen(),
                  isWide: isWide),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Poruke'),
              subtitle: const Text('Direktni razgovori sa kupcima i prodavcima'),
              selected: _isActive('messages', isWide),
              onTap: () => _openPanel('messages', const ConversationsScreen(),
                  isWide: isWide),
            ),
          ],
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Obaveštenja'),
            subtitle: const Text('Nove poruke i statusi'),
            selected: _isActive('notifications', isWide),
            onTap: () => _openPanel(
                'notifications', const NotificationsScreen(),
                isWide: isWide),
          ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Podešavanja'),
            selected: _isActive('settings', isWide),
            onTap: () => _openPanel('settings', const SettingsScreen(),
                isWide: isWide),
          ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.help_outline),
            title: const Text('Podrška i pomoć'),
            onTap: () => _push('/support'),
          ),
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.info_outline),
            title: const Text('O aplikaciji'),
            onTap: () => _push('/about'),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Odjavi se',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Odjavi se?'),
                  content:
                      const Text('Da li ste sigurni da želite da se odjavite?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Odustani'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Odjavi se'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AppState>().authService.signOut();
                if (context.mounted) {
                  context.go('/');
                }
              }
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
