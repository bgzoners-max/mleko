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
import '../widgets/profile/profile_section_header.dart';
import '../widgets/profile/panel_placeholder.dart';
import '../widgets/guest_auth_prompt.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prijava')),
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
      appBar: AppBar(title: const Text('Profil')),
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
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (user.isSeller) ...[
                    SellerProfilePhotoSection(user: user),
                    const SizedBox(height: 6),
                    SellerGallerySection(user: user),
                    const SizedBox(height: 6),
                  ],
                  ProfileDataCard(user: user),
                  const SizedBox(height: 6),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Brži pristup svim važnim stvarima',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Na profilu možeš brzo otvoriti porudžbine, omiljene proizvode, poruke i podešavanja.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!user.isGuest) ...[
                    BuyerStatsCard(user: user),
                    const SizedBox(height: 6),
                  ],
                  if (user.isSeller) ...[
                    MiniStoreCard(user: user),
                    const SizedBox(height: 6),
                  ],
                  Card(
                    child: Column(
                      children: _buildNavItems(context, user, isWide: true),
                    ),
                  ),
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
      if (user.isSeller) SellerProfilePhotoSection(user: user),
      if (user.isSeller) SellerGallerySection(user: user),
      ProfileDataCard(user: user),
      if (!user.isGuest) BuyerStatsCard(user: user),
    ];
    return ListView(
      padding: EdgeInsets.all(isSmallTablet ? 12 : 8),
      children: [
        ...profileCards,
        SizedBox(height: isSmallTablet ? 12 : 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Brži pristup svim važnim stvarima',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Na profilu možeš brzo otvoriti porudžbine, omiljene proizvode, poruke i podešavanja.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: isSmallTablet ? 8 : 4),
        if (user.isSeller) ...[
          MiniStoreCard(user: user),
          SizedBox(height: isSmallTablet ? 8 : 4),
        ],
        ..._buildNavItems(context, user, isWide: false),
      ],
    );
  }

  List<Widget> _buildNavItems(BuildContext context, UserModel user,
      {required bool isWide}) {
    void push(String route) => context.push(route);
    void openPanel(String section, Widget screen) =>
        _showInPanel(section, screen);
    bool isActive(String section) => isWide && _activeSection == section;

    return [
      const ProfileSectionHeader(title: 'KUPOVINA'),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.shopping_bag_outlined),
        title: const Text('Moje porudžbine',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Praćenje statusa i istorija'),
        onTap: () => push('/orders'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.favorite_outline),
        title: const Text('Omiljeni proizvodi'),
        subtitle: const Text('Brzi pristup najdražim proizvodima'),
        selected: isActive('favorites'),
        onTap: () => isWide
            ? openPanel('favorites', const FavoritesScreen())
            : push('/favorites'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.people_outline),
        title: const Text('Pratim prodavce'),
        selected: isActive('favorite-sellers'),
        onTap: () => isWide
            ? openPanel('favorite-sellers', const FavoriteSellersScreen())
            : push('/favorite-sellers'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.rate_review_outlined),
        title: const Text('Moje recenzije'),
        onTap: () => push('/buyer/${user.id}/reviews'),
      ),
      const ProfileSectionHeader(title: 'OGLASNIK'),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.campaign_outlined),
        title: const Text('Moji oglasi',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Pregled, izmena i status vaših oglasa'),
        onTap: () {
          if (user.isGuest) {
            showGuestAuthPrompt(
              context,
              title: 'Moji oglasi',
              message:
                  'Kao gost možete slobodno pregledati sve oglase. Da biste upravljali sopstvenim oglasima, potrebno je da se prijavite na nalog.',
              icon: Icons.campaign_outlined,
            );
            return;
          }
          push('/classifieds/my');
        },
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.notifications_active_outlined),
        title: const Text('Praćene kategorije i pretrage',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Obaveštenja o novim oglasima'),
        selected: isActive('saved-searches'),
        trailing: () {
          final count =
              context.watch<ClassifiedsProvider>().subscriptions.length;
          if (count == 0) return null;
          return Badge.count(
            count: count,
            backgroundColor: Theme.of(context).colorScheme.primary,
          );
        }(),
        onTap: () {
          if (user.isGuest) {
            showGuestAuthPrompt(
              context,
              title: 'Praćene pretrage',
              message:
                  'Da biste sačuvali pretrage i dobijali obaveštenja o novim oglasima, potrebno je da se prijavite na nalog.',
              icon: Icons.notifications_active_outlined,
            );
            return;
          }
          isWide
              ? openPanel('saved-searches', const SavedSearchesScreen())
              : push('/classifieds/saved-searches');
        },
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.add_circle_outline),
        title: const Text('Postavi novi oglas'),
        subtitle: const Text('Besplatna objava oglasa'),
        onTap: () {
          if (user.isGuest) {
            showGuestAuthPrompt(
              context,
              title: 'Postavljanje oglasa',
              message:
                  'Kao gost možete slobodno pregledati sve oglase. Da biste postavili svoj oglas, potrebno je da se prijavite na nalog ili besplatno registrujete.',
              icon: Icons.add_circle_outline,
            );
            return;
          }
          push('/classifieds/new');
        },
      ),
      if (!user.isGuest && !user.isSeller)
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.chat_bubble_outline),
          title: const Text('Poruke'),
          selected: isActive('messages'),
          onTap: () => isWide
              ? openPanel('messages', const ConversationsScreen())
              : push('/conversations'),
        ),
      const SizedBox(height: 8),
      const ProfileSectionHeader(title: 'PRODAVNICA'),
      if (user.isSeller) ...[
        if (!user.isGuest)
          ListTile(
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Poruke'),
            selected: isActive('messages'),
            onTap: () => isWide
                ? openPanel('messages', const ConversationsScreen())
                : push('/conversations'),
          ),
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Moja lokacija na mapi'),
          onTap: () => push('/seller-settings'),
        ),
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.rate_review_outlined),
          title: const Text('Recenzije kupaca'),
          selected: isActive('reviews'),
          onTap: () => isWide
              ? openPanel('reviews', SellerReviewsScreen(sellerId: user.id))
              : push('/seller/${user.id}/reviews'),
        ),
      ] else if (!user.isGuest) ...[
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Postani prodavac / Otvori gazdinstvo'),
          subtitle: const Text('Organizovana prodaja domaće hrane i isporuke'),
          selected: isActive('becoming-seller'),
          onTap: () => isWide
              ? openPanel('becoming-seller', const BecomingSellerScreen())
              : push('/becoming-seller'),
        ),
      ] else ...[
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.person_add_outlined),
          title: const Text('Registruj se'),
          subtitle: const Text('Kupuj hranu, postavljaj oglase i otvori gazdinstvo'),
          onTap: () => push('/register'),
        ),
      ],
      const SizedBox(height: 8),
      const ProfileSectionHeader(title: 'NALOG I PODRŠKA'),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Obaveštenja'),
        subtitle: const Text('Nove poruke i ažuriranja'),
        selected: isActive('notifications'),
        onTap: () => isWide
            ? openPanel('notifications', const NotificationsScreen())
            : push('/notifications'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.settings_outlined),
        title: const Text('Podešavanja'),
        selected: isActive('settings'),
        onTap: () => isWide
            ? openPanel('settings', const SettingsScreen())
            : push('/settings'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.help_outline),
        title: const Text('Podrška i pomoć'),
        onTap: () => push('/support'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.info_outline),
        title: const Text('O aplikaciji'),
        onTap: () => push('/about'),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Odjavi se'),
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
            if (context.mounted) context.go('/login');
          }
        },
      ),
    ];
  }
}
