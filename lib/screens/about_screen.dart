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
                  fontWeight: FontWeight.w800,
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
        _buildSectionCard(
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
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Domaći Market je nastao sa jasnom misijom: da ponudi poštenu, otvorenu i modernu platformu koja rešava dva velika svakodnevna izazova ljudi u Srbiji.\n\nPrvo, decenijama unazad, vredni seoski domaćini i zanatlije bili su prepušteni prekupcima i visokim trgovačkim maržama, dok su porodice u gradovima gubile dodir sa pravom, svežom i zdravom domaćom hranom čije se poreklo tačno zna.\n\nDrugo, poljoprivrednicima, zanatlijama i običnim ljudima nedostajalo je fer i moderno mesto za oglašavanje poljoprivredne mehanizacije, stoke, alata, vozila i stvari za dom — bez plaćanja skupih oglasnih taksi, bez provizija na prodatu robu i bez naplate obnavljanja oglasa.\n\nZato smo stvorili Domaći Market kao dve ravnopravne, obimne sekcije na jednom mestu: Pijacu domaće hrane sa sela i Nacionalne male oglase.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPillTag(context, Icons.verified_user_outlined, '100% Bez posrednika'),
                  _buildPillTag(context, Icons.payments_outlined, '0% Provizije (sav novac ide prodavcu)'),
                  _buildPillTag(context, Icons.campaign_outlined, '100% Besplatno oglašavanje'),
                  _buildPillTag(context, Icons.map_outlined, 'Lokalno i širom Srbije'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 3. VELIKA SEKCIJA 1: PIJACA DOMAĆE HRANE
        _buildComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.4 : 0.25),
          accentColor: const Color(0xFF2E7D32),
          tagText: 'PRVA SEKCIJA: OD NJIVE DO TRPEZE',
          badgeIcon: Icons.eco,
          title: 'Pijaca domaće hrane sa seoskih gazdinstava',
          subtitle:
              'Kratak lanac snabdevanja koji vas spaja direktno sa vrednim domaćinima širom Srbije. Sveže, prirodno i pripremljeno po narudžbini bez hladnjača i industrijskih skladišta.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsectionHeader(
                context,
                Icons.shopping_basket_outlined,
                'Šta možete pronaći i naručiti:',
                const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              _buildCategoryBullet(
                context,
                'Mleko i mlečni proizvodi:',
                'Sveže kravlje i kozje mleko, zreli zlatiborski, sjenički i pirotski sirevi, mladi sir, punomasni kajmak, surutka.',
              ),
              _buildCategoryBullet(
                context,
                'Suvo i sveže domaće meso:',
                'Goveđa i svinjska pršuta, domaća slanina, čvarci, mast, sremski i vojvođanski kulen, sušene kobasice bez veštačkih aditiva.',
              ),
              _buildCategoryBullet(
                context,
                'Prirodni med i pčelinji proizvodi:',
                'Bagremov, livadski, lipov i šumski med, propolis kapi, polen, matični mleč i saće direktno od registrovanih pčelara.',
              ),
              _buildCategoryBullet(
                context,
                'Domaća zimnica i prerađevine:',
                'Tradicionalni cepkani i mleveni ajvar, pinđur, lovačka salata, turšija, kiseli kupus, džemovi bez konzervansa, slatka i sirupi.',
              ),
              _buildCategoryBullet(
                context,
                'Brašno, žitarice i vodenice:',
                'Belo i žuto kukuruzno brašno mleveno na vodeničnom kamenu, integralno pšenično, ražano i speltino brašno.',
              ),
              _buildCategoryBullet(
                context,
                'Sezonsko voće, povrće i orasi:',
                'Domaći paradajz, paprika, krompir, jabuke, kruške, maline, borovnice, orasi i lešnici ubranih u punoj zrelosti.',
              ),
              const SizedBox(height: 16),
              _buildSubsectionHeader(
                context,
                Icons.verified_outlined,
                'Kako funkcioniše i po čemu se razlikuje:',
                const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              _buildAdvantageRow(
                context,
                'Nema industrijskih magacina:',
                'Hrana ne stoji mesecima po policama — priprema se, pakuje i šalje sveže tek nakon što potvrdite porudžbinu kod domaćina.',
              ),
              _buildAdvantageRow(
                context,
                'Interaktivna mapa i lokalna ponuda:',
                'Jednim dodirom pronađite gazdinstva u vašem gradu ili susednim selima za lično preuzimanje ili direktnu dostavu.',
              ),
              _buildAdvantageRow(
                context,
                'Prilagođene seoske mere:',
                'Naručivanje po meri domaćina: u kilogramima, gramima, teglama, litrima, vezama ili porodičnim paketima.',
              ),
              _buildAdvantageRow(
                context,
                'Profili domaćina i transparentnost:',
                'Svako gazdinstvo ima profil sa fotografijama imanja, pričom o tradiciji proizvodnje i proverenim ocenama kupaca.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF245938),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/categories')),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Istraži ponudu hrane', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFF81C784) : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/becoming-seller')),
                    icon: const Icon(Icons.add_business_outlined, size: 18),
                    label: const Text('Postani prodavac hrane', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 4. VELIKA SEKCIJA 2: NACIONALNI MALI OGLASI
        _buildComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor: const Color(0xFFD97724).withValues(alpha: isDark ? 0.4 : 0.3),
          accentColor: const Color(0xFFD97724),
          tagText: 'DRUGA SEKCIJA: 100% BESPLATNO I BEZ PROVIZIJE',
          badgeIcon: Icons.campaign_rounded,
          title: 'Nacionalni Mali Oglasi za celu Srbiju',
          subtitle:
              'Potpuno besplatna berza za oglašavanje poljoprivredne mehanizacije, stoke, alata, vozila, kućnih aparata, opreme za decu i nekretnina. Oglasite brzo i bez ikakvih skrivenih nameta.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubsectionHeader(
                context,
                Icons.grid_view_rounded,
                'Obuhvatne kategorije malih oglasa:',
                const Color(0xFFD97724),
              ),
              const SizedBox(height: 10),
              _buildCategoryBullet(
                context,
                'Poljoprivreda i mehanizacija:',
                'Traktori (IMT, Rakovica, Zetor, John Deere...), priključne mašine, plugovi, rotacione freze, sejalice, berači, kombajni, prikolice, sadnice, stočna hrana, bale sena, pčelarska oprema.',
              ),
              _buildCategoryBullet(
                context,
                'Domaće životinje i stoka:',
                'Krave, telad, junad, ovce, jagnjad, koze, prasad, svinje, živina, konji, priplodni materijal i domaće rase.',
              ),
              _buildCategoryBullet(
                context,
                'Vozila, transport i delovi:',
                'Polovni automobili, dostavni kombiji, teretna vozila, traktorske i auto-prikolice, gume, felne i auto-delovi.',
              ),
              _buildCategoryBullet(
                context,
                'Alati, mašine i zanatstvo:',
                'Profesionalni i hobi alati, motorne testere, trimeri, bušilice, brusilice, aparati za varenje, kompresori, agregati i oprema za radionice.',
              ),
              _buildCategoryBullet(
                context,
                'Bela tehnika, grejanje i dom:',
                'Šporeti na drva (Smederevci, Alfa Plam), peći na pelet, kotlovi za grejanje, frižideri, zamrzivači, nameštaj i baštenska oprema.',
              ),
              _buildCategoryBullet(
                context,
                'Sve za decu i porodicu:',
                'Dečija kolica, auto-sedišta, hranilice, kreveci, bicikli, igračke, bebi oprema i odeća.',
              ),
              _buildCategoryBullet(
                context,
                'Zdravlje, lepota i rukotvorine:',
                'Prirodni melemi, domaći sapuni, tinkture, ručno tkani ćilimi, nošnje, unikatno pletivo i drvorez.',
              ),
              _buildCategoryBullet(
                context,
                'Nekretnine i zemljište:',
                'Seoska domaćinstva, vikendice, seoske kuće, obradive njive, placevi, šume i poljoprivredno zemljište.',
              ),
              const SizedBox(height: 16),
              _buildSubsectionHeader(
                context,
                Icons.thumb_up_alt_outlined,
                'Prednosti i pravila za oglašivače:',
                const Color(0xFFD97724),
              ),
              const SizedBox(height: 10),
              _buildAdvantageRow(
                context,
                '100% Besplatna objava:',
                'Postavljanje oglasa ne zahteva platne kartice, pretplate niti skrivene naknade. Svaki građanin može slobodno oglasiti ono što prodaje.',
              ),
              _buildAdvantageRow(
                context,
                'Besplatno obnavljanje (Refresh):',
                'Kada istekne definisani period, oglas možete besplatno osvežiti i vratiti na vrh pretrage jednim klikom — bez ikakvih doplaćivanja.',
              ),
              _buildAdvantageRow(
                context,
                'Fleksibilno određivanje cene:',
                'Podrška za fiksne cene (u RSD ili EUR), cene po dogovoru, zamenu za drugu robu ili poklanjanje onima kojima je potrebno.',
              ),
              _buildAdvantageRow(
                context,
                'Zaštita privatnosti i telefona:',
                'Sami birate da li želite da vaš broj telefona bude javno prikazan ili da komunicirate isključivo kroz naš bezbedan interni chat.',
              ),
              const SizedBox(height: 20),
              Wrap(
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
                    onPressed: () => withHaptic(() => context.push('/classifieds')),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Pregledaj male oglase', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFFFB74D) : const Color(0xFFD97724),
                      side: BorderSide(
                        color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFD97724),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/classifieds/new')),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Postavi besplatan oglas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 5. MOGUĆNOSTI I TEHNOLOGIJA U SLUŽBI ČOVEKA
        _buildSectionCard(
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
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Objedinili smo jednostavnost tradicionalnog pazara sa savremenim digitalnim pogodnostima za sve korisnike:',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _buildFeatureRow(
                context,
                Icons.chat_outlined,
                'Direktan interni chat sa slikama',
                'Dogovarajte se sa kupcima i prodavcima direktno u aplikaciji u realnom vremenu — razmenjujte slike, detalje o preuzimanju i stanju robe bez napuštanja platforme.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.map_outlined,
                'Interaktivna mapa Srbije',
                'Jednim klikom pronađite proizvođače hrane i oglase u vašoj neposrednoj geografskoj okolini, pogledajte tačnu lokaciju i dogovorite posetu.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.shield_outlined,
                'Maksimalna zaštita privatnosti i protiv botova',
                'Brojevi telefona i podaci o adresi zaštićeni su od automatskih web botova i scraping-a. Vi imate punu kontrolu nad tim šta delite javno.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
                context,
                Icons.star_outline_rounded,
                'Sistem obostranih recenzija i ugleda',
                'Gradimo zajednicu poverenja u kojoj savesni prodavci i savesni kupci stiču vidljiv ugled i pozitivne preporuke ostalih članova.',
              ),
              const Divider(height: 24),
              _buildFeatureRow(
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
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildManifestItem(
                context,
                '1',
                'Sav novac ide onome ko stvara i nudi (0% provizije)',
                'Domaći Market ne uzima procenat od vaše domaće hrane niti proviziju od prodatih stvari sa oglasa. Svaki dinar ide direktno domaćinu i prodavcu.',
              ),
              const SizedBox(height: 14),
              _buildManifestItem(
                context,
                '2',
                'Čuvanje domaće proizvodnje i srpskog sela',
                'Podržavamo opstanak seoskih porodica, negovanje starih sorti i recepata, i slobodan protok dobara između sela i grada bez nametnutih ucenjivačkih marži.',
              ),
              const SizedBox(height: 14),
              _buildManifestItem(
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
                  fontWeight: FontWeight.w800,
                  color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bilo da ste poljoprivredno gazdinstvo, porodica koja traži zdravu hranu, domaćin koji nudi traktor ili neko ko želi besplatno da oglasi stvari za kuću — ovo je vaše mesto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/categories')),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Pijaca hrane', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97724),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/classifieds')),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Mali oglasi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AmazonColors.amberLight : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark ? AmazonColors.amberLight : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => withHaptic(() => context.push('/classifieds/new')),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Postavi oglas', style: TextStyle(fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AmazonColors.getCardShadow(context),
      ),
      child: child,
    );
  }

  Widget _buildComprehensiveSectionCard({
    required BuildContext context,
    required Color cardBg,
    required Color borderColor,
    required Color accentColor,
    required String tagText,
    required IconData badgeIcon,
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.4),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(badgeIcon, size: 24, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tagText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.bitter(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildSubsectionHeader(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBullet(
    BuildContext context,
    String label,
    String description,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: AmazonColors.amber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageRow(
    BuildContext context,
    String label,
    String text,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
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
            borderRadius: BorderRadius.circular(10),
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
