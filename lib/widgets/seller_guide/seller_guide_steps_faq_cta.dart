import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../about/about_section_helpers.dart';

class SellerGuideStepsFaqAndCtaSection extends StatelessWidget {
  const SellerGuideStepsFaqAndCtaSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Breakpoints.isTabletOrLarger(context);
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;
    final borderColor =
        isDark ? AmazonColors.darkBorder : AmazonColors.borderGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3. KORAK PO KORAK
        aboutComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor:
              const Color(0xFF245938).withValues(alpha: isDark ? 0.4 : 0.3),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () =>
              withHaptic(() => context.push('/becoming-seller')),
          icon: const Icon(Icons.add_business_outlined, size: 18),
          label: const Text('Postani prodavac',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF245938),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => withHaptic(() => context.push('/categories')),
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: const Text('Pogledaj Pijacu',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => withHaptic(() => context.push('/classifieds')),
          icon: const Icon(Icons.campaign_rounded, size: 18),
          label: const Text('Mali oglasi',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
