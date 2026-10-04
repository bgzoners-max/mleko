import 'auth_utils.dart';
import '../../providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
class MarketingContent extends StatelessWidget {
  final bool isDesktop;
  const MarketingContent({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zaglavlje brenda sa bedžom
        Row(
          children: [
            Image.asset(
              'assets/images/header_logo.png',
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Domaći market',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Pijaca domaće hrane & Mali oglasi',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withAlpha(50),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined,
                      color: Color(0xFF81C784), size: 13),
                  SizedBox(width: 5),
                  Text(
                    'BEZ PROVIZIJE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Naslov i opis
        Text(
          'Od domaće trpeze do svega za život',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 23,
            height: 1.22,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kupujte autentične seoske delikatese direktno od proizvođača ili oglasite i pronađite bilo šta – besplatno i bez posrednika.',
          style: TextStyle(
            color: Colors.white.withAlpha(225),
            fontSize: 13,
            height: 1.38,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),

        // GLAVNI VIP BANER: 100% BESPLATNO POSTAVLJANJE I OBNAVLJANJE
        const _FreePerksHighlightBar(),
        const SizedBox(height: 16),

        // Celina 1 & 2: Pijaca domaće hrane i Mali oglasi
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 480;

            final cardFood = _ShowcasePillarCard(
              icon: Icons.cottage_rounded,
              badgeText: '100% DOMAĆE',
              badgeColor: const Color(0xFF2E7D32),
              accentColor: const Color(0xFF81C784),
              title: 'Pijaca domaće hrane',
              subtitle: 'Sveže sa seoskih gazdinstava',
              bullets: const [
                'Domaći sir, kajmak, mleko, med i suvo meso',
                'Sezonsko voće, povrće, zimnica i sokovi',
                'Kupovina od seljaka bez posrednika i marži',
              ],
              chips: const [
                '🧀 Sir & kajmak',
                '🍯 Domaći med',
                '🥩 Suvo meso',
                '🍓 Voće i povrće',
                '🍷 Zimnica',
              ],
              actionLabel: 'Istraži Pijacu hrane →',
              onAction: () =>
                  enterAsGuestWithMode(context, MarketMode.foodMarket),
            );

            final cardClassifieds = _ShowcasePillarCard(
              icon: Icons.campaign_rounded,
              badgeText: '0 DIN OBNAVLJANJE',
              badgeColor: const Color(0xFFE65100),
              accentColor: const Color(0xFFFFB74D),
              title: 'Mali oglasi za sve',
              subtitle: 'Kupujte i prodajte bez troškova',
              bullets: const [
                'Mobilni telefoni, tehnika i bela tehnika',
                'Automobili, delovi i poljoprivredne mašine',
                'Nekretnine, nameštaj, alati i usluge',
              ],
              chips: const [
                '🚗 Vozila & delovi',
                '📱 Tehnika & IT',
                '🏠 Nekretnine',
                '🔧 Alati & mašine',
                '🛋️ Nameštaj',
              ],
              actionLabel: 'Pregledaj Male oglase →',
              onAction: () =>
                  enterAsGuestWithMode(context, MarketMode.classifieds),
            );

            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cardFood),
                  const SizedBox(width: 14),
                  Expanded(child: cardClassifieds),
                ],
              );
            } else {
              return Column(
                children: [
                  cardFood,
                  const SizedBox(height: 12),
                  cardClassifieds,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),

        // Bedževi poverenja na dnu
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _MiniTrustChip(
                icon: Icons.verified_outlined, label: 'Bez posrednika'),
            _MiniTrustChip(
                icon: Icons.autorenew_rounded,
                label: '0 Dinara obnavljanje'),
            _MiniTrustChip(
                icon: Icons.handshake_outlined, label: 'Direktan kontakt'),
            _MiniTrustChip(
                icon: Icons.location_on_outlined,
                label: 'Lokalno širom Srbije'),
          ],
        ),
      ],
    );
  }
}

class _FreePerksHighlightBar extends StatelessWidget {
  const _FreePerksHighlightBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF81C784).withAlpha(110),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded,
                    color: Color(0xFF3E2723), size: 13),
                SizedBox(width: 3),
                Text(
                  'ZAUVEK BESPLATNO',
                  style: TextStyle(
                    color: Color(0xFF3E2723),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: _FreePerkColumn(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Besplatno postavljanje',
                  description:
                      'Objavi oglase bez limita i bez plaćanja',
                  iconColor: Color(0xFF81C784),
                ),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withAlpha(40),
              ),
              const Expanded(
                child: _FreePerkColumn(
                  icon: Icons.autorenew_rounded,
                  title: 'Besplatno obnavljanje',
                  description:
                      'Vrati oglas na vrh za 0 dinara kad god poželiš',
                  iconColor: Color(0xFFFFCA28),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreePerkColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const _FreePerkColumn({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withAlpha(190),
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShowcasePillarCard extends StatelessWidget {
  final IconData icon;
  final String badgeText;
  final Color badgeColor;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final List<String> chips;
  final String actionLabel;
  final VoidCallback onAction;

  const _ShowcasePillarCard({
    required this.icon,
    required this.badgeText,
    required this.badgeColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.chips,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(48),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withAlpha(190),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha(60),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Category chips
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: chips
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(24),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withAlpha(38),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: Colors.white.withAlpha(235),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 9),
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
                        color: Colors.white.withAlpha(220),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withAlpha(32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.white.withAlpha(45)),
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

class _MiniTrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniTrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(210),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

