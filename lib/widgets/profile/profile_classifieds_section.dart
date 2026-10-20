import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/classifieds_provider.dart';
import '../../screens/classifieds/add_edit_classified_ad_screen.dart';
import '../../screens/classifieds/my_classified_ads_screen.dart';
import '../../screens/classifieds/saved_searches_screen.dart';
import '../guest_auth_prompt.dart';
import 'profile_market_section.dart'
    show ProfileOpenPanel, ProfileIsActiveSection;

/// SEKCIJA 2: Sve što ima veze sa Oglasnikom.
/// Svi mali oglasi grupisani zajedno i blizu jedno drugog!
/// Izdvojeno iz `ProfileScreen._buildOglasnikSection` bez izmena logike.
class ProfileClassifiedsSection extends StatelessWidget {
  const ProfileClassifiedsSection({
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

  void _requireLogin(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    showGuestAuthPrompt(context, title: title, message: message, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        type: MaterialType.transparency,
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
                    child: Icon(Icons.campaign_outlined,
                        size: 20, color: headerColor),
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
              leading:
                  Icon(Icons.format_list_bulleted_rounded, color: headerColor),
              title: const Text('Moji oglasi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Pregled, izmena i status objavljenih oglasa'),
              selected: isActiveSection('my-classifieds', isWide),
              onTap: () {
                if (user.isGuest) {
                  _requireLogin(
                    context,
                    title: 'Moji oglasi',
                    message:
                        'Kao gost možete slobodno pregledati sve oglase. Da biste upravljali sopstvenim oglasima, potrebno je da se prijavite.',
                    icon: Icons.campaign_outlined,
                  );
                  return;
                }
                onOpenPanel('my-classifieds', const MyClassifiedAdsScreen(),
                    isWide: isWide);
              },
            ),

            // Postavi novi oglas
            ListTile(
              visualDensity: VisualDensity.compact,
              leading: Icon(Icons.add_circle_outline, color: headerColor),
              title: const Text('Postavi novi oglas',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Besplatna objava novog malog oglasa'),
              selected: isActiveSection('new-classified', isWide),
              onTap: () {
                if (user.isGuest) {
                  _requireLogin(
                    context,
                    title: 'Postavljanje oglasa',
                    message:
                        'Kao gost možete slobodno pregledati sve oglase. Da biste postavili svoj oglas, potrebno je da se prijavite.',
                    icon: Icons.add_circle_outline,
                  );
                  return;
                }
                onOpenPanel('new-classified', const AddEditClassifiedAdScreen(),
                    isWide: isWide);
              },
            ),

            // Praćene kategorije i pretrage (sa brojačem)
            ListTile(
              visualDensity: VisualDensity.compact,
              leading:
                  Icon(Icons.notifications_active_outlined, color: headerColor),
              title: const Text('Praćene kategorije i pretrage',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle:
                  const Text('Obaveštenja o novim oglasima koji vas zanimaju'),
              selected: isActiveSection('saved-searches', isWide),
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
                  _requireLogin(
                    context,
                    title: 'Praćene pretrage',
                    message:
                        'Da biste sačuvali pretrage i dobijali obaveštenja o novim oglasima, potrebno je da se prijavite.',
                    icon: Icons.notifications_active_outlined,
                  );
                  return;
                }
                onOpenPanel('saved-searches', const SavedSearchesScreen(),
                    isWide: isWide);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
