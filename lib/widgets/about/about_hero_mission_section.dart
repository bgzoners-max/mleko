import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/amazon_theme.dart';
import '../../core/responsive.dart';
import 'about_section_helpers.dart';

class AboutHeroAndMissionSection extends StatelessWidget {
  const AboutHeroAndMissionSection({super.key});

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97724).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD97724).withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'JEDINSTVENA NACIONALNA PLATFORMA U SRBIJI',
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
                'Domaći Market — Pijaca domaće hrane & 100% besplatni mali oglasi',
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 27 : 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jedinstvena platforma koja spaja proverenu hranu sa seoskih gazdinstava i slobodnu nacionalnu oglasnu berzu bez posrednika, provizija i skrivenih troškova.',
                style: TextStyle(
                  fontSize: isTablet ? 15.5 : 14,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 2. KO SMO MI I ZAŠTO POSTOJIMO
        aboutSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ko smo mi i šta gradimo?',
                style: GoogleFonts.bitter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AmazonColors.darkTextPrimary
                      : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Domaći Market je nastao sa jednostavnom i snažnom idejom: da stvorimo pošteno, moderno i otvoreno mesto koje povezuje ljude širom Srbije i olakšava im svakodnevnu trgovinu.\n\n'
                'Prvo — domaća hrana direktno od proizvođača. Želimo da podržimo vredne seoske domaćine, pčelare, vinare i male zanatlije, a porodicama u gradovima omogućimo lak i siguran pristup svežoj, prirodnoj hrani proverenog porekla. Bez komplikovanih posrednika — od porodičnog gazdinstva pravo na vašu trpezu.\n\n'
                'Drugo — slobodna i besplatna berza za sve građane. Stvorili smo nacionalne male oglase otvorene za svakoga — bilo da prodajete ili tražite automobil, telefon, belu tehniku, nameštaj, nekretninu, stvari za decu i dom, alate ili poljoprivredne mašine. Naš princip je uvek isti i jasan: postavljanje oglasa, njihovo osvežavanje na vrh i celokupna trgovina su 100% besplatni, bez ikakvih provizija i skrivenih troškova.\n\n'
                'Zato Domaći Market na jednom mestu spaja dve ravnopravne celine: Pijacu domaće hrane sa gazdinstava i Nacionalne male oglase za celu Srbiju — prostor gde ljudi trguju jednostavno, direktno i sa poverenjem.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: isDark
                      ? AmazonColors.darkTextSecondary
                      : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  aboutPillTag(
                      context, Icons.verified_user_outlined, '100% Bez posrednika'),
                  aboutPillTag(context, Icons.payments_outlined,
                      '0% Provizije (sav novac ide prodavcu)'),
                  aboutPillTag(context, Icons.campaign_outlined,
                      '100% Besplatno oglašavanje'),
                  aboutPillTag(
                      context, Icons.map_outlined, 'Lokalno i širom Srbije'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
