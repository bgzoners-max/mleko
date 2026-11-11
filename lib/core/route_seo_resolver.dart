import 'web_seo.dart';

class RouteSeoSpec {
  const RouteSeoSpec({
    required this.title,
    required this.description,
    required this.path,
    required this.robots,
  });

  final String title;
  final String description;
  final String path;
  final String robots;
}

const String defaultIndexRobots = 'index, follow, max-image-preview:large';
const String noIndexFollowRobots = 'noindex, follow';
const String noIndexNoFollowRobots = 'noindex, nofollow';

const Map<String, ({String name, String description})> classifiedCategorySeoMeta = {
  'poljoprivreda': (
    name: 'Poljoprivreda — traktori, priključci, seme i stoka',
    description:
        'Besplatni mali oglasi za poljoprivredu: traktori (IMT, Zetor, Rakovica), priključne mašine, kombajni, seme, đubrivo i stoka na Domaćem Marketu.',
  ),
  'vozila': (
    name: 'Vozila i Auto-Moto oglasi',
    description:
        'Polovni automobili, motocikli, kombiji, traktori, auto delovi i gume direktno od vlasnika u Srbiji bez provizije.',
  ),
  'masine_alati': (
    name: 'Mašine i alati za radionicu i industriju',
    description:
        'Ručni i električni alati, aparati za zavarivanje, kompresori, strugovi i građevinske mašine u besplatnim oglasima.',
  ),
  'dom_basta': (
    name: 'Dom i bašta — nameštaj, uređaji i oprema za dvorište',
    description:
        'Nameštaj, bela tehnika, kosilice, trimeri, bazeni, baštenske garniture i sve za uređenje kuće i okućnice.',
  ),
  'telefoni': (
    name: 'Mobilni telefoni, tableti i oprema',
    description:
        'Novi i polovni pametni telefoni, iPhone, Samsung, Xiaomi, pametni satovi i oprema bez posrednika.',
  ),
  'tehnika': (
    name: 'Tehnika, računari, laptopovi i audio-video',
    description:
        'Laptopovi, desktop računari, televizori, gejming konzole i foto oprema u besplatnim malim oglasima u Srbiji.',
  ),
  'nekretnine': (
    name: 'Nekretnine — kuće, stanovi, placevi i seoska imanja',
    description:
        'Prodaja i izdavanje stanova, kuća, vikendica, poljoprivrednog zemljišta i seoskih imanja direktno od vlasnika.',
  ),
  'gradjevinarstvo': (
    name: 'Građevinarstvo — materijal, stolarija i mašine',
    description:
        'Građevinski materijal, drvena građa, PVC stolarija, krovni pokrivači, skele i građevinske mašine.',
  ),
  'odeca_obuca': (
    name: 'Odeća, obuća i modni dodaci',
    description:
        'Ženska, muška i radna odeća, sportska i kožna obuća, jakne i torbe u besplatnim oglasima.',
  ),
  'deca_bebe': (
    name: 'Deca i bebe — kolica, kreveci, odeća i igračke',
    description:
        'Dečija kolica, auto sedišta, kreveci, oprema za bebe, dečija odeća i bicikli bez provizije.',
  ),
  'sport_hobi': (
    name: 'Sport, biciklizam, ribolov i hobi',
    description:
        'Bicikli, fitness sprave, oprema za planinarenje, lov i ribolov, muzički instrumenti i kolekcionarstvo.',
  ),
  'ljubimci': (
    name: 'Kućni ljubimci i oprema za životinje',
    description:
        'Kućni ljubimci, psi, mačke, ptice, akvaristika i oprema za negu ljubimaca širom Srbije.',
  ),
  'usluge': (
    name: 'Usluge, majstori, prevoz i poljoprivredni radovi',
    description:
        'Komercijalne i zanatske usluge: prevoz robe, građevinski radovi, vodoinstalateri, električari i mašinska obrada zemlje.',
  ),
  'zdravlje_lepota': (
    name: 'Zdravlje, lepota i prirodni preparati',
    description:
        'Prirodna kozmetika, etarska ulja, aparati za negu i medicinska pomagala u besplatnim oglasima.',
  ),
  'knjige_edukacija': (
    name: 'Knjige, udžbenici i edukacija',
    description:
        'Školski udžbenici, beletristika, stručna literatura, stripovi i časovi učenja bez posrednika.',
  ),
  'umetnost_rukotvorine': (
    name: 'Umetnost, antikviteti i domaće rukotvorine',
    description:
        'Slike, skulpture, etno suveniri, pleteni i vezeni radovi, keramika i antikviteti domaćih zanatlija.',
  ),
};

