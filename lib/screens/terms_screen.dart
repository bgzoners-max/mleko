import 'package:flutter/material.dart';
import 'package:mleko/core/web_seo.dart';
import 'package:mleko/core/responsive.dart';

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
    final horizontalPadding = Breakpoints.horizontalPadding(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Uslovi korišćenja')),
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
              child: const _TermsContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

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
                'Pravna pravila korišćenja platforme',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Korišćenjem platforme potvrđujete da ste pročitali, razumeli i prihvatili uslove navedene u nastavku.',
                style: body,
              ),
            ],
          ),
        ),
        SizedBox(height: sectionSpacing),
        Text('USLOVI KORIŠĆENJA – domaćimarket.rs', style: pageTitle),
        const SizedBox(height: 12),
        Text('Datum stupanja na snagu: 9. april 2026.', style: body),
        section('1', 'Opšte odredbe', [
          'Dobrodošli na platformu domaćimarket.rs, koja omogućava povezivanje proizvođača domaćih proizvoda i krajnjih kupaca.',
          'Korišćenjem platforme korisnik potvrđuje da je pročitao, razumeo i prihvatio ove Uslove korišćenja.',
        ]),
        section('2', 'Opis usluge', [
          'Platforma omogućava registraciju korisnika, objavljivanje i pregled ponude proizvoda, komunikaciju između kupaca i prodavaca, kao i slanje upita i porudžbina kroz digitalni interfejs.',
          'Platforma ne učestvuje direktno u proizvodnji, distribuciji niti fizičkoj isporuci proizvoda, osim ako naknadno ne bude izričito objavljeno drugačije.',
        ]),
        sectionBullets('3', 'Registracija i korisnički nalog', [
          'korisnik je dužan da unese tačne, potpune i ažurne podatke',
          'korisnik je odgovoran za čuvanje svojih pristupnih podataka i za sve aktivnosti koje se izvrše preko njegovog naloga',
          'zabranjeno je otvaranje naloga sa lažnim identitetom ili u ime trećeg lica bez ovlašćenja',
        ]),
        sectionBullets('4', 'Obaveze prodavca', [
          'da proizvodi, opisi, cene, fotografije i druge objavljene informacije budu tačni i da ne dovode kupce u zabludu',
          'da je ovlašćen da nudi proizvode koje objavljuje i da postupa u skladu sa važećim propisima Republike Srbije',
          'da snosi odgovornost za kvalitet, bezbednost, ispravnost, deklarisanje i zakonitost svojih proizvoda',
          'da ne objavljuje zabranjene, nedozvoljene ili obmanjujuće sadržaje i ponude',
        ]),
        sectionBullets('5', 'Obaveze kupca', [
          'da koristi platformu savesno i u skladu sa važećim propisima',
          'da ne koristi platformu za zloupotrebu, uznemiravanje, lažno naručivanje ili nanošenje štete drugim korisnicima',
          'da samostalno proceni ponudu prodavca pre donošenja odluke o kupovini ili kontaktu',
        ]),
        section('6', 'Uloga platforme i ograničenje odgovornosti', [
          'Platforma domaćimarket.rs deluje kao digitalna platforma za povezivanje korisnika i ne garantuje kvalitet, bezbednost, zdravstvenu ispravnost, legalnost, raspoloživost niti tačnost ponude koju objavljuju korisnici.',
          'Platforma ne snosi odgovornost za štetu nastalu iz odnosa između kupca i prodavca, uključujući sporove u vezi sa kvalitetom proizvoda, isporukom, cenom, reklamacijama ili drugim okolnostima pojedinačne transakcije, osim u meri u kojoj je takva odgovornost izričito propisana obavezujućim pravom.',
        ]),
        sectionBullets('7', 'Zabranjene aktivnosti', [
          'objavljivanje lažnih, obmanjujućih, nezakonitih ili uvredljivih sadržaja',
          'lažno predstavljanje, zloupotreba tuđih podataka ili neovlašćeno korišćenje naloga',
          'objavljivanje proizvoda ili sadržaja čije je stavljanje u promet ili prikazivanje zabranjeno zakonom',
          'narušavanje bezbednosti sistema, pokušaji neovlašćenog pristupa ili ometanje rada platforme',
        ]),
        section('8', 'Uklanjanje sadržaja i naloga', [
          'Platforma zadržava pravo da ukloni sadržaj, ograniči pristup ili privremeno odnosno trajno suspenduje korisnički nalog ako utvrdi ili osnovano posumnja da korisnik krši ove Uslove korišćenja, važeće propise ili prava trećih lica.',
          'Platforma može preduzeti navedene mere i bez prethodne najave kada je to neophodno radi zaštite drugih korisnika, bezbednosti sistema ili poštovanja zakonskih obaveza.',
        ]),
        section('9', 'Intelektualna svojina', [
          'Softver, dizajn, struktura sajta, tekstovi, logotipi i drugi elementi platforme, osim sadržaja koji postavljaju korisnici, pripadaju rukovaocu ili licima koja su za to dala odgovarajuća prava.',
          'Bez prethodne dozvole nije dozvoljeno neovlašćeno kopiranje, distribucija, prerada ili korišćenje sadržaja platforme, osim u meri dozvoljenoj zakonom.',
        ]),
        section('10', 'Privatnost i obrada podataka', [
          'Pravila koja se odnose na prikupljanje, obradu, čuvanje i zaštitu podataka o ličnosti uređena su posebnim dokumentom Politika privatnosti, koji je sastavni deo pravnog okvira korišćenja platforme.',
          'Prihvatanjem ovih Uslova korisnik potvrđuje i da je upoznat sa Politikom privatnosti.',
        ]),
        section('11', 'Izmene uslova', [
          'Rukovalac zadržava pravo da izmeni ili dopuni ove Uslove korišćenja u bilo kom trenutku, naročito radi usklađivanja sa razvojem platforme, poslovnog modela ili promenama važećih propisa.',
          'Ažurirana verzija biće objavljena na platformi, uz naznačen datum stupanja na snagu.',
        ]),
        section('12', 'Merodavno pravo i nadležnost', [
          'Na ove Uslove korišćenja primenjuje se pravo Republike Srbije.',
          'Za sporove koji nastanu u vezi sa korišćenjem platforme nadležan je stvarno nadležni sud u Republici Srbiji, osim ako obavezujući propisi nalažu drugačije.',
        ]),
        section('13', 'Kontakt', [
          'Za pitanja u vezi sa ovim Uslovima korišćenja možete se obratiti na: Vladimir Ivanović, Crvenih Hrastova 6, Beograd, Republika Srbija, email: vrvlada@gmail.com.',
        ]),
      ],
    );
  }
}
