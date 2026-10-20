import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import 'mini_store_card.dart';
import '../../screens/favorite_sellers_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/seller/seller_settings_screen.dart';
import '../../screens/tab_orders_or_inbox_screen.dart';

/// Zajednički potpis navigacije profila: otvara odeljku.
/// [section] je ključ aktivne sekcije, [screen] ciljani ekran,
/// [isWide] određuje panel vs push navigaciju, [route] opciona eksplicitna ruta.
typedef ProfileOpenPanel = void Function(
  String section,
  Widget screen, {
  required bool isWide,
  String? route,
});

/// Zajednički potpis provere aktivne sekcije na širokom layoutu.
typedef ProfileIsActiveSection = bool Function(String section, bool isWide);

/// SEKCIJA 1: Sve što ima veze sa Mini pijacom (hrana, gazdinstva, porudžbine).
/// Upakovano zajedno sa blago zelenkastom pozadinom.
/// Izdvojeno iz `ProfileScreen._buildMiniPijacaSection` bez izmena logike.
class ProfileMarketSection extends StatelessWidget {
  const ProfileMarketSection({
    super.key,
    required this.user,
    required this.isWide,
    required this.onOpenPanel,
    required this.isActiveSection,
  });

  final UserModel user;
  final bool isWide;
  final ProfileOpenPanel onOpenPanel;
  final ProfileIsActiveSection isActiveSection;

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        type: MaterialType.transparency,
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
              _SellerMapTile(
                headerColor: headerColor,
                selected: isActiveSection('seller-settings', isWide),
                onTap: () => onOpenPanel(
                  'seller-settings',
                  const SellerSettingsScreen(),
                  isWide: isWide,
                ),
              ),
            ],
            _MiniPijacaTile(
              headerColor: headerColor,
              icon: Icons.shopping_bag_outlined,
              title: 'Moje porudžbine hrane',
              subtitle: 'Praćenje statusa i istorija porudžbina',
              selected: isActiveSection('orders', isWide),
              onTap: () => onOpenPanel(
                'orders',
                const TabOrdersOrInboxScreen(),
                isWide: isWide,
              ),
            ),
            _MiniPijacaTile(
              headerColor: headerColor,
              icon: Icons.favorite_outline,
              title: 'Omiljeni proizvodi',
              subtitle: 'Brzi pristup najdražim proizvodima sa pijace',
              selected: isActiveSection('favorites', isWide),
              onTap: () => onOpenPanel('favorites', const FavoritesScreen(),
                  isWide: isWide),
            ),
            _MiniPijacaTile(
              headerColor: headerColor,
              icon: Icons.people_outline,
              title: 'Pratim gazdinstva i prodavce',
              subtitle: 'Obaveštenja o novoj ponudi proizvođača',
              selected: isActiveSection('favorite-sellers', isWide),
              onTap: () => onOpenPanel(
                  'favorite-sellers', const FavoriteSellersScreen(),
                  isWide: isWide),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _SellerMapTile extends StatelessWidget {
  const _SellerMapTile({
    required this.headerColor,
    required this.selected,
    required this.onTap,
  });

  final Color headerColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(Icons.location_on_outlined, color: headerColor),
      title: const Text('Moja lokacija i isporuke na mapi',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('Podešavanje adrese i tačaka isporuke hrane'),
      selected: selected,
      onTap: onTap,
    );
  }
}

class _MiniPijacaTile extends StatelessWidget {
  const _MiniPijacaTile({
    required this.headerColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Color headerColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: headerColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      selected: selected,
      onTap: onTap,
    );
  }
}
