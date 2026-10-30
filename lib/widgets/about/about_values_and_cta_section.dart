import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../core/responsive.dart';
import 'about_section_helpers.dart';

class AboutValuesAndCtaSection extends StatelessWidget {
  const AboutValuesAndCtaSection({super.key});

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
        // 5. MOGUĆNOSTI I TEHNOLOGIJA U SLUŽBI ČOVEKA
        aboutSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moderna tehnologija u službi poštene trgovine',
                style: GoogleFonts.bitter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AmazonColors.darkTextPrimary
                      : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Objedinili smo jednostavnost tradicionalnog pazara sa savremenim digitalnim pogodnostima za sve korisnike:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AmazonColors.darkTextSecondary
                      : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              aboutFeatureRow(
                context,
                Icons.chat_outlined,
                'Direktan interni chat sa slikama',
                'Dogovarajte se sa kupcima i prodavcima direktno u aplikaciji u realnom vremenu — razmenjujte slike, detalje o preuzimanju i stanju robe bez napuštanja platforme.',
              ),
              const Divider(height: 24),
              aboutFeatureRow(
                context,
                Icons.map_outlined,
                'Interaktivna mapa Srbije',
                'Jednim klikom pronađite proizvođače hrane i oglase u vašoj neposrednoj geografskoj okolini, pogledajte tačnu lokaciju i dogovorite posetu.',
              ),
              const Divider(height: 24),
              aboutFeatureRow(
                context,
                Icons.shield_outlined,
                'Maksimalna zaštita privatnosti i protiv botova',
                'Brojevi telefona i podaci o adresi zaštićeni su od automatskih web botova i scraping-a. Vi imate punu kontrolu nad tim šta delite javno.',
              ),
              const Divider(height: 24),
              aboutFeatureRow(
                context,
                Icons.star_outline_rounded,
                'Sistem obostranih recenzija i ugleda',
                'Gradimo zajednicu poverenja u kojoj savesni prodavci i savesni kupci stiču vidljiv ugled i pozitivne preporuke ostalih članova.',
              ),
              const Divider(height: 24),
              aboutFeatureRow(
                context,
                Icons.devices_outlined,
                'Brza PWA aplikacija za sve ekrane',
                'Domaći Market radi trenutno na telefonu, tabletu i računaru. Možete ga instalirati kao laganu aplikaciju bez trošenja memorije i bez potrebe za posetom prodavnicama aplikacija.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 6. NAŠ MANIFEST
        aboutSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: borderColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Naš manifest — Zašto nam je stalo?',
                style: GoogleFonts.bitter(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AmazonColors.darkTextPrimary
                      : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              aboutManifestItem(
                context,
                '1',
                'Sav novac ide onome ko stvara i nudi (0% provizije)',
                'Domaći Market ne uzima procenat od vaše domaće hrane niti proviziju od prodatih stvari sa oglasa. Svaki dinar ide direktno domaćinu i prodavcu.',
              ),
              const SizedBox(height: 14),
              aboutManifestItem(
                context,
                '2',
                'Čuvanje domaće proizvodnje i srpskog sela',
                'Podržavamo opstanak seoskih porodica, negovanje starih sorti i recepata, i slobodan protok dobara između sela i grada bez nametnutih ucenjivačkih marži.',
              ),
              const SizedBox(height: 14),
              aboutManifestItem(
                context,
                '3',
                'Transparentnost, poštenje i data reč',
                'Gradimo mesto gde data reč ima težinu, cene su javne i poštene, a svaki član ima svoje ime i stoji ponosno iza onoga što nudi.',
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // 7. ZAVRŠNI CTA BANNER
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 28 : 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B241E) : const Color(0xFFF0EDE5),
            borderRadius: BorderRadius.circular(20),
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
                size: 38,
                color: AmazonColors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                'Dobrodošli u zajednicu Domaćeg Marketa',
                textAlign: TextAlign.center,
                style: GoogleFonts.bitter(
                  fontSize: isTablet ? 23 : 19,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AmazonColors.darkTextPrimary
                      : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bilo da ste poljoprivredno gazdinstvo, porodica koja traži zdravu hranu, domaćin koji nudi traktor ili neko ko želi besplatno da oglasi stvari za kuću — ovo je vaše mesto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark
                      ? AmazonColors.darkTextSecondary
                      : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF245938),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/categories')),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Pijaca hrane',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97724),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/classifieds')),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Mali oglasi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AmazonColors.amberLight
                          : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark
                            ? AmazonColors.amberLight
                            : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/vodic-za-proizvodjace')),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Kako postaviti proizvode',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AmazonColors.amberLight
                          : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark
                            ? AmazonColors.amberLight
                            : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/classifieds/new')),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Postavi oglas',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
