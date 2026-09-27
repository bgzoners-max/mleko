import 'package:flutter/material.dart';
import 'package:mleko/core/web_seo.dart';
import '../widgets/legal_content_layout.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    setPageMetadata(
      title: 'Uslovi korišćenja | domaćimarket.rs',
      description:
          'Pravila korišćenja platforme domaćimarket.rs, usklađena sa Zakonom o zaštiti potrošača, Zakonom o trgovini i Zakonom o oglašavanju.',
      path: '/uslovi-koriscenja',
    );

    final b = LegalContentBuilder(context);

    return LegalDocumentLayout(
      appBarTitle: 'Uslovi korišćenja',
      summaryHeader: 'Pravna pravila i usklađenost sa zakonima Republike Srbije',
      summaryText:
          'Korišćenjem platforme domaćimarket.rs potvrđujete da ste pročitali, razumeli i u celosti prihvatili ove Uslove korišćenja, usklađene sa Zakonom o zaštiti potrošača, Zakonom o trgovini ("Sl. glasnik RS", br. 35/2026) i Zakonom o oglašavanju.',
      pageTitle: 'USLOVI KORIŠĆENJA – domaćimarket.rs',
      effectiveDate: '1. avgust 2026. (poslednje ažuriranje: 27. septembar 2026.)',
      children: [
        b.section('1', 'Opšte odredbe i pravni okvir', [
          'Dobrodošli na platformu domaćimarket.rs, digitalnu platformu koja omogućava povezivanje proizvođača domaće hrane, oglašivača i krajnjih kupaca.',
          'Korišćenjem platforme korisnik potvrđuje da je u celosti upoznat sa ovim Uslovima korišćenja i da ih prihvata kao obavezujuće ugovorne odredbe.',
          'Poslovanje i oglašavanje na platformi podležu zakonodavstvu Republike Srbije, naročito Zakonu o zaštiti potrošača, izmenama Zakona o trgovini ("Sl. glasnik RS", br. 35/2026) i Zakonu o oglašavanju.',
        ]),
        b.section('2', 'Opis usluge i uloga platforme', [
          'Platforma omogućava registraciju korisnika, postavljanje i pretragu malih oglasa i ponude domaće hrane, direktnu komunikaciju između korisnika, kao i kreiranje upita i porudžbina kroz digitalni interfejs.',
          'Platforma pruža isključivo informaciono-tehnološku infrastrukturu za povezivanje oglašivača i kupaca. Platforma nije ugovorna strana u kupoprodajnim transakcijama, ne učestvuje u proizvodnji, transportu niti isporuci robe, osim ako to naknadno ne bude izričito i ugovorno uređeno.',
        ]),
        b.sectionBullets('3', 'Korisnički nalog i registracija', [
          'korisnik je dužan da unese tačne, istinite, potpune i ažurne podatke pri kreiranju naloga i komunikaciji',
          'svaki korisnik je odgovoran za bezbednost i tajnost svojih pristupnih podataka i za sve radnje izvršene sa njegovog naloga',
          'strogo je zabranjeno otvaranje naloga pod lažnim identitetom, zloupotreba tuđih podataka ili delovanje u ime trećih lica bez izričitog zakonskog ovlašćenja',
        ]),
        b.section('4', 'Status prodavca i obaveštenje za potrošače (ZZP i Zakon o trgovini)', [
          'U skladu sa Zakonom o zaštiti potrošača i izmenama Zakona o trgovini ("Sl. glasnik RS", br. 35/2026), na platformi postoji jasna diferencijacija pravnog statusa lica koja nude robu:',
          '1. Registrovani trgovac (pravno lice, preduzetnik ili registrovano poljoprivredno gazdinstvo koje istupa u svojstvu trgovca).',
          '2. Fizičko lice (građanin koji vrši pojedinačnu prodaju sopstvenih polovnih stvari, viška proizvoda ili mehanizacije bez svojstva registrovanog trgovca).',
          'Korisnik koji postavlja oglas ili ponudu dužan je da pruži istinitu i tačnu izjavu o svom statusu.',
          'VAŽNO OBAVEŠTENJE ZA POTROŠAČE:',
          '• Ako kupujete od FIZIČKOG LICA: Na kupoprodaju se NE primenjuju odredbe Zakona o zaštiti potrošača. Kupac nema zakonsko pravo na odustanak od ugovora na daljinu u roku od 14 dana bez navođenja razloga, niti garantovane zakonske rokove reklamacije koji važe za potrošačke sporove. Na takav odnos primenjuju se isključivo opšta pravila Zakona o obligacionim odnosima.',
          '• Ako kupujete od TRGOVCA: Kao kupac-potrošač uživate sva prava propisana Zakonom o zaštiti potrošača, uključujući pravo na odustanak od ugovora zaključenog na daljinu u roku od 14 dana (uz zakonom propisane izuzetke za kvarljivu hranu i higijenske artikle), zakonsku saobraznost, kao i pravo na reklamaciju.',
        ]),
        b.sectionBullets('5', 'Inspekcijski nadzor i borba protiv sive ekonomije', [
          'tržišna inspekcija Republike Srbije ima zakonska ovlašćenja pojačanog nadzora nad onlajn platformama i fizičkim licima radi suzbijanja neregistrovane trgovine i sive ekonomije',
          'inspektori imaju pravo da prate i kontrolišu lica koja kontinuirano i u većem obimu nude i prodaju robu radi sticanja prihoda na internetu, a nisu registrovana kao trgovci',
          'u skladu sa zakonom, nadležni inspektori mogu sprovoditi prikrivenu kupovinu („mystery shopping“) pod lažnim identitetom bez prethodne najave radi utvrđivanja nelegalne trgovine',
          'zabranjeno je korišćenje platforme za obavljanje neregistrovane trgovinske delatnosti; korisnik koji krši ove odredbe snosi punu prekršajnu i materijalnu odgovornost pred nadležnim organima',
        ]),
        b.section('6', 'Nova pravila o isticanju cena, popustima i akcijama', [
          'Ukoliko se proizvod ili oglas oglašava sa popustom, na akciji ili uz promotivnu prodaju, prodavac je dužan da striktno poštuje zakonska pravila:',
          '• Referentna („stara“) cena mora biti stvarna, dokaziva i proverljiva. Prodavac je dužan da kao referentnu cenu navede najnižu cenu po kojoj je prodavao tu robu u poslednjih 30 dana pre početka sniženja.',
          '• Strogo je zabranjeno veštačko podizanje cena neposredno pre sniženja radi stvaranja privida većeg popusta.',
          '• Sve cene moraju biti istaknute jasno, nedvosmisleno i ažurirane u realnom vremenu, kako se potrošači ne bi dovodili u zabludu u pogledu stvarne visine cene ili popusta.',
        ]),
        b.section('7', 'Zabrana prikrivenog oglašavanja (Zakon o oglašavanju)', [
          'U skladu sa najnovijim izmenama Zakona o oglašavanju, zabranjeno je prikriveno oglašavanje u celokupnom digitalnom prostoru.',
          'Svaka oglasna poruka, bilo u formi istaknutog oglasa, sponzorisane ponude ili promotivnog sadržaja na pratećim kanalima i društvenim mrežama, mora biti jasno i nedvosmisleno označena kao oglas/reklama.',
          'Zabranjeno je zamagljivanje granice između lične preporuke i plaćenog oglašavanja. Korisnici i partneri koji primaju naknadu ili drugu korist za promociju određenih proizvoda dužni su da to transparentno naznače.',
        ]),
        b.section('8', 'Transparentnost rangiranja i zabrana lažnih recenzija', [
          'Platforma domaćimarket.rs transparentno primenjuje kriterijume za rangiranje i prikaz oglasa i ponude:',
          '• Osnovno rangiranje: zasniva se na hronološkom redosledu objavljivanja, relevantnosti unetih ključnih reči, izabranoj kategoriji, geografskoj blizini i definisanim korisničkim filterima.',
          '• Promovisane pozicije: Oglasi sa plaćenom promocijom („Istaknuti oglasi“) pozicioniraju se na vrh kategorije ili početne strane, i obavezno nose prepoznatljivu oznaku/bedž („Istaknuto“), čime je obezbeđena potpuna transparentnost.',
          'ZABRANA LAŽNIH RECENZIJA:',
          '• Strogo je zabranjeno naručivanje, organizovanje, pisanje ili objavljivanje lažnih pozitivnih ili negativnih ocena i recenzija radi obmanjivanja kupaca i nepoštene poslovne prakse.',
          '• Zakon propisuje novčane kazne za obmanjujuće ocene i lažne recenzije u rasponu od 300.000 do 2.000.000 dinara za pravna lica.',
          '• Platforma koristi tehničke i bezbednosne mehanizme za sprečavanje i otkrivanje lažnih recenzija (uključujući verifikaciju kupovina) i zadržava pravo momentalnog brisanja spornih ocena i trajnog blokiranja prekršilaca.',
        ]),
        b.sectionBullets('9', 'Opšte obaveze prodavca', [
          'da svi opisi, cene, poreklo, deklaracije, fotografije i druge informacije o robi budu tačni, istiniti i neobmanjujući',
          'da je ovlašćen da nudi i prodaje proizvode koje objavljuje i da postupa u punoj saglasnosti sa propisima Republike Srbije',
          'da snosi isključivu odgovornost za kvalitet, bezbednost, zdravstvenu ispravnost, deklarisanje, zakonsku saobraznost i poreklo svojih proizvoda',
          'da ne objavljuje zabranjenu, krivotvorenu, opasnu ili nedozvoljenu robu',
        ]),
        b.sectionBullets('10', 'Obaveze kupca', [
          'da platformu koristi savesno, pošteno i u skladu sa propisima',
          'da ne zloupotrebljava interfejs za lažno naručivanje, slanje lažnih upita, uznemiravanje ili nanošenje štete oglašivačima',
          'da samostalno i pažljivo proceni ponudu, status prodavca i uslove preuzimanja pre zaključivanja dogovora',
        ]),
        b.sectionBullets(
            '11', 'Posebna pravila za sveže meso i kvarljive namirnice', [
          'prodavac koji nudi sveže meso, proizvode životinjskog porekla ili druge kvarljive namirnice dužan je da postupa u skladu sa svim važećim sanitarnim, veterinarskim, deklarativnim i propisima o bezbednosti hrane Republike Srbije',
          'prodavac je isključivo odgovoran za zakonitost stavljanja takvih namirnica u promet, njihovu zdravstvenu ispravnost, sledljivost, higijensko pakovanje, deklarisanje i propisan transport',
          'kvarljive namirnice moraju biti transportovane i predate kupcu u odgovarajućem hladnom lancu i temperaturnom režimu, uz striktno poštovanje rokova upotrebe',
          'prodavac je dužan da u opisu jasno navede rok trajanja, način čuvanja i uslove primopredaje',
          'platforma ne vrši fizičku kontrolu hladnog lanca, skladištenja niti transporta i ne snosi odgovornost za očuvanje uslova svežine van okvira svoje digitalne posredničke uloge',
        ]),
        b.section('12',
            'Prijem robe, reklamacije i odgovornost za kvarljive proizvode', [
          'Kupac je dužan da po prijemu ili preuzimanju svežeg mesa i drugih kvarljivih namirnica bez odlaganja proveri očigledno stanje robe, uključujući izgled ambalaže, vidljiva oštećenja, očigledna odstupanja i druge nedostatke koji se mogu uočiti redovnim pregledom pri primopredaji.',
          'Reklamacije koje se odnose na očigledne nedostatke, pogrešnu isporuku, nepravilnosti pri isporuci ili sumnju na narušenu ispravnost kvarljive robe kupac treba da prijavi prodavcu bez odlaganja, po mogućnosti odmah po prijemu robe, uz dostavljanje raspoloživih dokaza kao što su fotografije, opis zatečenog stanja i vreme prijema.',
          'Nakon izvršene primopredaje kupac preuzima odgovornost za dalje pravilno rukovanje, čuvanje, hlađenje, zamrzavanje, pripremu i upotrebu kvarljive robe, u skladu sa prirodom proizvoda i uputstvima prodavca ili deklaracije.',
          'Platforma nije ugovorna strana u sporu povodom kvaliteta, kvarljivosti, načina čuvanja, prekida hladnog lanca, isporuke ili reklamacije takvih proizvoda i ne snosi odgovornost za štetu nastalu nakon predaje robe kupcu, osim u meri u kojoj je takva odgovornost izričito propisana obavezujućim pravom.',
        ]),
        b.section('13', 'Uloga platforme i ograničenje odgovornosti', [
          'Platforma domaćimarket.rs deluje kao digitalna platforma za povezivanje korisnika i ne garantuje kvalitet, bezbednost, zdravstvenu ispravnost, legalnost, raspoloživost niti tačnost ponude koju objavljuju korisnici.',
          'Platforma ne snosi odgovornost za štetu nastalu iz odnosa između kupca i prodavca, uključujući sporove u vezi sa kvalitetom proizvoda, isporukom, cenom, reklamacijama ili drugim okolnostima pojedinačne transakcije, osim u meri u kojoj je takva odgovornost izričito propisana obavezujućim pravom.',
        ]),
        b.sectionBullets('14', 'Zabranjene aktivnosti', [
          'objavljivanje lažnih, obmanjujućih, nezakonitih ili uvredljivih sadržaja',
          'lažno predstavljanje, zloupotreba tuđih podataka ili neovlašćeno korišćenje naloga',
          'objavljivanje proizvoda ili sadržaja čije je stavljanje u promet ili prikazivanje zabranjeno zakonom',
          'narušavanje bezbednosti sistema, pokušaji neovlašćenog pristupa ili ometanje rada platforme',
          'prikupljanje podataka drugih korisnika bez ovlašćenja (automatski scraping i botovanje)',
        ]),
        b.section('15', 'Uklanjanje sadržaja i naloga', [
          'Platforma zadržava pravo da ukloni sadržaj, ograniči pristup ili privremeno odnosno trajno suspenduje korisnički nalog ako utvrdi ili osnovano posumnja da korisnik krši ove Uslove korišćenja, važeće propise ili prava trećih lica.',
          'Platforma može preduzeti navedene mere i bez prethodne najave kada je to neophodno radi zaštite drugih korisnika, bezbednosti sistema ili poštovanja zakonskih obaveza.',
        ]),
        b.section('16', 'Intelektualna svojina', [
          'Softver, dizajn, struktura sajta, tekstovi, logotipi i drugi elementi platforme, osim sadržaja koji postavljaju korisnici, pripadaju rukovaocu ili licima koja su za to dala odgovarajuća prava.',
          'Bez prethodne dozvole nije dozvoljeno neovlašćeno kopiranje, distribucija, prerada ili korišćenje sadržaja platforme, osim u meri dozvoljenoj zakonom.',
        ]),
        b.section('17', 'Privatnost i obrada podataka', [
          'Pravila koja se odnose na prikupljanje, obradu, čuvanje i zaštitu podataka o ličnosti uređena su posebnim dokumentom Politika privatnosti, koji je sastavni deo pravnog okvira korišćenja platforme.',
          'Prihvatanjem ovih Uslova korisnik potvrđuje i da je upoznat sa Politikom privatnosti.',
        ]),
        b.section('18', 'Izmene uslova, merodavno pravo i nadležnost', [
          'Rukovalac zadržava pravo da izmeni ili dopuni ove Uslove korišćenja u bilo kom trenutku, naročito radi usklađivanja sa razvojem platforme, poslovnog modela ili promenama važećih propisa Republike Srbije.',
          'Ažurirana verzija biće objavljena na platformi, uz naznačen datum stupanja na snagu.',
          'Na ove Uslove korišćenja primenjuje se pravo Republike Srbije. Za sporove koji nastanu u vezi sa korišćenjem platforme nadležan je stvarno nadležni sud u Republici Srbiji, osim ako obavezujući propisi nalažu drugačije.',
        ]),
        b.section('19', 'Kontakt podaci', [
          'Za sva pitanja, primedbe ili prijave u vezi sa ovim Uslovima korišćenja možete se obratiti na: Vladimir Ivanović, Crvenih Hrastova 6, Beograd, Republika Srbija, email: vrvlada@gmail.com.',
        ]),
      ],
    );
  }
}
