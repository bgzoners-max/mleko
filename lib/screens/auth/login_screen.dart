import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/web_seo.dart';
import '../../models/app_error.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/error_dialog.dart';
import '../../widgets/beta_announcement_banner.dart';

Future<void> _enterAsGuestWithMode(
    BuildContext context, MarketMode mode) async {
  final appState = context.read<AppState>();
  unawaited(context.read<AppSettingsProvider>().setMarketMode(mode));
  await appState.authService.ensureCleanSession();
  if (context.mounted) {
    try {
      context.go('/');
    } catch (_) {}
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isDark = theme.brightness == Brightness.dark;

    setPageMetadata(
      title: 'Prijava | Pijaca hrane & Mali oglasi | Domaći Market',
      description:
          'Prijavite se na Domaći Market – berzu domaće hrane sa gazdinstava i besplatni oglasnik za sve i svašta (tehnika, vozila, nekretnine, alati). 100% besplatno postavljanje i obnavljanje oglasa.',
      path: '/login',
    );

    if (isDesktop) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Prijava'),
          actions: const [AppHomeButton()],
        ),
        body: Column(
          children: [
            const BetaAnnouncementBanner(),
            Expanded(
              child: Row(
                children: [
                  // Levi panel: Prezentacija platforme (Glassmorphism Showcase)
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF021B0B), // Najdublja smaragdna
                            Color(0xFF072C15), // Šumska zelena
                            Color(0xFF0E4521), // Topla priroda
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Ambijentalni sjaj 1 (gornji levi)
                          Positioned(
                            top: -90,
                            left: -90,
                            child: Container(
                              width: 380,
                              height: 380,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF2E7D32).withAlpha(85),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Ambijentalni sjaj 2 (donji desni)
                          Positioned(
                            bottom: 20,
                            right: -70,
                            child: Container(
                              width: 400,
                              height: 400,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFB300).withAlpha(45),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Sadržaj
                          const Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 36, vertical: 28),
                              child: MarketingContent(isDesktop: true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Desni panel: Forma za prijavu u fokusiranoj kartici
                  Expanded(
                    flex: 5,
                    child: Container(
                      color: isDark
                          ? theme.scaffoldBackgroundColor
                          : const Color(0xFFF7FAF7),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 32),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFE2EBE2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(isDark ? 55 : 14),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Dobrodošli nazad',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurface,
                                      letterSpacing: -0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Prijavite se na svoj nalog',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 26),
                                  const _LoginForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
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

    // Mobilni i tablet prikaz (Mobile First)
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Prijava'),
        actions: const [AppHomeButton()],
      ),
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF9F6F0),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const BetaAnnouncementBanner(),
              const _MobileHeroSection(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isDark ? Colors.white12 : const Color(0xFFE2EBE2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 45 : 12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Dobrodošli nazad',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.4,
                            fontSize: 21,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prijavite se na svoj nalog',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 22),
                        const _LoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
              const _MobileShowcaseSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

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
                  _enterAsGuestWithMode(context, MarketMode.foodMarket),
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
                  _enterAsGuestWithMode(context, MarketMode.classifieds),
            );

            if (sideBySide) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardFood),
                    const SizedBox(width: 14),
                    Expanded(child: cardClassifieds),
                  ],
                ),
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
      padding: const EdgeInsets.all(14),
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
              padding: const EdgeInsets.only(bottom: 4),
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
          const Spacer(),
          const SizedBox(height: 8),
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

class _MobileHeroSection extends StatelessWidget {
  const _MobileHeroSection();

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

class _MobileShowcaseSection extends StatelessWidget {
  const _MobileShowcaseSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide = constraints.maxWidth >= 580;

          final foodCard = _MobileShowcaseCard(
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
                _enterAsGuestWithMode(context, MarketMode.foodMarket),
          );

          final classifiedsCard = _MobileShowcaseCard(
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
                _enterAsGuestWithMode(context, MarketMode.classifieds),
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
                  _MobileTrustBadge(
                      icon: Icons.verified_outlined,
                      label: 'Bez posrednika',
                      isDark: isDark),
                  _MobileTrustBadge(
                      icon: Icons.autorenew_rounded,
                      label: '0 Din obnavljanje',
                      isDark: isDark),
                  _MobileTrustBadge(
                      icon: Icons.handshake_outlined,
                      label: 'Direktan kontakt',
                      isDark: isDark),
                  _MobileTrustBadge(
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

class _MobileShowcaseCard extends StatelessWidget {
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

  const _MobileShowcaseCard({
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

class _MobileTrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _MobileTrustBadge({
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

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;
  final bool _guestLoading = false;

  // Zaštita od brute-force pogađanja lozinki
  int _failedAttempts = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;
  bool get _isLockedOut => _lockoutSeconds > 0;
  static const int _maxFailedAttempts = 5;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startLockout(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSeconds = seconds;
      _error =
          'Previše neuspešnih pokušaja. Sačekajte $seconds sekundi pre ponovnog pokušaja.';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _error = null;
        });
      } else {
        setState(() {
          _lockoutSeconds--;
          _error =
              'Previše neuspešnih pokušaja. Sačekajte $_lockoutSeconds sekundi pre ponovnog pokušaja.';
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_isLockedOut) {
      setState(() => _error =
          'Previše neuspešnih pokušaja. Sačekajte $_lockoutSeconds sekundi pre ponovnog pokušaja.');
      return;
    }

    setState(() => _error = null);
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Unesite email i lozinku.');
      return;
    }
    context.read<AppState>().setLoading(true);
    try {
      await context.read<AppState>().authService.signInWithEmail(
            _email.text.trim(),
            _password.text,
          );
      _failedAttempts = 0;
      _lockoutTimer?.cancel();
      _lockoutSeconds = 0;
      if (mounted) context.go('/');
    } on Exception catch (e) {
      if (mounted) {
        _failedAttempts++;
        if (_failedAttempts >= _maxFailedAttempts) {
          _startLockout(30);
        }
        final errorMsg = _formatAuthError(e);
        setState(() => _error = errorMsg);
        final error = AppError.from(e,
            stackTrace: StackTrace.current, userMessage: errorMsg);
        await ErrorDialog.show(context,
            error: error, onRetry: _isLockedOut ? null : _submit);
      }
    } finally {
      if (mounted) context.read<AppState>().setLoading(false);
    }
  }

  Future<void> _guestWithMode(MarketMode mode) async {
    unawaited(context.read<AppSettingsProvider>().setMarketMode(mode));
    await _guest();
  }

  Future<void> _guest() async {
    final appState = context.read<AppState>();
    if (appState.authService.currentSupabaseUser?.isAnonymous == true) {
      try {
        await appState.authService.signOut();
      } catch (_) {}
    }
    if (mounted) {
      try {
        context.go('/');
      } catch (_) {}
    }
  }

  String _formatAuthError(Exception e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid') ||
        msg.contains('wrong') ||
        msg.contains('credentials') ||
        msg.contains('email not confirmed') ||
        msg.contains('user not found')) {
      return 'Pogrešan email ili lozinka.';
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return 'Nalog sa ovim email-om već postoji.';
    }
    if (msg.contains('network') ||
        msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('failed to fetch') ||
        msg.contains('xmlhttprequest')) {
      return 'Nema internet veze. Proveri konekciju i pokušaj ponovo.';
    }
    if (msg.contains('too many') || msg.contains('rate limit')) {
      return 'Previše pokušaja. Sačekaj nekoliko minuta i pokušaj ponovo.';
    }
    return 'Prijava nije uspela. Pokušaj ponovo.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAppLoading = context.watch<AppState>().isLoading;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            enabled: !_isLockedOut && !isAppLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'primer@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E241F) : const Color(0xFFF6F8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
              ),
            ),
            onSubmitted: (_) => _isLockedOut || isAppLoading ? null : _submit(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            enabled: !_isLockedOut && !isAppLoading,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Lozinka',
              prefixIcon: const Icon(Icons.lock_outline),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF1E241F) : const Color(0xFFF6F8F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD6DFD6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
              ),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Prikaži lozinku' : 'Sakrij lozinku',
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: _isLockedOut || isAppLoading
                    ? null
                    : () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _isLockedOut || isAppLoading ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLockedOut || isAppLoading
                  ? null
                  : () {
                      if (_email.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Unesite email za reset lozinke')),
                        );
                        return;
                      }
                      context
                          .read<AppState>()
                          .authService
                          .sendPasswordReset(_email.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Link za reset je poslat na email')),
                      );
                    },
              child: Text(
                'Zaboravljena lozinka?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_isLockedOut || isAppLoading) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isAppLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isLockedOut
                        ? 'Pokušajte ponovo za $_lockoutSeconds s'
                        : 'Prijavi se',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ili',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),

          // Dva privlačna tastera za izbor režima kao gost
          Row(
            children: [
              Expanded(
                child: _GuestQuickCard(
                  icon: Icons.cottage_rounded,
                  title: 'Pijaca hrane',
                  subtitle: 'Domaće sa sela',
                  color: const Color(0xFF2E7D32),
                  isLoading: _guestLoading,
                  onTap: () => _guestWithMode(MarketMode.foodMarket),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GuestQuickCard(
                  icon: Icons.campaign_rounded,
                  title: 'Mali oglasi',
                  subtitle: 'Besplatno',
                  color: const Color(0xFFE65100),
                  isLoading: _guestLoading,
                  onTap: () => _guestWithMode(MarketMode.classifieds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _guestLoading ? null : _guest,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
              ),
              child: _guestLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(
                      'Pregledaj sajt bez prijave →',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Nemaš nalog?',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Registruj se',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B5E20))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                  fontSize: 11,
                ),
                children: [
                  const TextSpan(text: 'Nastavkom prijave prihvatate naše '),
                  TextSpan(
                    text: 'Uslove korišćenja',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/uslovi-koriscenja'),
                  ),
                  const TextSpan(text: ' i '),
                  TextSpan(
                    text: 'Politiku privatnosti',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/politika-privatnosti'),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestQuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _GuestQuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? color.withAlpha(35) : color.withAlpha(16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? color.withAlpha(90) : color.withAlpha(65),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isDark ? Colors.white : theme.colorScheme.onSurface,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
