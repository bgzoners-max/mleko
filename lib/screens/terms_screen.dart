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
          'Pravila korišćenja platforme domaćimarket.rs, uključujući obaveze korisnika, prodavaca i ograničenja odgovornosti.',
      path: '/uslovi-koriscenja',
    );

    final b = LegalContentBuilder(context);

    return LegalDocumentLayout(
      appBarTitle: 'Uslovi korišćenja',
      summaryHeader: 'Pravna pravila korišćenja platforme',
      summaryText:
          'Korišćenjem platforme potvrđujete da ste pročitali, razumeli i prihvatili uslove navedene u nastavku.',
      pageTitle: 'USLOVI KORIŠĆENJA – domaćimarket.rs',
      effectiveDate: '9. april 2026.',
      children: [
        b.section('1', 'Opšte odredbe', [
          'Dobrodošli na platformu domaćimarket.rs, koja omogućava povezivanje proizvođača domaćih proizvoda i krajnjih kupaca.',
          'Korišćenjem platforme korisnik potvrđuje da je pročitao, razumeo i prihvatio ove Uslove korišćenja.',
        ]),
        b.section('2', 'Opis usluge', [
          'Platforma omogućava registraciju korisnika, objavljivanje i pregled ponude proizvoda, komunikaciju između kupaca i prodavaca, kao i slanje upita i porudžbina kroz digitalni interfejs.',
          'Platforma ne učestvuje direktno u proizvodnji, distribuciji niti fizičkoj isporuci proizvoda, osim ako naknadno ne bude izričito objavljeno drugačije.',
        ]),
        b.sectionBullets('3', 'Registracija i korisnički nalog', [
          'korisnik je dužan da unese tačne, potpune i ažurne podatke',
          'korisnik je odgovoran za čuvanje svojih pristupnih podataka i za sve aktivnosti koje se izvrše preko njegovog naloga',
          'zabranjeno je otvaranje naloga sa lažnim identitetom ili u ime trećeg lica bez ovlašćenja',
        ]),
        b.sectionBullets('4', 'Obaveze prodavca', [
          'da proizvodi, opisi, cene, fotografije i druge objavljene informacije budu tačni i da ne dovode kupce u zabludu',
          'da je ovlašćen da nudi proizvode koje objavljuje i da postupa u skladu sa važećim propisima Republike Srbije',
          'da snosi odgovornost za kvalitet, bezbednost, ispravnost, deklarisanje i zakonitost svojih proizvoda',
          'da ne objavljuje zabranjene, nedozvoljene ili obmanjujuće sadržaje i ponude',
        ]),
        b.sectionBullets('5', 'Obaveze kupca', [
          'da koristi platformu savesno i u skladu sa važećim propisima',
          'da ne koristi platformu za zloupotrebu, uznemiravanje, lažno naručivanje ili nanošenje štete drugim korisnicima',
          'da samostalno proceni ponudu prodavca pre donošenja odluke o kupovini ili kontaktu',
        ]),
        b.sectionBullets(
            '6', 'Posebna pravila za sveže meso i kvarljive namirnice', [
          'prodavac koji nudi sveže meso, proizvode životinjskog porekla ili druge kvarljive namirnice dužan je da postupa u skladu sa svim važećim sanitarnim, veterinarskim, deklarativnim i drugim propisima Republike Srbije',
          'prodavac je isključivo odgovoran za zakonitost stavljanja takvih proizvoda u promet, njihovu zdravstvenu ispravnost, sledljivost, način pakovanja, deklarisanja, transporta i isporuke',
          'kvarljive namirnice moraju biti čuvane, transportovane i predate kupcu u odgovarajućem temperaturnom režimu, uz poštovanje rokova upotrebe, uslova skladištenja i svih pravila potrebnih za očuvanje bezbednosti hrane',
          'prodavac je dužan da u opisu proizvoda i prilikom dogovora sa kupcem jasno navede bitne informacije o roku trajanja, načinu čuvanja, potrebnom temperaturnom režimu i eventualnim posebnim uslovima prijema ili preuzimanja robe',
          'platforma ne vrši kontrolu hladnog lanca, skladištenja, prevoza niti fizičke primopredaje svežeg mesa i kvarljivih namirnica i ne garantuje da su ti uslovi ispunjeni, osim ako izričito ne preuzme takvu obavezu posebnim pisanom obaveštenjem',
        ]),
        b.section('7',
            'Prijem robe, reklamacije i odgovornost za kvarljive proizvode', [
          'Kupac je dužan da po prijemu ili preuzimanju svežeg mesa i drugih kvarljivih namirnica bez odlaganja proveri očigledno stanje robe, uključujući izgled ambalaže, vidljiva oštećenja, očigledna odstupanja i druge nedostatke koji se mogu uočiti redovnim pregledom pri primopredaji.',
          'Reklamacije koje se odnose na očigledne nedostatke, pogrešnu isporuku, nepravilnosti pri isporuci ili sumnju na narušenu ispravnost kvarljive robe kupac treba da prijavi prodavcu bez odlaganja, po mogućnosti odmah po prijemu robe, uz dostavljanje raspoloživih dokaza kao što su fotografije, opis zatečenog stanja i vreme prijema.',
          'Nakon izvršene primopredaje kupac preuzima odgovornost za dalje pravilno rukovanje, čuvanje, hlađenje, zamrzavanje, pripremu i upotrebu kvarljive robe, u skladu sa prirodom proizvoda i uputstvima prodavca ili deklaracije.',
          'Platforma nije ugovorna strana u sporu povodom kvaliteta, kvarljivosti, načina čuvanja, prekida hladnog lanca, isporuke ili reklamacije takvih proizvoda i ne snosi odgovornost za štetu nastalu nakon predaje robe kupcu, osim u meri u kojoj je takva odgovornost izričito propisana obavezujućim pravom.',
        ]),
        b.section('8', 'Uloga platforme i ograničenje odgovornosti', [
          'Platforma domaćimarket.rs deluje kao digitalna platforma za povezivanje korisnika i ne garantuje kvalitet, bezbednost, zdravstvenu ispravnost, legalnost, raspoloživost niti tačnost ponude koju objavljuju korisnici.',
          'Platforma ne snosi odgovornost za štetu nastalu iz odnosa između kupca i prodavca, uključujući sporove u vezi sa kvalitetom proizvoda, isporukom, cenom, reklamacijama ili drugim okolnostima pojedinačne transakcije, osim u meri u kojoj je takva odgovornost izričito propisana obavezujućim pravom.',
        ]),
        b.sectionBullets('9', 'Zabranjene aktivnosti', [
          'objavljivanje lažnih, obmanjujućih, nezakonitih ili uvredljivih sadržaja',
          'lažno predstavljanje, zloupotreba tuđih podataka ili neovlašćeno korišćenje naloga',
          'objavljivanje proizvoda ili sadržaja čije je stavljanje u promet ili prikazivanje zabranjeno zakonom',
          'narušavanje bezbednosti sistema, pokušaji neovlašćenog pristupa ili ometanje rada platforme',
        ]),
        b.section('10', 'Uklanjanje sadržaja i naloga', [
          'Platforma zadržava pravo da ukloni sadržaj, ograniči pristup ili privremeno odnosno trajno suspenduje korisnički nalog ako utvrdi ili osnovano posumnja da korisnik krši ove Uslove korišćenja, važeće propise ili prava trećih lica.',
          'Platforma može preduzeti navedene mere i bez prethodne najave kada je to neophodno radi zaštite drugih korisnika, bezbednosti sistema ili poštovanja zakonskih obaveza.',
        ]),
        b.section('11', 'Intelektualna svojina', [
          'Softver, dizajn, struktura sajta, tekstovi, logotipi i drugi elementi platforme, osim sadržaja koji postavljaju korisnici, pripadaju rukovaocu ili licima koja su za to dala odgovarajuća prava.',
          'Bez prethodne dozvole nije dozvoljeno neovlašćeno kopiranje, distribucija, prerada ili korišćenje sadržaja platforme, osim u meri dozvoljenoj zakonom.',
        ]),
        b.section('12', 'Privatnost i obrada podataka', [
          'Pravila koja se odnose na prikupljanje, obradu, čuvanje i zaštitu podataka o ličnosti uređena su posebnim dokumentom Politika privatnosti, koji je sastavni deo pravnog okvira korišćenja platforme.',
          'Prihvatanjem ovih Uslova korisnik potvrđuje i da je upoznat sa Politikom privatnosti.',
        ]),
        b.section('13', 'Izmene uslova', [
          'Rukovalac zadržava pravo da izmeni ili dopuni ove Uslove korišćenja u bilo kom trenutku, naročito radi usklađivanja sa razvojem platforme, poslovnog modela ili promenama važećih propisa.',
          'Ažurirana verzija biće objavljena na platformi, uz naznačen datum stupanja na snagu.',
        ]),
        b.section('14', 'Merodavno pravo i nadležnost', [
          'Na ove Uslove korišćenja primenjuje se pravo Republike Srbije.',
          'Za sporove koji nastanu u vezi sa korišćenjem platforme nadležan je stvarno nadležni sud u Republici Srbiji, osim ako obavezujući propisi nalažu drugačije.',
        ]),
        b.section('15', 'Kontakt', [
          'Za pitanja u vezi sa ovim Uslovima korišćenja možete se obratiti na: Vladimir Ivanović, Crvenih Hrastova 6, Beograd, Republika Srbija, email: vrvlada@gmail.com.',
        ]),
      ],
    );
  }
}
