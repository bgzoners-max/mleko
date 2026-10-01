import 'auth_utils.dart';
import '../../providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
class MobileHeroSection extends StatelessWidget {
  const MobileHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF021B0B),
            Color(0xFF072C15),
            Color(0xFF0E4521),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/header_logo.png',
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Domaći market',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                    Text(
                      'Pijaca hrane & Mali oglasi',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(50),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Color(0xFF81C784), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'BEZ PROVIZIJE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // VIP BANER ZA MOBILNI (kompaktan i pregledan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF81C784).withAlpha(110),
                width: 0.8,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 14),
                SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '100% BESPLATNO POSTAVLJANJE I OBNAVLJANJE OGLASA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MobileShowcaseSection extends StatelessWidget {
  const MobileShowcaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= 580;

          final foodCard = MobileShowcaseCard(
            isDark: isDark,
            icon: Icons.cottage_rounded,
            badgeText: '100% DOMAĆE',
            badgeColor: const Color(0xFF2E7D32),
            accentColor: const Color(0xFF2E7D32),
            title: 'Pijaca domaće hrane',
            subtitle: 'Direktno sa seoskih gazdinstava',
            chips: const [
              '🧀 Sir & kajmak',
              '🍯 Med',
              '🥩 Suvo meso',
              '🍓 Voće & povrće',
              '🍷 Zimnica',
            ],
            bullets: const [
              'Autentični domaći proizvodi lokalnih gazdinstava',
              'Direktna kupovina bez posrednika i marži',
            ],
            actionLabel: 'Istraži Pijacu hrane →',
            onAction: () =>
                enterAsGuestWithMode(context, MarketMode.foodMarket),
          );

          final classifiedsCard = MobileShowcaseCard(
            isDark: isDark,
            icon: Icons.campaign_rounded,
            badgeText: '0 DIN OBNAVLJANJE',
            badgeColor: const Color(0xFFE65100),
            accentColor: const Color(0xFFE65100),
            title: 'Mali oglasi za sve',
            subtitle: 'Kupujte i prodajte bez ikakvih troškova',
            chips: const [
              '🚗 Vozila',
              '📱 Tehnika',
              '🏠 Nekretnine',
              '🔧 Alati',
              '🛋️ Nameštaj',
            ],
            bullets: const [
              '100% besplatno postavljanje bez limita',
              'Besplatno obnavljanje i vraćanje na vrh',
            ],
            actionLabel: 'Pregledaj Male oglase →',
            onAction: () =>
                enterAsGuestWithMode(context, MarketMode.classifieds),
          );

          return Column(
            children: [
              const Divider(),
              const SizedBox(height: 14),
              Text(
                'Zašto izabrati Domaći market?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Brzo, jednostavno i 100% bez provizije',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              if (sideBySide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: foodCard),
                      const SizedBox(width: 12),
                      Expanded(child: classifiedsCard),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    foodCard,
                    const SizedBox(height: 12),
                    classifiedsCard,
                  ],
                ),
              const SizedBox(height: 18),
              // Bedževi poverenja
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  MobileTrustBadge(
                      icon: Icons.verified_outlined,
                      label: 'Bez posrednika',
                      isDark: isDark),
                  MobileTrustBadge(
                      icon: Icons.autorenew_rounded,
                      label: '0 Din obnavljanje',
                      isDark: isDark),
                  MobileTrustBadge(
                      icon: Icons.handshake_outlined,
                      label: 'Direktan kontakt',
                      isDark: isDark),
                  MobileTrustBadge(
                      icon: Icons.location_on_outlined,
                      label: 'Širom Srbije',
                      isDark: isDark),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class MobileShowcaseCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<String> chips;
  final List<String> bullets;
  final String actionLabel;
  final VoidCallback onAction;

  const MobileShowcaseCard({super.key,
    required this.isDark,
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.bullets,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E241F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2EBE2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isDark ? Colors.white : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: badgeColor.withAlpha(80),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          // Chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(15)
                            : const Color(0xFFF3F6F3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: accentColor,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                backgroundColor: accentColor.withAlpha(isDark ? 30 : 15),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 12),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MobileTrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const MobileTrustBadge({super.key,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2EBE2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

