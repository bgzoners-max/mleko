import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/amazon_theme.dart';
import '../core/design_system.dart';
import '../core/haptic.dart';
import '../core/responsive.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/about/about_section_helpers.dart';

/// Javni vodič za proizvođače hrane: objašnjava razliku između Pijace
/// (prodaja domaće hrane) i Malih oglasa (besplatni oglasnik za sve
/// ostalo) i korak-po-korak proces postavljanja proizvoda na sajt.
class SellerGuideScreen extends StatelessWidget {
  const SellerGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = Breakpoints.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AmazonColors.getCanvas(context),
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Kako postaviti proizvode'),
        actions: const [
          AppHomeButton(),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
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
              child: const Column(
                children: [
                  _SellerGuideContent(),
                  SizedBox(height: 24),
                  AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SellerGuideContent extends StatelessWidget {
  const _SellerGuideContent();

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
          padding: EdgeInsets.all(isTablet ? 30 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF142419),
                Color(0xFF245938),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
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
                  'VODIČ ZA PROIZVOĐAČE DOMAĆE HRANE',
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
                'Izložite svoje proizvode na Pijaci domacimarket.rs — besplatno',
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 26 : 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Domaći Market ima dva dela: Pijacu domaće hrane, gde proizvođači izlazu svoje proizvode i primaju porudžbine, i besplatne Male oglase, namenjene svemu ostalom — mehanizaciji, vozilima, alatima, nekretninama. Ovaj vodič objašnjava razliku i vodi vas kroz postavljanje ponude u nekoliko jednostavnih koraka.',
                style: TextStyle(
                  fontSize: isTablet ? 15.5 : 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  aboutPillTag(context, Icons.payments_outlined, '0 dinara provizije'),
                  aboutPillTag(context, Icons.verified_outlined, 'Direktno od gazdinstva'),
                  aboutPillTag(context, Icons.storefront_outlined, 'Online tezga 24/7'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 2. PIJACA VS MALI OGLASI
        aboutSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pijaca ili Mali oglasi — gde šta ide?',
                style: GoogleFonts.bitter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Najčešće pitanje koje dobijamo: „Na šta se tačno odnose oglasi, a na šta pijaca?" Odgovor je jednostavan — zavisi od toga šta prodajete.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 560;
                  final cards = [
                    _TwoSidesCard(
                      context: context,
                      cardBg: cardBg,
                      accentColor: const Color(0xFF245938),
                      badgeIcon: Icons.storefront_rounded,
                      title: 'Pijaca domaće hrane',
                      subtitle: 'Za proizvođače i gazdinstva koja redovno prodaju hranu',
                      bullets: const [
                        'Svako gazdinstvo ima svoj prodajni profil (tezgu) sa opisom, lokacijom i ocenama',
                        'Proizvodi imaju cenu, količinu i mernu jedinicu — kilogram, tegla, litar, veza...',
                        'Kupci dodaju proizvode u korpu i šalju porudžbinu direktno gazdinstvu',
                        'Namirnice se pripremaju sveže, tek po potvrđenoj porudžbini',
                      ],
                      ctaLabel: 'Pogledaj Pijacu',
                      ctaRoute: '/categories',
                    ),
                    _TwoSidesCard(
                      context: context,
                      cardBg: cardBg,
                      accentColor: const Color(0xFFD97724),
                      badgeIcon: Icons.campaign_rounded,
                      title: 'Mali oglasi (100% besplatno)',
                      subtitle: 'Za sve što nije hrana — jednostavno oglasi i dogovori se',
                      bullets: const [
                        'Traktori, poljoprivredne mašine, alati, vozila, bela tehnika...',
                        'Nekretnine, nameštaj, stvari za decu, oprema, domaće životinje, usluge',
                        'Postavljanje i obnavljanje oglasa uvek košta 0 dinara',
                        'Kupci vas kontaktiraju direktno — bez posrednika i provizije',
                      ],
                      ctaLabel: 'Pogledaj oglase',
                      ctaRoute: '/classifieds',
                    ),
                  ];
                  if (wide) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      cards[0],
                      const SizedBox(height: 14),
                      cards[1],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              _GoldenRuleCallout(isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 3. KORAK PO KORAK
        aboutComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: const Color(0xFF245938).withValues(alpha: isDark ? 0.4 : 0.3),
          accentColor: const Color(0xFF245938),
          tagText: 'PET KORAKA DO SVOJE ONLINE TEZGE',
          badgeIcon: Icons.storefront_rounded,
          title: 'Kako postaviti proizvode na sajt — korak po korak',
          subtitle:
              'Ceo proces traje nekoliko minuta i potpuno je besplatan. Ne trebaju vam ništa drugo do interneta i fotografija vaših proizvoda.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutManifestItem(
                context,
                '1',
                'Registrujte besplatan nalog',
                'Otvorite aplikaciju ili sajt domacimarket.rs i registrujte se e-mail adresom. Potvrdite e-mail i prijavite se — to je sve što treba da biste počeli.',
              ),
              const SizedBox(height: 12),
              aboutManifestItem(
                context,
                '2',
                'Otvorite prodavnički profil — „Postani prodavac"',
                'U profilu izaberite opciju „Postani prodavac". Unesite naziv gazdinstva, mesto i telefon — time otvarate svoju tezgu na Pijaci. Kasnije možete dopuniti profil: opis gazdinstva, tačnu lokaciju na mapi i fotografije.',
              ),
              const SizedBox(height: 12),
              aboutManifestItem(
                context,
                '3',
                'Dodajte proizvode',
                'Kliknite „Dodaj proizvod" za svaki proizvod: fotografije, naziv, opis, kategoriju (mlečni proizvodi, med, meso, zimnica...), cenu i mernu jedinicu. Proizvod odmah postaje vidljiv na Pijaci.',
              ),
              const SizedBox(height: 12),
              aboutManifestItem(
                context,
                '4',
                'Primajte porudžbine i upite',
                'Kupci pronalaze vaše proizvode kroz kategorije, pretragu i mapu gazdinstava, dodaju ih u korpu i šalju porudžbinu. Porudžbina je upit — vi potvrđujete količinu, termin i način preuzimanja ili dostave.',
              ),
              const SizedBox(height: 12),
              aboutManifestItem(
                context,
                '5',
                'Pripremite, isporučite i naplatite direktno',
                'Hrana se priprema sveže po porudžbini. Dogovarate se direktno sa kupcem o isporuci (lično preuzimanje ili dostava) i naplati — platforma ne uzima nikakvu proviziju ni maržu.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 4. ČESTA PITANJA
        aboutSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutSubsectionHeader(
                context,
                Icons.help_outline_rounded,
                'Česta pitanja proizvođača',
                const Color(0xFF245938),
              ),
              const SizedBox(height: 16),
              aboutFeatureRow(
                context,
                Icons.payments_outlined,
                'Koliko košta izlaganje proizvoda?',
                'Ništa. Otvaranje prodavničkog profila, dodavanje proizvoda i primanje porudžbina su potpuno besplatni — bez provizije, pretplate ili skrivenih troškova.',
              ),
              const SizedBox(height: 14),
              aboutFeatureRow(
                context,
                Icons.rule_folder_outlined,
                'Mogu li hranu da objavim kao mali oglas?',
                'Ne — domaća hrana se izlaže isključivo na Pijaci, gde kupci mogu da je naruče sa cenom, količinom i ocenama gazdinstva. Mali oglasi su namenjeni mehanizaciji, vozilima, alatima, nekretninama i ostalim stvarima.',
              ),
              const SizedBox(height: 14),
              aboutFeatureRow(
                context,
                Icons.agriculture_rounded,
                'Šta ako prodajem i traktor ili mašine?',
                'Savršeno — pored tezge na Pijaci, besplatno postavite male oglase u kategoriji „Poljoprivreda" za mehanizaciju, opremu i stoku. Mnogi domaćini koriste oba dela platforme.',
              ),
              const SizedBox(height: 14),
              aboutFeatureRow(
                context,
                Icons.map_outlined,
                'Kako će kupci pronaći moje gazdinstvo?',
                'Kroz kategorije Pijace, pretragu po nazivu i mestu, kao i interaktivnu mapu gazdinstava — kupci iz vaše okoline lako pronalaze najbliže domaće proizvođače.',
              ),
              const SizedBox(height: 14),
              aboutFeatureRow(
                context,
                Icons.local_shipping_outlined,
                'Ko organizuje isporuku i naplatu?',
                'Vi, direktno sa kupcem — lično preuzimanje na gazdinstvu ili dogovorena dostava. Platforma vas povezuje i omogućava komunikaciju, ali ne učestvuje u naplati.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 5. ZATVARANJE — CTA
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
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.agriculture_rounded,
                size: 42,
                color: AmazonColors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                'Spremni da otvorite svoju tezgu?',
                textAlign: TextAlign.center,
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 23 : 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Registrujte se, otvorite prodavnički profil i danas izložite svoje domaće proizvode kupcima širom Srbije — potpuno besplatno.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 22),
              const _GuideCtaButtons(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Istaknuta poruka „Zlatno pravilo" — hrana ide na Pijacu, ne u oglase.
class _GoldenRuleCallout extends StatelessWidget {
  final bool isDark;

  const _GoldenRuleCallout({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD97724).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD97724).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 22, color: Color(0xFFD97724)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zlatno pravilo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ako ste ga proizveli i to je hrana — sir, kajmak, med, meso, zimnica, rakija, jaja — ide na Pijacu. Ako prodajete stvar ili mašinu jednom (traktor, telefon, nameštaj) — to je mali oglas. Hrana se ne objavljuje kao mali oglas, već isključivo kroz vaš prodavnički profil na Pijaci.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
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

/// CTA dugmad na dnu vodiča (Postani prodavac / Pijaca / Mali oglasi).
class _GuideCtaButtons extends StatelessWidget {
  const _GuideCtaButtons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97724),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => withHaptic(() => context.push('/becoming-seller')),
          icon: const Icon(Icons.add_business_outlined, size: 18),
          label: const Text('Postani prodavac', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF245938),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => withHaptic(() => context.push('/categories')),
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: const Text('Pogledaj Pijacu', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => withHaptic(() => context.push('/classifieds')),
          icon: const Icon(Icons.campaign_rounded, size: 18),
          label: const Text('Mali oglasi', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

/// Kartica „Pijaca" ili „Mali oglasi" u sekciji poređenja.
class _TwoSidesCard extends StatelessWidget {
  final BuildContext context;
  final Color cardBg;
  final Color accentColor;
  final IconData badgeIcon;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final String ctaLabel;
  final String ctaRoute;

  const _TwoSidesCard({
    required this.context,
    required this.cardBg,
    required this.accentColor,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.ctaLabel,
    required this.ctaRoute,
  });

  @override
  Widget build(BuildContext buildContext) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(badgeIcon, size: 22, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.bitter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_outline_rounded,
                        size: 15, color: accentColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => withHaptic(() => context.push(ctaRoute)),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                ctaLabel,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