const Map<String, ({String name, String description})> foodCategorySeoMeta = {
  'mlecni-proizvodi': (
    name: 'Domaći mlečni proizvodi',
    description:
        'Sveže domaće mleko, beli sir, kačkavalj, kajmak, surutka i jogurt direktno sa srpskih farmi i gazdinstava.',
  ),
  'meso': (
    name: 'Meso, riba i delikatesi',
    description:
        'Prava domaća pršuta, dimljena slanina, kobasice, čvarci, sveže meso i rečna riba sa srpskih domaćinstava.',
  ),
  'voce-i-povrce': (
    name: 'Sveže voće i povrće sa sela',
    description:
        'Prirodno gajeno voće i povrće direktno od poljoprivrednika: krompir, luk, jabuke, šljive, jagode, maline i borovnice.',
  ),
  'med-i-pcelinji-proizvodi': (
    name: 'Domaći med i pčelinji proizvodi',
    description:
        'Prirodni bagremov, livadski, lipov i šumski med, polen, propolis i matični mleč direktno od pčelara iz Srbije.',
  ),
  'slana-zimnica': (
    name: 'Slana zimnica i domaći ajvar',
    description:
        'Domaći ajvar od pečenih paprika, pinđur, ljutenica, kiseli krastavci, turšija i kiseli kupus po tradicionalnim receptima.',
  ),
  'slatka-zimnica-i-dzemovi': (
    name: 'Džemovi, slatko i pekmez',
    description:
        'Domaći džem od šljiva, kajsija i jagoda, tradicionalno slatko, šipurak i kompoti bez veštačkih konzervansa.',
  ),
  'jaja': (
    name: 'Domaća kokošija i prepeličija jaja',
    description:
        'Sveža domaća jaja od koka iz slobodnog uzgoja i jaja japanskih prepelica direktno sa gazdinstva.',
  ),
  'vina-i-domace-rakije': (
    name: 'Domaće rakije, vina i likeri',
    description:
        'Šljivovica, dunjevača, kajsijevača, viljamovka, medovača, domaći likeri i vina malih porodičnih podruma Srbije.',
  ),
  'sokovi-i-domaci-sirupi': (
    name: 'Prirodni sokovi i domaći sirupi',
    description:
        'Hladno ceđeni sokovi bez šećera, domaći sok od paradajza, sirup od zove, nane, višnje i aronije.',
  ),
  'brasno-testenine-i-zitarice': (
    name: 'Brašno, domaće testenine i žitarice',
    description:
        'Integralno i kukuruzno brašno mleveno na potočari, domaće kore za pitu, rezanci i mlado žito.',
  ),
  'hladno-cedjena-ulja-i-sirceta': (
    name: 'Hladno ceđena ulja i domaća sirćeta',
    description:
        'Hladno ceđeno ulje bundeve, suncokreta i lana, i pravo domaće jabukovo sirće sa sela.',
  ),
  'cajevi-zacini-i-lekovito-bilje': (
    name: 'Čajevi, začini i lekovito bilje',
    description:
        'Samonikli planinski i livadski čajevi, nana, kamilica, rtanjski čaj, sušeno začinsko bilje i mlevena paprika.',
  ),
  'orasasti-plodovi-semenke-i-suvo-voce': (
    name: 'Orašasti plodovi, semenke i suvo voće',
    description:
        'Domaći orasi, lešnici, bademi, golica bundeve, suve šljive, sušene jabuke i kruške.',
  ),
  'gljive-i-tartufi': (
    name: 'Domaće i šumske gljive i tartufi',
    description:
        'Sveži i sušeni vrganji, lisičarke, šitake, bukovače i crni i beli tartufi sa srpskih terena.',
  ),
};

