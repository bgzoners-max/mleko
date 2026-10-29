import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../theme_toggle_switch.dart';
import 'publish_chooser_dialog.dart';

/// Akciono dugme sa ikonicom i opcionim bedžom brojača.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final int? badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;

  const HeaderIconButton({
    super.key,
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

/// Desni klaster akcija za desktop zaglavlje:
/// Korpa, Notifikacije, Poruke, Moje porudžbine, Prekidač teme, Korisnički meni / Prijava i CTA "+ Postavi oglas".
class DesktopHeaderActions extends StatelessWidget {
  final bool isDark;
  final bool isGuest;
  final UserModel? user;
  final int cartCount;
  final int unreadCount;
  final void Function(int branchIndex, {required String route}) onNavigateTo;

  const DesktopHeaderActions({
    super.key,
    required this.isDark,
    required this.isGuest,
    required this.user,
    required this.cartCount,
    required this.unreadCount,
    required this.onNavigateTo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Korpa
        HeaderIconButton(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Korpa za narudžbine',
          badgeCount: cartCount,
          badgeColor: AmazonColors.amber,
          onTap: () => context.push('/cart'),
        ),

        // Ako korisnik nije gost: Notifikacije, Poruke, Porudžbine
        if (!isGuest) ...[
          const SizedBox(width: 4),
          HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Obaveštenja',
            badgeCount: unreadCount,
            badgeColor: AmazonColors.dealRed,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
          HeaderIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Poruke',
            onTap: () => onNavigateTo(3, route: '/conversations'),
          ),
          const SizedBox(width: 4),
          HeaderIconButton(
            icon: Icons.receipt_long_outlined,
            tooltip: 'Moje porudžbine',
            onTap: () => onNavigateTo(2, route: '/orders'),
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
                PopupMenuItem(
                  value: 4,
                  child: Row(
                    children: [
                      Icon(Icons.agriculture_rounded, size: 18, color: isDark ? AmazonColors.lightGreen : AmazonColors.green),
                      const SizedBox(width: 10),
                      const Text('Gazdinstvo / Prodavnica', style: TextStyle(fontWeight: FontWeight.w700)),
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
              if (val == 1) onNavigateTo(4, route: '/profile');
              if (val == 2) onNavigateTo(2, route: '/orders');
              if (val == 3) onNavigateTo(3, route: '/conversations');
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

        // Hero CTA Dugme: "+ Postavi oglas" (otvara izbor između hrane i malih oglasa)
        ElevatedButton.icon(
          onPressed: () => showPublishChooserDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFE082),
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
}
