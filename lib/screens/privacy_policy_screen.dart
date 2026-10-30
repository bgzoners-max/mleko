import 'package:flutter/material.dart';
import 'package:mleko/core/web_seo.dart';
import '../widgets/legal_content_layout.dart';

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

    final b = LegalContentBuilder(context);

    return LegalDocumentLayout(
      appBarTitle: 'Politika privatnosti',
      summaryHeader: 'Kako obrađujemo i štitimo podatke o ličnosti',
      summaryText:
          'Ova politika objašnjava koje podatke prikupljamo, zašto ih obrađujemo, sa kim ih delimo i koja prava imate kao korisnik platforme domaćimarket.rs.',
      pageTitle: 'POLITIKA PRIVATNOSTI – domaćimarket.rs',
      effectiveDate: '30. oktobar 2026.',
      children: [
        b.section('1', 'Ko je rukovalac podacima', [
          'Rukovalac podacima o ličnosti u vezi sa platformom domaćimarket.rs je Vladimir Ivanović, Beograd, Republika Srbija, email: podrska@domacimarket.rs.',
          'Rukovalac određuje svrhe i načine obrade podataka o ličnosti u okviru funkcionisanja platforme, u skladu sa Zakonom o zaštiti podataka o ličnosti Republike Srbije („Sl. glasnik RS“, br. 87/2018 – ZZPL).',
        ]),
        b.section('2', 'Status platforme', [
          'Platforma domaćimarket.rs je digitalna platforma za povezivanje proizvođača domaće hrane, oglašivača malih oglasa i kupaca.',
          'Korišćenje osnovnih funkcionalnosti platforme i oglašavanje je besplatno za korisnike.',
        ]),
        b.sectionBullets('3', 'Na koga se politika odnosi', [
          'posetioce sajta i korisnike web i mobilne verzije platforme',
          'registrovane korisnike aplikacije i sajta',
          'kupce, prodavce, oglašivače malih oglasa, goste i administratore, u meri u kojoj koriste platformu',
          'lica koja nas kontaktiraju putem email-a ili drugih komunikacionih kanala',
        ]),
        b.sectionBullets(
            '4', 'Koje strane učestvuju u funkcionisanju platforme', [
          'Vladimir Ivanović, kao rukovalac i lice koje upravlja platformom domaćimarket.rs',
          'korisnici platforme, uključujući kupce, prodavce, goste i administratore',
          'Supabase, kao pružalac tehničke infrastrukture za autentikaciju i bazu podataka',
          'Cloudflare (Cloudflare Pages i Cloudflare R2), kao pružalac infrastrukture za web hosting, CDN mrežu, bezbednosnu zaštitu i skladištenje medijskih datoteka (fotografija proizvoda i oglasa)',
          'Google Firebase i Firebase Cloud Messaging (FCM), kao pružaoci infrastrukture za push notifikacije i obradu tokena uređaja',
          'sistemske usluge uređaja i operativnih sistema, kao što su lokacione usluge, galerija fotografija i notifikacioni sistemi, kada korisnik za to da dozvolu',
          'nadležni državni organi Republike Srbije, kada je dostavljanje podataka neophodno radi ispunjenja zakonske obaveze ili zaštite prava i bezbednosti',
        ]),
        b.text(
            'Navedene strane mogu imati ulogu obrađivača, primaoca podataka ili nezavisnih rukovalaca, u zavisnosti od prirode konkretne obrade.'),
        b.sectionBullets(
            '4a', 'Podaci o ličnosti prikupljeni putem Google prijave (Google User Data)', [
          'Kada se korisnik prijavi putem Google naloga, platforma pristupa isključivo imenu, email adresi i profilnoj slici korisnika.',
          'Prikupljeni Google podaci koriste se isključivo radi bezbedne autentifikacije i kreiranja korisničkog naloga.',
          'Domaći Market u celosti poštuje Google API Services User Data Policy, uključujući Limited Use zahteve.',
          'Google podaci se nikada ne prodaju, ne iznajmljuju niti dele sa trećim licima ili marketinškim agencijama.',
          'Korisnik može u svakom trenutku zatražiti trajno brisanje svog naloga i svih povezanih podataka slanjem zahteva na podrska@domacimarket.rs.',
        ]),
        b.sectionBullets('5', 'Koje podatke možemo obrađivati', [
          'identifikacione i nalogne podatke, kao što su email adresa, korisničko ime, prikazano ime i uloga korisnika',
          'kontakt podatke, kao što su broj telefona, grad i drugi podaci koje korisnik unese u profil ili komunikaciju',
          'podatke o profilu prodavca, kao što su naziv gazdinstva/firme, opis, fotografije, lokacija, opciono uneti BPG broj poljoprivrednog gazdinstva (12 cifara) ili PIB pravnog lica/preduzetnika (9 cifara), kao i datum i vreme elektronskog prihvatanja izjave o sanitarnoj i pravnoj odgovornosti',
          'podatke o proizvodima, uključujući naziv, opis, cenu, količinu, slike i druge podatke koje prodavac objavi',
          'podatke o porudžbinama i upitima, uključujući povezanu komunikaciju, statuse, podatke o mestu i vremenu isporuke ili preuzimanja, kao i kontakt podatke potrebne za realizaciju porudžbine',
          'podatke iz reklamacija, prijava problema i sporova između korisnika, uključujući opis prijavljenog nedostatka, vreme prijema robe, fotografije i drugu dokumentaciju koju korisnik dobrovoljno dostavi, uključujući slučajeve koji se odnose na kvarljive proizvode',
          'podatke o notifikacijama i evidenciju o sistemskim i korisničkim obaveštenjima',
          'tehničke podatke, kao što su identifikatori uređaja, tokeni za push notifikacije, osnovni logovi grešaka i podaci o sesiji',
          'podatke o lokaciji, ali samo u meri u kojoj korisnik odobri pristup lokaciji uređaja',
          'fotografije i druge datoteke koje korisnik dobrovoljno otpremi putem platforme',
        ]),
        b.text(
            'Platforma nije namenjena obradi posebnih vrsta podataka o ličnosti, kao što su podaci o zdravlju, biometrijski podaci, politička ili verska uverenja. Molimo korisnike da takve podatke ne unose niti šalju putem platforme.'),
        b.sectionBullets('6', 'Kako prikupljamo podatke', [
          'direktno od korisnika, kada se registruju, popunjavaju profil, objavljuju proizvode, šalju porudžbine ili komuniciraju putem platforme',
          'automatski, kroz tehničko funkcionisanje aplikacije i sajta',
          'preko dozvola koje korisnik odobri na svom uređaju, na primer za lokaciju, galeriju slika ili push notifikacije',
          'iz komunikacije sa korisnikom, kada nam se obrati putem email-a ili drugih kanala podrške',
        ]),
        b.sectionBullets('7', 'Svrhe obrade podataka', [
          'omogućavanje registracije i prijave korisnika',
          'kreiranje i održavanje korisničkih profila',
          'objavljivanje i prikazivanje proizvoda i profila prodavaca',
          'povezivanje kupaca i prodavaca',
          'slanje, evidentiranje i upravljanje porudžbinama, upitima i statusima',
          'organizovanje i evidentiranje isporuke, preuzimanja i povezane komunikacije između kupca i prodavca',
          'obrada reklamacija, prijava problema, sporova i dokaza dostavljenih u vezi sa porudžbinama, uključujući situacije koje se odnose na kvarljive proizvode i prijavljene nedostatke pri primopredaji',
          'slanje obaveštenja i push notifikacija u vezi sa korišćenjem platforme',
          'omogućavanje rada funkcionalnosti koje zavise od lokacije ili odabranog regiona',
          'bezbednost sistema, sprečavanje zloupotreba i zaštita prava korisnika i rukovaoca',
          'unapređenje rada platforme, otklanjanje grešaka i tehničko održavanje',
          'postupanje po zakonskim obavezama i zahtevima nadležnih organa',
        ]),
        b.sectionBullets('8', 'Pravni osnov obrade', [
          'pristanak korisnika, kada je potreban, na primer za određene dozvole uređaja ili određene vrste komunikacije',
          'izvršenje ugovora ili preduzimanje radnji na zahtev korisnika pre zaključenja ugovora, kada je obrada neophodna za funkcionisanje naloga, porudžbine ili komunikacije',
          'ispunjenje zakonskih obaveza rukovaoca',
          'legitimni interes rukovaoca, kada je obrada neophodna radi bezbednosti platforme, sprečavanja zloupotreba, vođenja evidencija, odbrane pravnih zahteva i unapređenja tehničke stabilnosti platforme',
        ]),
        b.text(
            'Ako se obrada zasniva na pristanku, korisnik može opozvati pristanak u svakom trenutku, pri čemu opoziv ne utiče na zakonitost obrade izvršene pre opoziva.'),
        b.section('9', 'Da li je davanje podataka obavezno', [
          'Određeni podaci su neophodni za korišćenje pojedinih funkcionalnosti platforme. Ako korisnik ne dostavi podatke koji su potrebni za registraciju, profil, porudžbinu, komunikaciju ili tehničko funkcionisanje određene usluge, moguće je da tu funkcionalnost neće moći da koristi.',
          'Davanje podataka za lokaciju, galeriju fotografija i push notifikacije zavisi od dozvola koje korisnik daje na svom uređaju. Nedavanje takvih dozvola može ograničiti određene funkcionalnosti, ali ne mora sprečiti osnovno korišćenje platforme.',
        ]),
        b.sectionBullets('10', 'Primaoci podataka', [
          'rukovalac',
          'ovlašćena lica koja tehnički održavaju ili administriraju platformu, u meri u kojoj je to neophodno',
          'pružaoci tehničkih usluga kao što su Supabase, Google Firebase i hosting infrastruktura, u skladu sa njihovom ulogom u obradi',
          'drugi korisnici platforme kada je razmena podataka neophodna radi realizacije porudžbine, isporuke, preuzimanja, reklamacije ili rešavanja spora između kupca i prodavca',
          'drugi korisnici platforme, ali samo za one podatke koje korisnik sam objavi ili učini dostupnim u okviru platforme',
          'nadležni državni organi, sudovi, inspekcije i druga ovlašćena tela, kada to nalaže zakon ili zakonit zahtev',
        ]),
        b.section('11', 'Javno dostupni podaci i zaštita BPG broja', [
          'Korisnik, a naročito prodavac, može dobrovoljno objaviti određene podatke na platformi, kao što su prikazano ime, grad ili region, naziv gazdinstva ili firme, PIB pravnog lica (koji je javni podatak u APR registru), fotografije profila, fotografije proizvoda i oglasa, opis ponude i druge informacije koje sam unese.',
          'Pun 12-cifreni Broj poljoprivrednog gazdinstva (BPG) fizičkog lica – nosioca gazdinstva je zaštićen na nivou baze podataka i NIJE javno vidljiv drugim posetiocima sajta; posetiocima se prikazuje isključivo oznaka „Verifikovano gazdinstvo (BPG)“ uz maskiran prikaz poslednje 4 cifre (npr. ••••••••1234).',
        ]),
        b.section('12', 'Lokacija, slike i dozvole uređaja', [
          'Platforma može tražiti pristup lokaciji uređaja radi određivanja regiona, poboljšanja korisničkog iskustva i prikaza relevantnog sadržaja. Lokacija se obrađuje samo uz dozvolu korisnika.',
          'Platforma može tražiti i pristup galeriji ili fotografijama uređaja radi otpremanja slika profila, proizvoda ili sadržaja gazdinstva, kao i dozvolu za primanje push notifikacija.',
          'Korisnik može upravljati ovim dozvolama u podešavanjima svog uređaja.',
        ]),
        b.section('13', 'Push notifikacije', [
          'Ako korisnik omogući push notifikacije, platforma može obrađivati token uređaja i povezivati ga sa korisničkim nalogom kako bi slala obaveštenja u vezi sa porudžbinama, statusima aktivnosti na platformi, sistemskim obaveštenjima i drugim relevantnim događajima.',
          'Push notifikacije se šalju preko tehničke infrastrukture Firebase Cloud Messaging i povezanih servisnih komponenti.',
        ]),
        b.section('14', 'Čuvanje podataka', [
          'Podatke o ličnosti čuvamo onoliko dugo koliko je potrebno za ostvarivanje svrhe za koju su prikupljeni, osim ako je duži rok čuvanja potreban radi ispunjenja zakonske obaveze ili zaštite pravnih interesa.',
          'Rok čuvanja može zavisiti od vrste podatka i funkcionalnosti platforme, uključujući trajanje korisničkog naloga, trajanje aktivnih i arhiviranih porudžbina ili upita, potrebe za rešavanjem sporova, reklamacija i bezbednosnih incidenata, uključujući reklamacije koje se odnose na kvarljive proizvode, kao i obavezne evidencije koje rukovalac mora da čuva u skladu sa zakonom.',
          'Kada podaci više nisu potrebni, brišu se, anonimizuju ili se njihova obrada ograničava, u skladu sa tehničkim mogućnostima i zakonskim obavezama.',
        ]),
        b.section('15', 'Prenos podataka u druge države', [
          'Određeni tehnički pružaoci usluga koje platforma koristi mogu obrađivati podatke na serverima koji se nalaze van Republike Srbije, uključujući države Evropske unije i druge države, u zavisnosti od infrastrukture konkretnih pružalaca usluga.',
          'U takvim slučajevima nastojimo da se prenos i obrada podataka vrše u skladu sa Zakonom o zaštiti podataka o ličnosti Republike Srbije i uz primenu odgovarajućih mera zaštite, u meri u kojoj su primenljive.',
        ]),
        b.section('16', 'Mere zaštite podataka', [
          'Preduzimamo razumne tehničke, organizacione i kadrovske mere radi zaštite podataka od neovlašćenog pristupa, nezakonite obrade, gubitka, uništenja, izmene i neovlašćenog otkrivanja.',
          'Ipak, nijedan sistem elektronske komunikacije i skladištenja podataka ne može garantovati apsolutnu bezbednost. Korisnicima savetujemo da koriste jake lozinke i da vode računa o bezbednosti svojih uređaja i naloga.',
        ]),
        b.sectionBullets('17', 'Prava korisnika', [
          'da zatraži informaciju da li obrađujemo njegove podatke i pristup tim podacima',
          'da zatraži ispravku netačnih ili dopunu nepotpunih podataka',
          'da zatraži brisanje podataka, kada su za to ispunjeni zakonski uslovi',
          'da zatraži ograničenje obrade',
          'da podnese prigovor na obradu u slučajevima predviđenim zakonom',
          'da zatraži prenosivost podataka, kada su ispunjeni zakonski uslovi',
          'da opozove pristanak, kada se obrada zasniva na pristanku',
          'da podnese pritužbu Povereniku za informacije od javnog značaja i zaštitu podataka o ličnosti',
        ]),
        b.text(
            'Zahtev za ostvarivanje prava korisnik može poslati na email: podrska@domacimarket.rs. Rukovalac će odgovoriti u rokovima i pod uslovima predviđenim važećim propisima Republike Srbije.'),
        b.section('18', 'Pritužba Povereniku', [
          'Ako korisnik smatra da se njegovi podaci obrađuju suprotno zakonu, ima pravo da podnese pritužbu Povereniku za informacije od javnog značaja i zaštitu podataka o ličnosti.',
          'Kontakt Poverenika: Bulevar kralja Aleksandra 15, Beograd, email: office@poverenik.rs, web: www.poverenik.rs.',
        ]),
        b.section('19', 'Maloletna lica', [
          'Platforma nije namenjena obradi podataka maloletnih lica bez odgovarajućeg pravnog osnova.',
          'Ako utvrdimo da su podaci maloletnog lica obrađeni protivno primenljivim pravilima, preduzećemo razumne mere da takve podatke uklonimo ili obradu uskladimo sa zakonom.',
        ]),
        b.section('20', 'Izmene politike privatnosti', [
          'Rukovalac zadržava pravo da ovu Politiku privatnosti izmeni ili dopuni, naročito u slučaju promene funkcionalnosti platforme, promene tehničkih pružalaca usluga, promene pravnog ili poslovnog modela platforme ili usklađivanja sa novim zakonskim zahtevima.',
          'Aktuelna verzija politike biće objavljena na platformi, uz naznačen datum stupanja na snagu.',
        ]),
        b.section('21', 'Kontakt', [
          'Za sva pitanja u vezi sa ovom Politikom privatnosti i obradom podataka o ličnosti možete se obratiti na: Vladimir Ivanović, Beograd, Republika Srbija, email: podrska@domacimarket.rs.',
        ]),
      ],
    );
  }
}