RouteSeoSpec? resolveQueryRouteSeo(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return null;

  final routePath = uri.path.isEmpty ? '/' : uri.path;
  final normalizedPath =
      routePath.length > 1 && routePath.endsWith('/')
          ? routePath.substring(0, routePath.length - 1)
          : routePath;

  final q = uri.queryParameters['q']?.trim() ?? '';
  final category = uri.queryParameters['category']?.trim() ?? '';

  if (normalizedPath == '/terms') {
    return const RouteSeoSpec(
      title: 'Uslovi korišćenja | domaćimarket.rs',
      description:
          'Pravila korišćenja platforme domaćimarket.rs, usklađena sa zakonima Republike Srbije.',
      path: '/uslovi-koriscenja',
      robots: defaultIndexRobots,
    );
  }

  if (normalizedPath == '/search') {
    if (q.isEmpty && category.isEmpty) return null;
    final term = q.isNotEmpty ? q : category;
    final isTemplate = term == '{search_term_string}';
    return RouteSeoSpec(
      title: isTemplate
          ? 'Pretraga proizvoda | Domaći Market'
          : 'Pretraga: $term | Domaći Market',
      description:
          'Rezultati pretrage domaćih proizvoda na Domaćem Marketu direktno od proizvođača u Srbiji.',
      path: '/search',
      robots: noIndexFollowRobots,
    );
  }

  if (normalizedPath == '/classifieds') {
    if (q.isNotEmpty) {
      final isTemplate = q == '{search_term_string}';
      final canonicalPath = category.isNotEmpty
          ? '/classifieds?category=${Uri.encodeQueryComponent(category)}'
          : '/classifieds';
      return RouteSeoSpec(
        title: isTemplate
            ? 'Pretraga malih oglasa | Domaći Market'
            : 'Pretraga malih oglasa: $q | Domaći Market',
        description:
            'Pretraga besplatnih malih oglasa u Srbiji na platformi Domaći Market bez posrednika.',
        path: canonicalPath,
        robots: noIndexFollowRobots,
      );
    }

    if (category.isNotEmpty) {
      final meta = classifiedCategorySeoMeta[category];
      final encoded = Uri.encodeQueryComponent(category);
      if (meta != null) {
        return RouteSeoSpec(
          title: '${meta.name} — Mali Oglasi | Domaći Market',
          description: meta.description,
          path: '/classifieds?category=$encoded',
          robots: defaultIndexRobots,
        );
      }
      return RouteSeoSpec(
        title: 'Mali oglasi — $category | Domaći Market',
        description:
            'Pregledajte besplatne male oglase u kategoriji $category direktno od vlasnika u Srbiji.',
        path: '/classifieds?category=$encoded',
        robots: defaultIndexRobots,
      );
    }

    return null;
  }

  if (normalizedPath == '/categories' && category.isNotEmpty) {
    final meta = foodCategorySeoMeta[category];
    final encoded = Uri.encodeQueryComponent(category);
    if (meta != null) {
      return RouteSeoSpec(
        title: '${meta.name} | Pijaca | Domaći Market',
        description: meta.description,
        path: '/categories?category=$encoded',
        robots: defaultIndexRobots,
      );
    }
    return const RouteSeoSpec(
      title: 'Kategorije domaćih proizvoda | Domaći Market',
      description:
          'Pregledajte sve kategorije domaće hrane direktno sa seoskih gazdinstava u Srbiji.',
      path: '/categories',
      robots: noIndexFollowRobots,
    );
  }

  return null;
}

void applyNotFoundSeoMetadata({String? path}) {
  setPageMetadata(
    title: 'Stranica nije pronađena (404) | Domaći Market',
    description:
        'Tražena stranica ne postoji ili je uklonjena. Pogledajte domaću hranu sa sela i besplatne male oglase na Domaćem Marketu.',
    path: (path != null && path.isNotEmpty) ? path : '/',
    robots: noIndexNoFollowRobots,
  );
}

