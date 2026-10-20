import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../screens/about_screen.dart';
import '../../screens/conversations_screen.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/notifications_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/support_screen.dart';
import 'profile_market_section.dart'
    show ProfileOpenPanel, ProfileIsActiveSection;

/// SEKCIJA 4: Nalog i podešavanja.
/// Izdvojeno iz `ProfileScreen._buildAccountSection` bez izmena logike.
class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
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
                subtitle:
                    const Text('Izmena imena, broja telefona, grada i adrese'),
                selected: isActiveSection('edit-profile', isWide),
                onTap: () => onOpenPanel(
                    'edit-profile', const EditProfileScreen(),
                    isWide: isWide),
              ),
              ListTile(
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Poruke'),
                subtitle:
                    const Text('Direktni razgovori sa kupcima i prodavcima'),
                selected: isActiveSection('messages', isWide),
                onTap: () => onOpenPanel(
                    'messages', const ConversationsScreen(),
                    isWide: isWide),
              ),
            ],
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Obaveštenja'),
              subtitle: const Text('Nove poruke i statusi'),
              selected: isActiveSection('notifications', isWide),
              onTap: () => onOpenPanel(
                  'notifications', const NotificationsScreen(),
                  isWide: isWide),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Podešavanja'),
              selected: isActiveSection('settings', isWide),
              onTap: () => onOpenPanel('settings', const SettingsScreen(),
                  isWide: isWide),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.help_outline),
              title: const Text('Podrška i pomoć'),
              selected: isActiveSection('support', isWide),
              onTap: () => onOpenPanel(
                'support',
                const SupportScreen(),
                isWide: isWide,
              ),
            ),
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.info_outline),
              title: const Text('O aplikaciji'),
              selected: isActiveSection('about', isWide),
              onTap: () => onOpenPanel(
                'about',
                const AboutScreen(),
                isWide: isWide,
              ),
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
                    content: const Text(
                        'Da li ste sigurni da želite da se odjavite?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Odustani')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Odjavi se')),
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
      ),
    );
  }
}
