import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/design_system.dart';
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

import '../widgets/profile/mini_store_card.dart';
import '../widgets/profile/buyer_stats_card.dart';
import '../widgets/profile/seller_profile_photo_section.dart';
import '../widgets/profile/seller_gallery_section.dart';
import '../widgets/profile/profile_data_card.dart';
import '../widgets/profile/profile_section_header.dart';
import '../widgets/profile/panel_placeholder.dart';

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
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Niste prijavljeni.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Prijavi se'),
              ),
            ],
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
        title: const Text('Moje porudžbine', style: TextStyle(fontWeight: FontWeight.w600)),
        onTap: () => push('/orders'),
      ),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.favorite_outline),
        title: const Text('Omiljeni proizvodi'),
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
          title: const Text('Postani prodavac'),
          selected: isActive('becoming-seller'),
          onTap: () => isWide
              ? openPanel('becoming-seller', const BecomingSellerScreen())
              : push('/becoming-seller'),
        ),
      ] else ...[
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.info_outline),
          title: const Text('Registruj se za prodaju'),
          onTap: () => push('/register'),
        ),
      ],
      
      const SizedBox(height: 8),
      const ProfileSectionHeader(title: 'NALOG I PODRŠKA'),
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Obaveštenja'),
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
