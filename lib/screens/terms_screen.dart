import 'package:flutter/material.dart';
import 'package:mleko/core/responsive.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uslovi korišćenja')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.isTabletOrLarger(context) ? 720 : double.infinity,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Breakpoints.horizontalPadding(context)).copyWith(bottom: 32),
            child: const _TermsContent(),
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
    final body = theme.textTheme.bodyMedium;
    final heading = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    Widget section(String number, String title, List<String> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('$number. $title', style: heading),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(item, style: body),
              )),
        ],
      );
    }

    Widget bullet(String text) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
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
        const SizedBox(height: 8),
        Text('USLOVI KORIŠĆENJA – „Naše selo"',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),

        // 1
        section('1', 'Opšte odredbe', [
          'Dobrodošli na platformu „Naše selo" (u daljem tekstu: Platforma), koja omogućava povezivanje proizvođača domaćih proizvoda i krajnjih kupaca.',
          'Korišćenjem Platforme, korisnik potvrđuje da je pročitao, razumeo i prihvatio ove Uslove korišćenja.',
        ]),

        // 2
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('2. Opis usluge', style: heading),
            const SizedBox(height: 8),
            Text('Platforma „Naše selo" omogućava:', style: body),
            const SizedBox(height: 4),
            bullet('registraciju domaćinstava i proizvođača'),
            bullet('objavljivanje i pregled ponude proizvoda'),
            bullet('komunikaciju između kupaca i proizvođača'),
            const SizedBox(height: 6),
            Text('Platforma ne učestvuje direktno u proizvodnji, distribuciji niti prodaji proizvoda.', style: body),
          ],
        ),

        // 3
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('3. Registracija korisnika', style: heading),
            const SizedBox(height: 8),
            Text('Registracijom na Platformu korisnik potvrđuje da:', style: body),
            const SizedBox(height: 4),
            bullet('su svi uneti podaci tačni i istiniti'),
            bullet('ima pravo da koristi Platformu u skladu sa važećim zakonima'),
            bullet('neće zloupotrebljavati sistem niti unositi lažne informacije'),
            const SizedBox(height: 6),
            Text('Korisnik je odgovoran za čuvanje svojih pristupnih podataka.', style: body),
          ],
        ),

        // 4
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('4. Odgovornost proizvođača', style: heading),
            const SizedBox(height: 8),
            Text('Korisnik koji registruje domaćinstvo ili proizvode izjavljuje i garantuje:', style: body),
            const SizedBox(height: 4),
            bullet('da ima pravo da se bavi proizvodnjom i/ili prodajom hrane u skladu sa zakonima Republike Srbije'),
            bullet('da poseduje sve potrebne dozvole, ukoliko su zakonom propisane'),
            bullet('da proizvodi ispunjavaju sve higijenske i zdravstvene standarde'),
            bullet('da redovno proverava zdravstvenu ispravnost proizvoda'),
            bullet('da su svi opisi proizvoda tačni i ne dovode kupce u zabludu'),
            const SizedBox(height: 6),
            Text('Korisnik snosi punu odgovornost za kvalitet, bezbednost i ispravnost svojih proizvoda.', style: body),
          ],
        ),

        // 5
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('5. Ograničenje odgovornosti platforme', style: heading),
            const SizedBox(height: 8),
            Text('Platforma „Naše selo":', style: body),
            const SizedBox(height: 4),
            bullet('ne garantuje kvalitet, bezbednost niti ispravnost proizvoda'),
            bullet('ne snosi odgovornost za eventualne štete nastale korišćenjem proizvoda'),
            bullet('ne učestvuje u transakcijama između korisnika'),
            bullet('ne odgovara za netačne ili obmanjujuće informacije koje unesu korisnici'),
            const SizedBox(height: 6),
            Text('Sva odgovornost je isključivo na proizvođaču i korisnicima koji učestvuju u razmeni.', style: body),
          ],
        ),

        // 6
        sectionBullets('6', 'Zabranjene aktivnosti', [
          'objavljivanje lažnih ili obmanjujućih informacija',
          'prodaja proizvoda koji nisu dozvoljeni zakonom',
          'kršenje važećih zdravstvenih i bezbednosnih propisa',
          'zloupotreba platforme u bilo kom obliku',
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Platforma zadržava pravo da ukloni sadržaj ili nalog koji krši pravila.', style: body),
        ),

        // 7
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text('7. Uklanjanje naloga', style: heading),
            const SizedBox(height: 8),
            Text('Platforma zadržava pravo da:', style: body),
            const SizedBox(height: 4),
            bullet('privremeno ili trajno suspenduje nalog'),
            bullet('ukloni sadržaj bez prethodne najave'),
            const SizedBox(height: 6),
            Text('u slučaju kršenja ovih Uslova.', style: body),
          ],
        ),

        // 8
        section('8', 'Privatnost podataka', [
          'Platforma prikuplja i obrađuje lične podatke u skladu sa važećim zakonima o zaštiti podataka o ličnosti.',
          'Podaci se koriste isključivo u svrhu funkcionisanja Platforme.',
        ]),

        // 9
        section('9', 'Izmene uslova', [
          'Platforma zadržava pravo da izmeni ove Uslove u bilo kom trenutku.',
          'Korisnici će biti obavešteni o izmenama putem aplikacije ili sajta.',
        ]),

        // 10
        section('10', 'Završne odredbe', [
          'Na ove Uslove primenjuje se pravo Republike Srbije.',
          'U slučaju spora, nadležan je sud u Republici Srbiji.',
        ]),
      ],
    );
  }
}
