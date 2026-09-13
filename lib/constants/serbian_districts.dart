/// Model upravnog okruga u Republici Srbiji za precizno filtriranje lokacija nekretnina.
class SerbianDistrict {
  final String id;
  final String name;
  final String region;
  final List<String> cities;

  const SerbianDistrict({
    required this.id,
    required this.name,
    required this.region,
    required this.cities,
  });
}

/// Centralizovana lista okruga i geografsko mapiranje opština u Srbiji.
class SerbianDistricts {
  SerbianDistricts._();

  static const List<SerbianDistrict> all = [
    // Beograd
    SerbianDistrict(
      id: 'beogradski',
      name: 'Grad Beograd',
      region: 'Beograd',
      cities: [
        'Beograd',
        'Zemun',
        'Novi Beograd',
        'Vračar',
        'Stari Grad',
        'Palilula',
        'Zvezdara',
        'Voždovac',
        'Čukarica',
        'Rakovica',
        'Surčin',
        'Grocka',
        'Barajevo',
        'Mladenovac',
        'Obrenovac',
        'Lazarevac',
        'Sopot',
      ],
    ),

    // Vojvodina
    SerbianDistrict(
      id: 'juznobacki',
      name: 'Južnobački okrug',
      region: 'Vojvodina',
      cities: [
        'Novi Sad',
        'Bačka Palanka',
        'Vrbas',
        'Bečej',
        'Temerin',
        'Žabalj',
        'Titel',
        'Srbobran',
        'Bački Petrovac',
        'Beočin',
        'Sremski Karlovci',
      ],
    ),
    SerbianDistrict(
      id: 'severnobacki',
      name: 'Severnobački okrug',
      region: 'Vojvodina',
      cities: ['Subotica', 'Bačka Topola', 'Mali Iđoš'],
    ),
    SerbianDistrict(
      id: 'zapadnobacki',
      name: 'Zapadnobački okrug',
      region: 'Vojvodina',
      cities: ['Sombor', 'Apatin', 'Kula', 'Odžaci'],
    ),
    SerbianDistrict(
      id: 'sremski',
      name: 'Sremski okrug',
      region: 'Vojvodina',
      cities: [
        'Sremska Mitrovica',
        'Stara Pazova',
        'Inđija',
        'Ruma',
        'Šid',
        'Pećinci',
        'Irig',
      ],
    ),
    SerbianDistrict(
      id: 'juznobanatski',
      name: 'Južnobanatski okrug',
      region: 'Vojvodina',
      cities: [
        'Pančevo',
        'Vršac',
        'Kovin',
        'Alibunar',
        'Bela Crkva',
        'Kovačica',
        'Opovo',
        'Plandište',
      ],
    ),
    SerbianDistrict(
      id: 'srednjobanatski',
      name: 'Srednjobanatski okrug',
      region: 'Vojvodina',
      cities: ['Zrenjanin', 'Novi Bečej', 'Žitište', 'Sečanj', 'Nova Crnja'],
    ),
    SerbianDistrict(
      id: 'severnobanatski',
      name: 'Severnobanatski okrug',
      region: 'Vojvodina',
      cities: ['Kikinda', 'Senta', 'Ada', 'Kanjiža', 'Novi Kneževac', 'Čoka'],
    ),

    // Šumadija i Zapadna Srbija
    SerbianDistrict(
      id: 'sumadijski',
      name: 'Šumadijski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: [
        'Kragujevac',
        'Aranđelovac',
        'Topola',
        'Batočina',
        'Knić',
        'Lapovo',
        'Rača',
      ],
    ),
    SerbianDistrict(
      id: 'moravicki',
      name: 'Moravički okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: ['Čačak', 'Gornji Milanovac', 'Ivanjica', 'Lučani', 'Guča'],
    ),
    SerbianDistrict(
      id: 'zlatiborski',
      name: 'Zlatiborski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: [
        'Užice',
        'Zlatibor',
        'Čajetina',
        'Požega',
        'Priboj',
        'Prijepolje',
        'Sjenica',
        'Bajina Bašta',
        'Nova Varoš',
        'Arilje',
        'Kosjerić',
      ],
    ),
    SerbianDistrict(
      id: 'kolubarski',
      name: 'Kolubarski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: ['Valjevo', 'Ub', 'Lajkovac', 'Ljig', 'Mionica', 'Osečina'],
    ),
    SerbianDistrict(
      id: 'macvanski',
      name: 'Mačvanski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: [
        'Šabac',
        'Loznica',
        'Bogatić',
        'Vladimirci',
        'Koceljeva',
        'Mali Zvornik',
        'Krupanj',
        'Ljubovija',
      ],
    ),
    SerbianDistrict(
      id: 'pomoravski',
      name: 'Pomoravski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: [
        'Jagodina',
        'Paraćin',
        'Ćuprija',
        'Svilajnac',
        'Despotovac',
        'Rekovac',
      ],
    ),
    SerbianDistrict(
      id: 'raski',
      name: 'Raški okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: ['Kraljevo', 'Novi Pazar', 'Vrnjačka Banja', 'Raška', 'Tutin', 'Kopaonik'],
    ),
    SerbianDistrict(
      id: 'rasinski',
      name: 'Rasinski okrug',
      region: 'Šumadija i Zapadna Srbija',
      cities: ['Kruševac', 'Trstenik', 'Aleksandrovac', 'Brus', 'Varvarin', 'Ćićevac'],
    ),

    // Južna i Istočna Srbija
    SerbianDistrict(
      id: 'nisavski',
      name: 'Nišavski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Niš', 'Aleksinac', 'Svrljig', 'Doljevac', 'Merošina', 'Ražanj', 'Gadžin Han'],
    ),
    SerbianDistrict(
      id: 'podunavski',
      name: 'Podunavski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Smederevo', 'Smederevska Palanka', 'Velika Plana'],
    ),
    SerbianDistrict(
      id: 'branicevski',
      name: 'Braničevski okrug',
      region: 'Južna i Istočna Srbija',
      cities: [
        'Požarevac',
        'Veliko Gradište',
        'Golubac',
        'Petrovac na Mlavi',
        'Kučevo',
        'Žagubica',
        'Kostolac',
      ],
    ),
    SerbianDistrict(
      id: 'borski',
      name: 'Borski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Bor', 'Negotin', 'Kladovo', 'Majdanpek'],
    ),
    SerbianDistrict(
      id: 'zajecarski',
      name: 'Zaječarski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Zaječar', 'Knjaževac', 'Sokobanja', 'Boljevac'],
    ),
    SerbianDistrict(
      id: 'jablanicki',
      name: 'Jablanički okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Leskovac', 'Vlasotince', 'Lebane', 'Bojnik', 'Medveđa', 'Crna Trava'],
    ),
    SerbianDistrict(
      id: 'pcinjski',
      name: 'Pčinjski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Vranje', 'Bujanovac', 'Preševo', 'Surdulica', 'Vladičin Han', 'Trgovište', 'Bosilegrad'],
    ),
    SerbianDistrict(
      id: 'pirotski',
      name: 'Pirotski okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Pirot', 'Bela Palanka', 'Dimitrovgrad', 'Babušnica'],
    ),
    SerbianDistrict(
      id: 'toplicki',
      name: 'Toplički okrug',
      region: 'Južna i Istočna Srbija',
      cities: ['Prokuplje', 'Kuršumlija', 'Blace', 'Žitorađa'],
    ),
  ];

  /// Pronalazi okrug po ID-ju (npr. 'zlatiborski', 'beogradski')
  static SerbianDistrict? findDistrictById(String id) {
    for (final district in all) {
      if (district.id == id) return district;
    }
    return null;
  }

  /// Pronalazi okrug na osnovu unetog grada ili opštine.
  static SerbianDistrict? findDistrictForCity(String city) {
    final clean = city.trim().toLowerCase();
    for (final district in all) {
      for (final c in district.cities) {
        if (c.toLowerCase() == clean) return district;
      }
    }
    return null;
  }
}

