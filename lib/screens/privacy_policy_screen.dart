import 'package:flutter/material.dart';
import 'package:mleko/core/web_seo.dart';
import 'package:mleko/core/responsive.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    setPageMetadata(
      title: 'Politika privatnosti | domaćimarket.rs',
      description:
          'Saznajte kako domaćimarket.rs prikuplja, obrađuje, čuva i štiti podatke o ličnosti korisnika.',
      path: '/politika-privatnosti',
    );
    final horizontalPadding = Breakpoints.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Politika privatnosti')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                Breakpoints.isTabletOrLarger(context) ? 720 : double.infinity,
          ),
          child: SelectionArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 16,
                  largeTabletValue: 20,
                  desktop: 24,
                ),
                horizontalPadding,
                Breakpoints.adaptiveDouble(
                  context,
                  phone: 32,
                  largeTabletValue: 40,
                  desktop: 48,
                ),
              ),
              child: const _PrivacyContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 22,
      largeTabletValue: 28,
      desktop: 32,
    );
    final itemSpacing = Breakpoints.adaptiveDouble(
      context,
      phone: 6,
      largeTabletValue: 7,
      desktop: 8,
    );
    final body = Breakpoints.supportingTextStyle(
      context,
      theme.textTheme.bodyMedium,
      phone: 15,
      largeTabletValue: 16,
      desktop: 16,
      height: 1.72,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final heading = Breakpoints.sectionTitleStyle(
      context,
      theme.textTheme.titleMedium,
    )?.copyWith(fontWeight: FontWeight.w700);
    final pageTitle = Breakpoints.heroTitleStyle(
      context,
      theme.textTheme.titleLarge,
    )?.copyWith(fontWeight: FontWeight.w800);

    Widget section(String number, String title, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: sectionSpacing),
          Text('$number. $title', style: heading),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: Text(item, style: body),
              )),
        ],
      );
    }

    Widget bullet(String text) => Padding(
          padding: EdgeInsets.only(left: 16, bottom: itemSpacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: body),
              Expanded(child: Text(text, style: body)),
            ],
          ),
        );

    Widget sectionBullets(String number, String title, List<String> bullets) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('$number. $title', style: heading),
          const SizedBox(height: 8),
          ...bullets.map(bullet),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Breakpoints.cardPadding(context) + 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kako obrađujemo i štitimo podatke o ličnosti',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ova politika objašnjava koje podatke prikupljamo, zašto ih obrađujemo, sa kim ih delimo i koja prava imate kao korisnik platforme domaćimarket.rs.',
                style: body,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionSpacing),
        Text('POLITIKA PRIVATNOSTI – domaćimarket.rs', style: pageTitle),
        const SizedBox(height: 12),
        Text('Datum stupanja na snagu: 9. april 2026.', style: body),
        section('1', 'Ko je rukovalac podacima', [
          'Rukovalac podacima o ličnosti u vezi sa platformom domaćimarket.rs je Vladimir Ivanović, Crvenih Hrastova 6, Beograd, Republika Srbija, email: vrvlada@gmail.com.',
          'Rukovalac određuje svrhe i načine obrade podataka o ličnosti u okviru funkcionisanja platforme.',
        ]),
        section('2', 'Status platforme', [
          'Platforma domaćimarket.rs je trenutno u razvojnoj, pilot i startup fazi.',
          'Korišćenje platforme je u ovom trenutku besplatno za sve korisnike.',
        ]),
        sectionBullets('3', 'Na koga se politika odnosi', [
          'posetioce sajta i korisnike web verzije platforme',
          'registrovane korisnike aplikacije i sajta',
          'kupce, prodavce, goste i administratore, u meri u kojoj koriste platformu',
          'lica koja nas kontaktiraju putem email-a ili drugih komunikacionih kanala',
        ]),
        sectionBullets(
            '4', 'Koje strane učestvuju u funkcionisanju platforme', [
          'Vladimir Ivanović, kao rukovalac i lice koje upravlja platformom domaćimarket.rs',
          'korisnici platforme, uključujući kupce, prodavce, goste i administratore',
          'Supabase, kao pružalac tehničke infrastrukture za autentikaciju, bazu podataka i čuvanje sadržaja, uključujući slike profila i proizvoda',
          'Google Firebase i Firebase Cloud Messaging, kao pružaoci infrastrukture za push notifikacije i obradu tokena uređaja',
          'Vercel ili drugi pružaoci hostinga i isporuke web sadržaja, kada se koriste za objavu i dostupnost web verzije',
          'sistemske usluge uređaja i operativnih sistema, kao što su lokacione usluge, galerija fotografija i notifikacioni sistemi, kada korisnik za to da dozvolu',
          'nadležni državni organi Republike Srbije, kada je dostavljanje podataka neophodno radi ispunjenja zakonske obaveze ili zaštite prava i bezbednosti',
        ]),
        Padding(
          padding: EdgeInsets.only(top: itemSpacing),
          child: Text(
            'Navedene strane mogu imati ulogu obrađivača, primaoca podataka ili nezavisnih rukovalaca, u zavisnosti od prirode konkretne obrade.',
            style: body,
          ),
        ),
        sectionBullets('5', 'Koje podatke možemo obrađivati', [
          'identifikacione i nalogne podatke, kao što su email adresa, korisničko ime, prikazano ime i uloga korisnika',
          'kontakt podatke, kao što su broj telefona, grad i drugi podaci koje korisnik unese u profil ili komunikaciju',
          'podatke o profilu prodavca, kao što su naziv gazdinstva, opis, fotografije i lokacija',
          'podatke o proizvodima, uključujući naziv, opis, cenu, količinu, slike i druge podatke koje prodavac objavi',
          'podatke o porudžbinama i upitima, uključujući povezanu komunikaciju i statuse',
          'podatke o notifikacijama i evidenciju o sistemskim i korisničkim obaveštenjima',
          'tehničke podatke, kao što su identifikatori uređaja, tokeni za push notifikacije, osnovni logovi grešaka i podaci o sesiji',
          'podatke o lokaciji, ali samo u meri u kojoj korisnik odobri pristup lokaciji uređaja',
          'fotografije i druge datoteke koje korisnik dobrovoljno otpremi putem platforme',
        ]),
        Padding(
          padding: EdgeInsets.only(top: itemSpacing),
          child: Text(
            'Platforma nije namenjena obradi posebnih vrsta podataka o ličnosti, kao što su podaci o zdravlju, biometrijski podaci, politička ili verska uverenja. Molimo korisnike da takve podatke ne unose niti šalju putem platforme.',
            style: body,
          ),
        ),
        sectionBullets('6', 'Kako prikupljamo podatke', [
          'direktno od korisnika, kada se registruju, popunjavaju profil, objavljuju proizvode, šalju porudžbine ili komuniciraju putem platforme',
          'automatski, kroz tehničko funkcionisanje aplikacije i sajta',
          'preko dozvola koje korisnik odobri na svom uređaju, na primer za lokaciju, galeriju slika ili push notifikacije',
          'iz komunikacije sa korisnikom, kada nam se obrati putem email-a ili drugih kanala podrške',
        ]),
        sectionBullets('7', 'Svrhe obrade podataka', [
          'omogućavanje registracije i prijave korisnika',
          'kreiranje i održavanje korisničkih profila',
          'objavljivanje i prikazivanje proizvoda i profila prodavaca',
          'povezivanje kupaca i prodavaca',
          'slanje, evidentiranje i upravljanje porudžbinama, upitima i statusima',
          'slanje obaveštenja i push notifikacija u vezi sa korišćenjem platforme',
          'omogućavanje rada funkcionalnosti koje zavise od lokacije ili odabranog regiona',
          'bezbednost sistema, sprečavanje zloupotreba i zaštita prava korisnika i rukovaoca',
          'unapređenje rada platforme, otklanjanje grešaka i tehničko održavanje',
          'postupanje po zakonskim obavezama i zahtevima nadležnih organa',
        ]),
        sectionBullets('8', 'Pravni osnov obrade', [
          'pristanak korisnika, kada je potreban, na primer za određene dozvole uređaja ili određene vrste komunikacije',
          'izvršenje ugovora ili preduzimanje radnji na zahtev korisnika pre zaključenja ugovora, kada je obrada neophodna za funkcionisanje naloga, porudžbine ili komunikacije',
          'ispunjenje zakonskih obaveza rukovaoca',
          'legitimni interes rukovaoca, kada je obrada neophodna radi bezbednosti platforme, sprečavanja zloupotreba, vođenja evidencija, odbrane pravnih zahteva i unapređenja tehničke stabilnosti platforme',
        ]),
        Padding(
          padding: EdgeInsets.only(top: itemSpacing),
          child: Text(
            'Ako se obrada zasniva na pristanku, korisnik može opozvati pristanak u svakom trenutku, pri čemu opoziv ne utiče na zakonitost obrade izvršene pre opoziva.',
            style: body,
          ),
        ),
        section('9', 'Da li je davanje podataka obavezno', [
          'Određeni podaci su neophodni za korišćenje pojedinih funkcionalnosti platforme. Ako korisnik ne dostavi podatke koji su potrebni za registraciju, profil, porudžbinu, komunikaciju ili tehničko funkcionisanje određene usluge, moguće je da tu funkcionalnost neće moći da koristi.',
          'Davanje podataka za lokaciju, galeriju fotografija i push notifikacije zavisi od dozvola koje korisnik daje na svom uređaju. Nedavanje takvih dozvola može ograničiti određene funkcionalnosti, ali ne mora sprečiti osnovno korišćenje platforme.',
        ]),
        sectionBullets('10', 'Primaoci podataka', [
          'rukovalac',
          'ovlašćena lica koja tehnički održavaju ili administriraju platformu, u meri u kojoj je to neophodno',
          'pružaoci tehničkih usluga kao što su Supabase, Google Firebase i hosting infrastruktura, u skladu sa njihovom ulogom u obradi',
          'drugi korisnici platforme, ali samo za one podatke koje korisnik sam objavi ili učini dostupnim u okviru platforme',
          'nadležni državni organi, sudovi, inspekcije i druga ovlašćena tela, kada to nalaže zakon ili zakonit zahtev',
        ]),
        section('11', 'Javno dostupni podaci', [
          'Korisnik, a naročito prodavac, može dobrovoljno objaviti određene podatke na platformi, kao što su prikazano ime, grad ili region, naziv gazdinstva, fotografije profila, fotografije proizvoda, opis ponude i druge informacije koje sam unese.',
          'Takvi podaci mogu postati vidljivi drugim korisnicima platforme i javnosti, u skladu sa podešavanjima i funkcionalnostima platforme.',
        ]),
        section('12', 'Lokacija, slike i dozvole uređaja', [
          'Platforma može tražiti pristup lokaciji uređaja radi određivanja regiona, poboljšanja korisničkog iskustva i prikaza relevantnog sadržaja. Lokacija se obrađuje samo uz dozvolu korisnika.',
          'Platforma može tražiti i pristup galeriji ili fotografijama uređaja radi otpremanja slika profila, proizvoda ili sadržaja gazdinstva, kao i dozvolu za primanje push notifikacija.',
          'Korisnik može upravljati ovim dozvolama u podešavanjima svog uređaja.',
        ]),
        section('13', 'Push notifikacije', [
          'Ako korisnik omogući push notifikacije, platforma može obrađivati token uređaja i povezivati ga sa korisničkim nalogom kako bi slala obaveštenja u vezi sa porudžbinama, statusima aktivnosti na platformi, sistemskim obaveštenjima i drugim relevantnim događajima.',
          'Push notifikacije se šalju preko tehničke infrastrukture Firebase Cloud Messaging i povezanih servisnih komponenti.',
        ]),
        section('14', 'Čuvanje podataka', [
          'Podatke o ličnosti čuvamo onoliko dugo koliko je potrebno za ostvarivanje svrhe za koju su prikupljeni, osim ako je duži rok čuvanja potreban radi ispunjenja zakonske obaveze ili zaštite pravnih interesa.',
          'Rok čuvanja može zavisiti od vrste podatka i funkcionalnosti platforme, uključujući trajanje korisničkog naloga, trajanje aktivnih i arhiviranih porudžbina ili upita, potrebe za rešavanjem sporova, reklamacija i bezbednosnih incidenata i obavezne evidencije koje rukovalac mora da čuva u skladu sa zakonom.',
          'Kada podaci više nisu potrebni, brišu se, anonimizuju ili se njihova obrada ograničava, u skladu sa tehničkim mogućnostima i zakonskim obavezama.',
        ]),
        section('15', 'Prenos podataka u druge države', [
          'Određeni tehnički pružaoci usluga koje platforma koristi mogu obrađivati podatke na serverima koji se nalaze van Republike Srbije, uključujući države Evropske unije i druge države, u zavisnosti od infrastrukture konkretnih pružalaca usluga.',
          'U takvim slučajevima nastojimo da se prenos i obrada podataka vrše u skladu sa Zakonom o zaštiti podataka o ličnosti Republike Srbije i uz primenu odgovarajućih mera zaštite, u meri u kojoj su primenljive.',
        ]),
        section('16', 'Mere zaštite podataka', [
          'Preduzimamo razumne tehničke, organizacione i kadrovske mere radi zaštite podataka od neovlašćenog pristupa, nezakonite obrade, gubitka, uništenja, izmene i neovlašćenog otkrivanja.',
          'Ipak, nijedan sistem elektronske komunikacije i skladištenja podataka ne može garantovati apsolutnu bezbednost. Korisnicima savetujemo da koriste jake lozinke i da vode računa o bezbednosti svojih uređaja i naloga.',
        ]),
        sectionBullets('17', 'Prava korisnika', [
          'da zatraži informaciju da li obrađujemo njegove podatke i pristup tim podacima',
          'da zatraži ispravku netačnih ili dopunu nepotpunih podataka',
          'da zatraži brisanje podataka, kada su za to ispunjeni zakonski uslovi',
          'da zatraži ograničenje obrade',
          'da podnese prigovor na obradu u slučajevima predviđenim zakonom',
          'da zatraži prenosivost podataka, kada su ispunjeni zakonski uslovi',
          'da opozove pristanak, kada se obrada zasniva na pristanku',
          'da podnese pritužbu Povereniku za informacije od javnog značaja i zaštitu podataka o ličnosti',
        ]),
        Padding(
          padding: EdgeInsets.only(top: itemSpacing),
          child: Text(
            'Zahtev za ostvarivanje prava korisnik može poslati na email: vrvlada@gmail.com. Rukovalac će odgovoriti u rokovima i pod uslovima predviđenim važećim propisima Republike Srbije.',
            style: body,
          ),
        ),
        section('18', 'Pritužba Povereniku', [
          'Ako korisnik smatra da se njegovi podaci obrađuju suprotno zakonu, ima pravo da podnese pritužbu Povereniku za informacije od javnog značaja i zaštitu podataka o ličnosti.',
          'Kontakt Poverenika: Bulevar kralja Aleksandra 15, Beograd, email: office@poverenik.rs, web: www.poverenik.rs.',
        ]),
        section('19', 'Maloletna lica', [
          'Platforma nije namenjena obradi podataka maloletnih lica bez odgovarajućeg pravnog osnova.',
          'Ako utvrdimo da su podaci maloletnog lica obrađeni protivno primenljivim pravilima, preduzećemo razumne mere da takve podatke uklonimo ili obradu uskladimo sa zakonom.',
        ]),
        section('20', 'Izmene politike privatnosti', [
          'Rukovalac zadržava pravo da ovu Politiku privatnosti izmeni ili dopuni, naročito u slučaju promene funkcionalnosti platforme, promene tehničkih pružalaca usluga, promene pravnog ili poslovnog modela platforme ili usklađivanja sa novim zakonskim zahtevima.',
          'Aktuelna verzija politike biće objavljena na platformi, uz naznačen datum stupanja na snagu.',
        ]),
        section('21', 'Kontakt', [
          'Za sva pitanja u vezi sa ovom Politikom privatnosti i obradom podataka o ličnosti možete se obratiti na: Vladimir Ivanović, Crvenih Hrastova 6, Beograd, Republika Srbija, email: vrvlada@gmail.com.',
        ]),
      ],
    );
  }
}
