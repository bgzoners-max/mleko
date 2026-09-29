import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/amazon_theme.dart';
import '../core/design_system.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';
import '../widgets/app_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Breakpoints.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('O platformi'),
        actions: const [
          AppHomeButton(),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 16,
                  largeTabletValue: 24,
                  desktop: 28,
                ),
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 32,
                  largeTabletValue: 44,
                  desktop: 52,
                ),
              ),
              child: const _AboutContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  const _AboutContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Breakpoints.isTabletOrLarger(context);
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HERO BANNER
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF142419),
                Color(0xFF245938),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF142419).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97724).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97724).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'ZANATSKA TRADICIJA & SLOBODNA TRGOVINA',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFD9A0),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Domaći Market — Povezujemo selo i grad direktno, bez posrednika',
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 26 : 21,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nacionalna berza autentične domaće hrane sa proverenih seoskih gazdinstava i 100% besplatni mali oglasi širom Srbije.',
                style: TextStyle(
                  fontSize: isTablet ? 15.5 : 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 2. KO SMO MI I ŠTA GRADIMO
        _buildSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ko smo mi i zašto postojimo?',
                style: GoogleFonts.bitter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Verujemo da svako ima pravo da zna tačno od koga kupuje, kako je hrana proizvedena i ko stoji iza svakog proizvoda. Godinama unazad, mala poljoprivredna gazdinstva i zanatlije u Srbiji bili su prepušteni prekupcima i visokim trgovačkim maržama, dok su kupci u gradovima gubili kontakt sa pravim, svežim domaćim ukusima.\n\nIstovremeno, ljudima na selu i u manjim mestima nedostajalo je jednostavno, pošteno i besplatno mesto gde mogu da ponude ili pronađu poljoprivredne mašine, stoku, alate, vozila i opremu za kuću bez plaćanja provizija i skupih oglasnih taksi.\n\nDomaći Market spaja te dve potrebe u jednu jedinstvenu, snažnu zajednicu.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildPillTag(context, Icons.verified_user_outlined, '100% Bez posrednika'),
                  _buildPillTag(context, Icons.payments_outlined, 'Sav novac ide domaćinu'),
                  _buildPillTag(context, Icons.campaign_outlined, '100% Besplatni oglasi'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 3. DVA STUBA PLATFORME
        Text(
          'Dva ključna stuba naše platforme',
          style: GoogleFonts.bitter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 640;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildPillarCard(
                    context: context,
                    icon: Icons.eco,
                    iconColor: const Color(0xFF2E7D32),
                    tagText: 'OD NJIVE DO TRPEZE',
                    title: 'Pijaca domaće hrane sa sela',
                    description:
                        'Povezujemo vas direktno sa seoskim gazdinstvima: sir, kajmak, sveže mleko, vrcani med, ajvar, zimnica, suhomesnati proizvodi, jaja i organsko voće i povrće.',
                    bullets: const [
                      'Bez skladišta — hrana se bere i priprema sveže po prijemu narudžbine',
                      'Prirodne količine prilagođene domaćem proizvodu (korak i minimalna porudžbina)',
                      'Jasno poreklo, lokacija gazdinstva i direktna komunikacija sa proizvođačem',
                    ],
                    buttonLabel: 'Istraži domaću hranu',
                    onButtonPressed: () => context.push('/categories'),
                  ),
                ),
                SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                Expanded(
                  flex: isWide ? 1 : 0,
                  child: _buildPillarCard(
                    context: context,
                    icon: Icons.storefront_outlined,
                    iconColor: const Color(0xFFD97724),
                    tagText: '100% BESPLATNO I BEZ PROVIZIJE',
                    title: 'Nacionalni Mali Oglasi',
                    description:
                        'Otvorena berza za poljoprivrednu mehanizaciju, zanatstvo, tehniku i svakodnevne potrebe širom Srbije bez skrivenih troškova.',
                    bullets: const [
                      'Traktori, priključne mašine, stoka, vozila, građevinski i zanatski alati',
                      'Bela tehnika, oprema za decu i bebe, nameštaj, nekretnine i rukotvorine',
                      'Besplatno postavljanje oglasa i besplatno obnavljanje na vrh pretrage',
                    ],
                    buttonLabel: 'Pogledaj male oglase',
                    onButtonPressed: () => context.push('/classifieds'),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 28),

        // 4. MOGUĆNOSTI I TEHNOLOGIJA U SLUŽBI ČOVEKA
        _buildSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mogućnosti i tehnologija u službi čoveka',
                style: GoogleFonts.bitter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spojili smo jednostavnost tradicionalne pijačne kupovine sa bezbednim i modernim digitalnim alatima:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _buildFeatureRow(
                context,
                Icons.map_outlined,
                'Interaktivna mapa gazdinstava',
                'Jednim klikom pronađite proizvođače u vašoj neposrednoj geografskoj blizini, pogledajte njihovu ponudu i dogovorite posetu gazdinstvu.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.chat_outlined,
                'Bezbedan interni chat (Poruke)',
                'Komunicirajte sa proizvođačima i prodavcima direktno u aplikaciji u realnom vremenu — dogovorite detalje isporuke bez preuranjenog deljenja ličnih podataka.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.shield_outlined,
                'Zaštita privatnosti i protiv spama',
                'Brojevi telefona i osetljivi podaci zaštićeni su od automatskih botova i scraping-a. Korisnik sam bira vidljivost svog broja telefona.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.devices_outlined,
                'Moderna PWA tehnologija',
                'Domaći Market radi trenutno na svim uređajima (telefon, tablet, računar). Možete ga instalirati kao aplikaciju jednim klikom — bez trošenja memorije i bez App Store/Google Play registracija.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.favorite_outline,
                'Praćenje omiljenih gazdinstava',
                'Zaprati omiljena seoska domaćinstva kako bi među prvima saznao kada stignu novi proizvodi, sveže seosko mleko ili sezonsko voće.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 5. NAŠ MANIFEST
        _buildSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Naš manifest — Zašto nam je stalo?',
                style: GoogleFonts.bitter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildManifestItem(
                context,
                '1',
                'Sav novac ide domaćinu',
                'Ne naplaćujemo procenat od vaše domaće hrane niti od prodatih stvari sa oglasa. Svaki dinar koji uložite ide direktno čoveku koji je robu proizveo.',
              ),
              const SizedBox(height: 14),
              _buildManifestItem(
                context,
                '2',
                'Čuvanje domaće tradicije i srpskog sela',
                'Podržavamo opstanak malih seoskih domaćinstava, negovanje tradicionalnih receptura i očuvanje autohtonih sorti i čistog domaćeg ukusa.',
              ),
              const SizedBox(height: 14),
              _buildManifestItem(
                context,
                '3',
                'Transparentnost, poštenje i data reč',
                'Gradimo mesto gde data reč ima težinu, gde su cene javne i jasne, a svaki proizvođač ima svoje ime, prezime i ponosno stoji iza onoga što nudi.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 6. ZAVRŠNI CTA BANNER
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 26 : 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF0EDE5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
              width: 1,
            ),
            boxShadow: AmazonColors.getCardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.handshake_outlined,
                size: 36,
                color: AmazonColors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                'Pridružite se zajednici Domaćeg Marketa',
                textAlign: TextAlign.center,
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bilo da ste seosko gazdinstvo koje želi verne kupce, domaćin koji nudi poljoprivrednu mašinu ili porodica koja svojoj deci želi pravu domaću hranu — Domaći Market je vaša kuća.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF245938),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => withHaptic(() => context.push('/becoming-seller')),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Postani prodavac hrane'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AmazonColors.amberLight : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark ? AmazonColors.amberLight : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => withHaptic(() => context.push('/classifieds/new')),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Postavi besplatan oglas'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required Color cardBg,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: child,
    );
  }

  Widget _buildPillTag(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B241E) : const Color(0xFFE8EFEA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF245938).withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF245938)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF99D19C) : const Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String tagText,
    required String title,
    required String description,
    required List<String> bullets,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor = isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.bitter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: iconColor,
                side: BorderSide(color: iconColor.withValues(alpha: 0.6), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => withHaptic(onButtonPressed),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF245938).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF245938)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManifestItem(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFD97724).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD97724).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD97724),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
