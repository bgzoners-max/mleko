import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import 'about_section_helpers.dart';

class AboutPillarsSection extends StatelessWidget {
  const AboutPillarsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AmazonColors.darkCard : AmazonColors.cardWhite;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3. VELIKA SEKCIJA 1: PIJACA DOMAĆE HRANE
        aboutComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor:
              const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.4 : 0.25),
          accentColor: const Color(0xFF2E7D32),
          tagText: 'PRVA SEKCIJA: OD NJIVE DO TRPEZE',
          badgeIcon: Icons.eco,
          title: 'Pijaca domaće hrane sa seoskih gazdinstava',
          subtitle:
              'Kratak lanac snabdevanja koji vas spaja direktno sa vrednim domaćinima širom Srbije. Sveže, prirodno i pripremljeno po narudžbini bez hladnjača i industrijskih skladišta.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutSubsectionHeader(
                context,
                Icons.shopping_basket_outlined,
                'Šta možete pronaći i naručiti:',
                const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              aboutCategoryBullet(
                context,
                'Mleko i mlečni proizvodi:',
                'Sveže kravlje i kozje mleko, zreli zlatiborski, sjenički i pirotski sirevi, mladi sir, punomasni kajmak, surutka.',
              ),
              aboutCategoryBullet(
                context,
                'Suvo i sveže domaće meso:',
                'Goveđa i svinjska pršuta, domaća slanina, čvarci, mast, sremski i vojvođanski kulen, sušene kobasice bez veštačkih aditiva.',
              ),
              aboutCategoryBullet(
                context,
                'Prirodni med i pčelinji proizvodi:',
                'Bagremov, livadski, lipov i šumski med, propolis kapi, polen, matični mleč i saće direktno od registrovanih pčelara.',
              ),
              aboutCategoryBullet(
                context,
                'Domaća zimnica i prerađevine:',
                'Tradicionalni cepkani i mleveni ajvar, pinđur, lovačka salata, turšija, kiseli kupus, džemovi bez konzervansa, slatka i sirupi.',
              ),
              aboutCategoryBullet(
                context,
                'Brašno, žitarice i vodenice:',
                'Belo i žuto kukuruzno brašno mleveno na vodeničnom kamenu, integralno pšenično, ražano i speltino brašno.',
              ),
              aboutCategoryBullet(
                context,
                'Sezonsko voće, povrće i orasi:',
                'Domaći paradajz, paprika, krompir, jabuke, kruške, maline, borovnice, orasi i lešnici ubranih u punoj zrelosti.',
              ),
              const SizedBox(height: 16),
              aboutSubsectionHeader(
                context,
                Icons.verified_outlined,
                'Kako funkcioniše i po čemu se razlikuje:',
                const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 10),
              aboutAdvantageRow(
                context,
                'Nema industrijskih magacina:',
                'Hrana ne stoji mesecima po policama — priprema se, pakuje i šalje sveže tek nakon što potvrdite porudžbinu kod domaćina.',
              ),
              aboutAdvantageRow(
                context,
                'Interaktivna mapa i lokalna ponuda:',
                'Jednim dodirom pronađite gazdinstva u vašem gradu ili susednim selima za lično preuzimanje ili direktnu dostavu.',
              ),
              aboutAdvantageRow(
                context,
                'Prilagođene seoske mere:',
                'Naručivanje po meri domaćina: u kilogramima, gramima, teglama, litrima, vezama ili porodičnim paketima.',
              ),
              aboutAdvantageRow(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/categories')),
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Istraži ponudu hrane',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFF81C784)
                          : const Color(0xFF245938),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF81C784)
                            : const Color(0xFF245938),
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/becoming-seller')),
                    icon: const Icon(Icons.add_business_outlined, size: 18),
                    label: const Text('Postani prodavac hrane',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // 4. VELIKA SEKCIJA 2: NACIONALNI MALI OGLASI
        aboutComprehensiveSectionCard(
          context: context,
          cardBg: cardBg,
          borderColor:
              const Color(0xFFD97724).withValues(alpha: isDark ? 0.4 : 0.3),
          accentColor: const Color(0xFFD97724),
          tagText: 'DRUGA SEKCIJA: 100% BESPLATNO I BEZ PROVIZIJE',
          badgeIcon: Icons.campaign_rounded,
          title: 'Nacionalni Mali Oglasi za celu Srbiju',
          subtitle:
              'Potpuno besplatan oglasnik u kom svako može da postavi oglas za bilo šta — telefone, računare, tehniku, automobile, nameštaj, odeću, opremu za decu, nekretnine, alate, kućne ljubimce ili poljoprivredu, brzo i bez ikakvih skrivenih nameta.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutSubsectionHeader(
                context,
                Icons.grid_view_rounded,
                'Obuhvatne kategorije malih oglasa:',
                const Color(0xFFD97724),
              ),
              const SizedBox(height: 10),
              aboutCategoryBullet(
                context,
                'Poljoprivreda i mehanizacija:',
                'Traktori (IMT, Rakovica, Zetor, John Deere...), priključne mašine, plugovi, rotacione freze, sejalice, berači, kombajni, prikolice, sadnice, stočna hrana, bale sena, pčelarska oprema.',
              ),
              aboutCategoryBullet(
                context,
                'Domaće životinje i stoka:',
                'Krave, telad, junad, ovce, jagnjad, koze, prasad, svinje, živina, konji, priplodni materijal i domaće rase.',
              ),
              aboutCategoryBullet(
                context,
                'Vozila, transport i delovi:',
                'Polovni automobili, dostavni kombiji, teretna vozila, traktorske i auto-prikolice, gume, felne i auto-delovi.',
              ),
              aboutCategoryBullet(
                context,
                'Alati, mašine i zanatstvo:',
                'Profesionalni i hobi alati, motorne testere, trimeri, bušilice, brusilice, aparati za varenje, kompresori, agregati i oprema za radionice.',
              ),
              aboutCategoryBullet(
                context,
                'Bela tehnika, grejanje i dom:',
                'Šporeti na drva (Smederevci, Alfa Plam), peći na pelet, kotlovi za grejanje, frižideri, zamrzivači, nameštaj i baštenska oprema.',
              ),
              aboutCategoryBullet(
                context,
                'Sve za decu i porodicu:',
                'Dečija kolica, auto-sedišta, hranilice, kreveci, bicikli, igračke, bebi oprema i odeća.',
              ),
              aboutCategoryBullet(
                context,
                'Zdravlje, lepota i rukotvorine:',
                'Prirodni melemi, domaći sapuni, tinkture, ručno tkani ćilimi, nošnje, unikatno pletivo i drvorez.',
              ),
              aboutCategoryBullet(
                context,
                'Nekretnine i zemljište:',
                'Seoska domaćinstva, vikendice, seoske kuće, obradive njive, placevi, šume i poljoprivredno zemljište.',
              ),
              const SizedBox(height: 16),
              aboutSubsectionHeader(
                context,
                Icons.thumb_up_alt_outlined,
                'Prednosti i pravila za oglašivače:',
                const Color(0xFFD97724),
              ),
              const SizedBox(height: 10),
              aboutAdvantageRow(
                context,
                '100% Besplatna objava:',
                'Postavljanje oglasa ne zahteva platne kartice, pretplate niti skrivene naknade. Svaki građanin može slobodno oglasiti ono što prodaje.',
              ),
              aboutAdvantageRow(
                context,
                'Besplatno obnavljanje (Refresh):',
                'Kada istekne definisani period, oglas možete besplatno osvežiti i vratiti na vrh pretrage jednim klikom — bez ikakvih doplaćivanja.',
              ),
              aboutAdvantageRow(
                context,
                'Fleksibilno određivanje cene:',
                'Podrška za fiksne cene (u RSD ili EUR), cene po dogovoru, zamenu za drugu robu ili poklanjanje onima kojima je potrebno.',
              ),
              aboutAdvantageRow(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () =>
                        withHaptic(() => context.push('/classifieds')),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Pregledaj male oglase',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? const Color(0xFFFFB74D)
                          : const Color(0xFFD97724),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFFFFB74D)
                            : const Color(0xFFD97724),
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
                    label: const Text('Postavi besplatan oglas',
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
