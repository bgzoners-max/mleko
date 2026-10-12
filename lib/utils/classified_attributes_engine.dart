import 'package:flutter/material.dart';
import '../core/lucide_icons.dart';
import '../models/category_attribute_model.dart';
import '../models/classified_category_model.dart';

class ClassifiedAttributesEngine {
  const ClassifiedAttributesEngine._();

  // --- 1. ŠEMA ZA AUTOMOBILE I VOZILA ---
  static const List<CategoryAttribute> carAttributes = [
    CategoryAttribute(
      key: 'year',
      label: 'Godište',
      type: AttributeType.number,
      unit: 'god.',
      min: 1950,
      max: 2026,
      hint: 'npr. 2018',
      icon: Icons.calendar_today_outlined,
    ),
    CategoryAttribute(
      key: 'mileage',
      label: 'Kilometraža',
      type: AttributeType.number,
      unit: 'km',
      min: 0,
      max: 1000000,
      hint: 'npr. 185000',
      icon: Icons.speed_outlined,
    ),
    CategoryAttribute(
      key: 'fuel',
      label: 'Gorivo',
      type: AttributeType.select,
      icon: Icons.local_gas_station_outlined,
      options: [
        CategoryAttributeOption(value: 'dizel', label: 'Dizel'),
        CategoryAttributeOption(value: 'benzin', label: 'Benzin'),
        CategoryAttributeOption(value: 'benzin_gas', label: 'Benzin + Gas (TNG)'),
        CategoryAttributeOption(value: 'hibrid', label: 'Hibridni pogon'),
        CategoryAttributeOption(value: 'elektro', label: 'Električni pogon'),
        CategoryAttributeOption(value: 'metan', label: 'Metan (CNG)'),
      ],
    ),
    CategoryAttribute(
      key: 'transmission',
      label: 'Menjač',
      type: AttributeType.select,
      icon: Icons.settings_outlined,
      options: [
        CategoryAttributeOption(value: 'manuelni', label: 'Manuelni menjač'),
        CategoryAttributeOption(value: 'automatski', label: 'Automatski menjač'),
        CategoryAttributeOption(value: 'poluautomatski', label: 'Poluautomatski'),
      ],
    ),
    CategoryAttribute(
      key: 'body_type',
      label: 'Karoserija',
      type: AttributeType.select,
      icon: Icons.directions_car_outlined,
      options: [
        CategoryAttributeOption(value: 'limuzina', label: 'Limuzina'),
        CategoryAttributeOption(value: 'karavan', label: 'Karavan'),
        CategoryAttributeOption(value: 'hecbek', label: 'Hečbek'),
        CategoryAttributeOption(value: 'dzip_suv', label: 'Džip / SUV'),
        CategoryAttributeOption(value: 'kupe', label: 'Kupe'),
        CategoryAttributeOption(value: 'kabriolet', label: 'Kabriolet'),
        CategoryAttributeOption(value: 'monovolumen', label: 'Monovolumen (MiniVan)'),
        CategoryAttributeOption(value: 'pickup', label: 'Pick-up'),
      ],
    ),
    CategoryAttribute(
      key: 'cubic_capacity',
      label: 'Kubikaža',
      type: AttributeType.number,
      unit: 'cm³',
      min: 500,
      max: 8000,
      hint: 'npr. 1968',
      icon: Icons.tune_outlined,
    ),
    CategoryAttribute(
      key: 'power_hp',
      label: 'Snaga motora',
      type: AttributeType.number,
      unit: 'KS',
      min: 10,
      max: 1500,
      hint: 'npr. 150',
      icon: Icons.flash_on_outlined,
    ),
  ];

  // --- 2. ŠEMA ZA TRAKTORE I POLJOPRIVREDNU MEHANIZACIJU ---
  static const List<CategoryAttribute> tractorAttributes = [
    CategoryAttribute(
      key: 'year',
      label: 'Godište',
      type: AttributeType.number,
      unit: 'god.',
      min: 1950,
      max: 2026,
      hint: 'npr. 1990',
      icon: Icons.calendar_today_outlined,
    ),
    CategoryAttribute(
      key: 'operating_hours',
      label: 'Radni sati',
      type: AttributeType.number,
      unit: 'h',
      min: 0,
      max: 50000,
      hint: 'npr. 3200',
      icon: Icons.timer_outlined,
    ),
    CategoryAttribute(
      key: 'engine_power_hp',
      label: 'Snaga motora',
      type: AttributeType.number,
      unit: 'KS',
      min: 15,
      max: 600,
      hint: 'npr. 39',
      icon: Icons.flash_on_outlined,
    ),
    CategoryAttribute(
      key: 'drive_type',
      label: 'Pogon',
      type: AttributeType.select,
      icon: Icons.agriculture_outlined,
      options: [
        CategoryAttributeOption(value: 'duplak_4x4', label: '4x4 (Dupla vuča)'),
        CategoryAttributeOption(value: 'zadnji_pogon', label: 'Zadnji pogon (2x4)'),
        CategoryAttributeOption(value: 'gusenicari', label: 'Guseničar'),
      ],
    ),
  ];

  // --- 3. ŠEME ZA NEKRETNINE ---

  /// Atributi za stanove i garsonjere
  static const List<CategoryAttribute> realEstateApartmentAttributes = [
    CategoryAttribute(
      key: 'transaction_type',
      label: 'Tip ponude',
      type: AttributeType.select,
      icon: Icons.sell_outlined,
      options: [
        CategoryAttributeOption(value: 'prodaja', label: 'Prodaja'),
        CategoryAttributeOption(value: 'izdavanje', label: 'Izdavanje'),
        CategoryAttributeOption(value: 'na_dan', label: 'Stan na dan'),
      ],
    ),
    CategoryAttribute(
      key: 'area_m2',
      label: 'Kvadratura',
      type: AttributeType.number,
      isDecimal: true,
      unit: 'm²',
      min: 10,
      max: 2000,
      hint: 'npr. 65',
      icon: Icons.square_foot_outlined,
    ),
    CategoryAttribute(
      key: 'rooms',
      label: 'Broj soba',
      type: AttributeType.select,
      icon: Icons.meeting_room_outlined,
      options: [
        CategoryAttributeOption(value: 'garsonjera', label: 'Garsonjera'),
        CategoryAttributeOption(value: '1.0', label: 'Jednosoban (1.0)'),
        CategoryAttributeOption(value: '1.5', label: 'Jednoiposoban (1.5)'),
        CategoryAttributeOption(value: '2.0', label: 'Dvosoban (2.0)'),
        CategoryAttributeOption(value: '2.5', label: 'Dvoiposoban (2.5)'),
        CategoryAttributeOption(value: '3.0', label: 'Trosoban (3.0)'),
        CategoryAttributeOption(value: '3.5', label: 'Troiposoban (3.5)'),
        CategoryAttributeOption(value: '4.0_plus', label: 'Četvorosoban i veći (4.0+)'),
      ],
    ),
    CategoryAttribute(
      key: 'floor',
      label: 'Sprat',
      type: AttributeType.select,
      icon: Icons.stairs_outlined,
      options: [
        CategoryAttributeOption(value: 'suteren', label: 'Suteren / Suterenski'),
        CategoryAttributeOption(value: 'prizemlje', label: 'Prizemlje (PR)'),
        CategoryAttributeOption(value: 'visoko_prizemlje', label: 'Visoko prizemlje (VPR)'),
        CategoryAttributeOption(value: '1', label: '1. sprat'),
        CategoryAttributeOption(value: '2', label: '2. sprat'),
        CategoryAttributeOption(value: '3', label: '3. sprat'),
        CategoryAttributeOption(value: '4', label: '4. sprat'),
        CategoryAttributeOption(value: '5', label: '5. sprat'),
        CategoryAttributeOption(value: '6', label: '6. sprat'),
        CategoryAttributeOption(value: '7_plus', label: '7. sprat i više'),
        CategoryAttributeOption(value: 'potkrovlje', label: 'Potkrovlje / Dupleks'),
      ],
    ),
    CategoryAttribute(
      key: 'heating',
      label: 'Grejanje',
      type: AttributeType.select,
      icon: Icons.whatshot_outlined,
      options: [
        CategoryAttributeOption(value: 'centralno', label: 'Centralno grejanje (CG)'),
        CategoryAttributeOption(value: 'etazno', label: 'Etažno grejanje (EG)'),
        CategoryAttributeOption(value: 'gas', label: 'Gas'),
        CategoryAttributeOption(value: 'klima_inverter', label: 'Klima / Inverter'),
        CategoryAttributeOption(value: 'drva_ugalj', label: 'Čvrsta goriva (drva/ugalj)'),
        CategoryAttributeOption(value: 'struja', label: 'Struja / TA peć'),
        CategoryAttributeOption(value: 'podno', label: 'Podno grejanje'),
      ],
    ),
    CategoryAttribute(
      key: 'elevator',
      label: 'Lift',
      type: AttributeType.boolean,
      icon: Icons.elevator_outlined,
    ),
    CategoryAttribute(
      key: 'terrace',
      label: 'Terasa / Lođa',
      type: AttributeType.boolean,
      icon: Icons.deck_outlined,
    ),
    CategoryAttribute(
      key: 'registered',
      label: 'Uknjiženo 1/1',
      type: AttributeType.boolean,
      icon: Icons.verified_outlined,
    ),
    CategoryAttribute(
      key: 'construction_type',
      label: 'Stanje gradnje',
      type: AttributeType.select,
      icon: Icons.apartment_outlined,
      options: [
        CategoryAttributeOption(value: 'novogradnja', label: 'Novogradnja'),
        CategoryAttributeOption(value: 'starogradnja', label: 'Starogradnja'),
        CategoryAttributeOption(value: 'u_izgradnji', label: 'U izgradnji'),
        CategoryAttributeOption(value: 'renovirano', label: 'Renovirano'),
        CategoryAttributeOption(value: 'izvorno', label: 'Izvorno stanje'),
      ],
    ),
  ];

  /// Atributi za kuće, seoska domaćinstva, vikendice i salaše
  static const List<CategoryAttribute> realEstateHouseAttributes = [
    CategoryAttribute(
      key: 'transaction_type',
      label: 'Tip ponude',
      type: AttributeType.select,
      icon: Icons.sell_outlined,
      options: [
        CategoryAttributeOption(value: 'prodaja', label: 'Prodaja'),
        CategoryAttributeOption(value: 'izdavanje', label: 'Izdavanje'),
        CategoryAttributeOption(value: 'na_dan', label: 'Izdavanje na dan / Seoski turizam'),
      ],
    ),
    CategoryAttribute(
      key: 'area_m2',
      label: 'Kvadratura objekta',
      type: AttributeType.number,
      isDecimal: true,
      unit: 'm²',
      min: 15,
      max: 5000,
      hint: 'npr. 120',
      icon: Icons.home_outlined,
    ),
    CategoryAttribute(
      key: 'land_area_ari',
      label: 'Površina placa / okućnice',
      type: AttributeType.number,
      isDecimal: true,
      unit: 'ar',
      min: 1,
      max: 5000,
      hint: 'npr. 15',
      icon: Icons.landscape_outlined,
    ),
    CategoryAttribute(
      key: 'water_supply',
      label: 'Vodosnabdevanje',
      type: AttributeType.select,
      icon: Icons.water_drop_outlined,
      options: [
        CategoryAttributeOption(value: 'gradski', label: 'Gradski vodovod'),
        CategoryAttributeOption(value: 'bunar', label: 'Bunar sa hidroforom'),
        CategoryAttributeOption(value: 'izvorska', label: 'Izvorska voda / Prirodni pad'),
        CategoryAttributeOption(value: 'cisterna', label: 'Cisterna / Bazen'),
      ],
    ),
    CategoryAttribute(
      key: 'electricity',
      label: 'Struja',
      type: AttributeType.select,
      icon: Icons.bolt_outlined,
      options: [
        CategoryAttributeOption(value: 'trofazna', label: 'Trofazna struja'),
        CategoryAttributeOption(value: 'monofazna', label: 'Monofazna struja'),
        CategoryAttributeOption(value: 'solarni', label: 'Solarni sistem / Off-grid'),
      ],
    ),
    CategoryAttribute(
      key: 'road_access',
      label: 'Prilazni put',
      type: AttributeType.select,
      icon: Icons.add_road_outlined,
      options: [
        CategoryAttributeOption(value: 'asfalt', label: 'Asfalt do kuće/imanja'),
        CategoryAttributeOption(value: 'makadam', label: 'Makadam / Tucanik'),
        CategoryAttributeOption(value: 'zemljani', label: 'Zemljani put'),
      ],
    ),
    CategoryAttribute(
      key: 'heating',
      label: 'Grejanje',
      type: AttributeType.select,
      icon: Icons.whatshot_outlined,
      options: [
        CategoryAttributeOption(value: 'drva_ugalj', label: 'Čvrsta goriva (drva/ugalj)'),
        CategoryAttributeOption(value: 'etazno', label: 'Etažno grejanje / Kotao'),
        CategoryAttributeOption(value: 'gas', label: 'Gas'),
        CategoryAttributeOption(value: 'klima_inverter', label: 'Klima / Inverter'),
        CategoryAttributeOption(value: 'struja', label: 'Struja / TA peć'),
        CategoryAttributeOption(value: 'podno', label: 'Podno grejanje'),
      ],
    ),
    CategoryAttribute(
      key: 'homestead_ready',
      label: 'Pogodno za poljoprivredno gazdinstvo',
      type: AttributeType.boolean,
      icon: Icons.cottage_outlined,
    ),
    CategoryAttribute(
      key: 'registered',
      label: 'Uknjiženo',
      type: AttributeType.boolean,
      icon: Icons.verified_outlined,
    ),
  ];

  /// Atributi za zemljište, njive, voćnjake i placeve
  static const List<CategoryAttribute> realEstateLandAttributes = [
    CategoryAttribute(
      key: 'land_area_ari',
      label: 'Površina zemljišta',
      type: AttributeType.number,
      isDecimal: true,
      unit: 'ar',
      min: 1,
      max: 50000,
      hint: 'npr. 50 (pola hektara)',
      icon: Icons.crop_landscape_outlined,
    ),
    CategoryAttribute(
      key: 'land_type',
      label: 'Namena zemljišta',
      type: AttributeType.select,
      icon: Icons.terrain_outlined,
      options: [
        CategoryAttributeOption(value: 'njiva', label: 'Obradivo zemljište / Njiva'),
        CategoryAttributeOption(value: 'vocnjak', label: 'Voćnjak'),
        CategoryAttributeOption(value: 'vinograd', label: 'Vinograd'),
        CategoryAttributeOption(value: 'suma', label: 'Šuma'),
        CategoryAttributeOption(value: 'pasnjak', label: 'Pašnjak / Livada'),
        CategoryAttributeOption(value: 'gradjevinski_plac', label: 'Građevinski plac'),
        CategoryAttributeOption(value: 'industrijsko', label: 'Industrijsko / Komercijalno'),
      ],
    ),
    CategoryAttribute(
      key: 'water_access',
      label: 'Voda / Priključak vode',
      type: AttributeType.boolean,
      icon: Icons.water_drop_outlined,
    ),
    CategoryAttribute(
      key: 'electricity_access',
      label: 'Struja / Priključak struje',
      type: AttributeType.boolean,
      icon: Icons.bolt_outlined,
    ),
    CategoryAttribute(
      key: 'irrigation',
      label: 'Navodnjavanje',
      type: AttributeType.boolean,
      icon: Icons.water_outlined,
    ),
    CategoryAttribute(
      key: 'road_access',
      label: 'Prilazni put',
      type: AttributeType.select,
      icon: Icons.add_road_outlined,
      options: [
        CategoryAttributeOption(value: 'asfalt', label: 'Asfaltni put'),
        CategoryAttributeOption(value: 'makadam', label: 'Makadam / Nasut put'),
        CategoryAttributeOption(value: 'poljski', label: 'Poljski / Zemljani put'),
      ],
    ),
    CategoryAttribute(
      key: 'registered',
      label: 'Uknjiženo 1/1',
      type: AttributeType.boolean,
      icon: Icons.verified_outlined,
    ),
  ];

  /// Kompatibilnost: opšta šema za nekretnine
  static List<CategoryAttribute> get realEstateAttributes => realEstateApartmentAttributes;

  // --- 4. ŠEMA ZA TELEFONE ---
  static const List<CategoryAttribute> phoneAttributes = [
    CategoryAttribute(
      key: 'storage_gb',
      label: 'Interna memorija',
      type: AttributeType.select,
      icon: LucideIcons.hardDrive,
      options: [
        CategoryAttributeOption(value: '32', label: '32 GB'),
        CategoryAttributeOption(value: '64', label: '64 GB'),
        CategoryAttributeOption(value: '128', label: '128 GB'),
        CategoryAttributeOption(value: '256', label: '256 GB'),
        CategoryAttributeOption(value: '512', label: '512 GB'),
        CategoryAttributeOption(value: '1024', label: '1 TB'),
      ],
    ),
    CategoryAttribute(
      key: 'ram_gb',
      label: 'RAM memorija',
      type: AttributeType.select,
      icon: LucideIcons.cpu,
      options: [
        CategoryAttributeOption(value: '3', label: '3 GB'),
        CategoryAttributeOption(value: '4', label: '4 GB'),
        CategoryAttributeOption(value: '6', label: '6 GB'),
        CategoryAttributeOption(value: '8', label: '8 GB'),
        CategoryAttributeOption(value: '12', label: '12 GB'),
        CategoryAttributeOption(value: '16', label: '16 GB'),
      ],
    ),
    CategoryAttribute(
      key: 'battery_capacity_mah',
      label: 'Kapacitet baterije',
      type: AttributeType.number,
      unit: 'mAh',
      min: 500,
      max: 25000,
      hint: 'npr. 5000',
      icon: LucideIcons.batteryCharging,
    ),
    CategoryAttribute(
      key: 'sim_free',
      label: 'SIM Free',
      type: AttributeType.boolean,
      icon: LucideIcons.unlock,
    ),
    CategoryAttribute(
      key: 'sim_single',
      label: '1x SIM slot',
      type: AttributeType.boolean,
      icon: LucideIcons.smartphone,
    ),
    CategoryAttribute(
      key: 'sim_dual',
      label: '2x SIM slota',
      type: AttributeType.boolean,
      icon: LucideIcons.layers,
    ),
    CategoryAttribute(
      key: 'sim_esim',
      label: 'eSIM podrška',
      type: AttributeType.boolean,
      icon: LucideIcons.nfc,
    ),
    CategoryAttribute(
      key: 'net_5g',
      label: '5G',
      type: AttributeType.boolean,
      icon: LucideIcons.signal,
    ),
    CategoryAttribute(
      key: 'warranty_official',
      label: 'Zvanična garancija',
      type: AttributeType.boolean,
      icon: LucideIcons.badgeCheck,
    ),
    CategoryAttribute(
      key: 'warranty_operator',
      label: 'Garancija operatera',
      type: AttributeType.boolean,
      icon: LucideIcons.radioTower,
    ),
    CategoryAttribute(
      key: 'warranty_shop',
      label: 'Garancija radnje / servisa',
      type: AttributeType.boolean,
      icon: LucideIcons.store,
    ),
    CategoryAttribute(
      key: 'warranty_working',
      label: 'Radna garancija',
      type: AttributeType.boolean,
      icon: LucideIcons.wrench,
    ),
    CategoryAttribute(
      key: 'acc_box',
      label: 'Originalna kutija',
      type: AttributeType.boolean,
      icon: LucideIcons.package,
    ),
    CategoryAttribute(
      key: 'acc_charger',
      label: 'Punjač',
      type: AttributeType.boolean,
      icon: LucideIcons.plug,
    ),
    CategoryAttribute(
      key: 'acc_cable',
      label: 'USB kabl',
      type: AttributeType.boolean,
      icon: LucideIcons.usb,
    ),
    CategoryAttribute(
      key: 'acc_case',
      label: 'Zaštitna maska',
      type: AttributeType.boolean,
      icon: LucideIcons.shield,
    ),
    CategoryAttribute(
      key: 'acc_glass',
      label: 'Zaštitno staklo',
      type: AttributeType.boolean,
      icon: LucideIcons.sparkles,
    ),
    CategoryAttribute(
      key: 'acc_headphones',
      label: 'Slušalice',
      type: AttributeType.boolean,
      icon: LucideIcons.headphones,
    ),
    CategoryAttribute(
      key: 'acc_receipt',
      label: 'Fiskalni račun',
      type: AttributeType.boolean,
      icon: LucideIcons.receipt,
    ),
  ];

  /// Vraća listu definisanih atributa za datu kategoriju (ili njene roditelje).
  static List<CategoryAttribute> getAttributesForCategory(
    String? categoryId, {
    List<ClassifiedCategoryModel>? breadcrumbs,
  }) {
    if (categoryId == null || categoryId.isEmpty) return const [];

    final id = categoryId.toLowerCase();
    final crumbIds = breadcrumbs?.map((c) => c.id.toLowerCase()).toSet() ?? {};

    bool matches(String target) => id.contains(target) || crumbIds.any((c) => c.contains(target));

    // Automobili / Vozila
    if (matches('auto') || matches('vozila') || id.startsWith('auto_')) {
      // Ignoriši delove i opremu
      if (!matches('delovi') && !matches('oprema') && !matches('gume')) {
        return carAttributes;
      }
    }

    // Traktori / Kombajni
    if (matches('traktor') || matches('kombajn') || id.startsWith('traktori_')) {
      if (!matches('delovi') && !matches('prikljuc')) {
        return tractorAttributes;
      }
    }

    // Nekretnine
    if (matches('stan') || matches('garsonjer')) {
      return realEstateApartmentAttributes;
    }
    if (matches('kuc') || matches('domacinstv') || matches('vikendic') || matches('salas') || matches('montazne')) {
      return realEstateHouseAttributes;
    }
    if (matches('zemlj') || matches('plac') || matches('njiv') || matches('oranic') || matches('vocn') || matches('sum') || matches('livad') || matches('pasnjak')) {
      return realEstateLandAttributes;
    }
    if (matches('nekretnine') || matches('poslovni') || matches('lokal') || matches('kancelarij') || matches('magacin') || matches('garaz')) {
      return realEstateApartmentAttributes;
    }

    // Telefoni / Smartfoni
    final isPhone = matches('telefoni') ||
        matches('smartfon') ||
        matches('pametni_telefoni') ||
        ClassifiedCategoryModel.isPhoneBrand(id);
    if (isPhone) {
      if (!matches('maske') &&
          !matches('punjac') &&
          !matches('delovi') &&
          !matches('satovi')) {
        return phoneAttributes;
      }
    }

    return const [];
  }

  static const List<CategoryAttribute> _legacyPhoneAttributes = [
    CategoryAttribute(
      key: 'warranty',
      label: 'Garancija',
      type: AttributeType.select,
      icon: LucideIcons.badgeCheck,
      options: [
        CategoryAttributeOption(value: 'zvanicna', label: 'Zvanična garancija'),
        CategoryAttributeOption(value: 'operater', label: 'Garancija operatera'),
        CategoryAttributeOption(value: 'servis_radnja', label: 'Garancija radnje / servisa'),
        CategoryAttributeOption(value: 'nema', label: 'Nema garanciju'),
      ],
    ),
    CategoryAttribute(
      key: 'sim_lock',
      label: 'SIM status',
      type: AttributeType.select,
      icon: LucideIcons.unlock,
      options: [
        CategoryAttributeOption(value: 'sim_free', label: 'SIM Free'),
        CategoryAttributeOption(value: 'zakljucan', label: 'Zaključan na mrežu'),
      ],
    ),
    CategoryAttribute(
      key: 'sim_slots',
      label: 'SIM slotovi',
      type: AttributeType.select,
      icon: LucideIcons.smartphone,
      options: [
        CategoryAttributeOption(value: 'single_sim', label: 'Single SIM'),
        CategoryAttributeOption(value: 'dual_sim', label: 'Dual SIM'),
        CategoryAttributeOption(value: 'sim_esim', label: 'SIM + eSIM'),
        CategoryAttributeOption(value: 'dual_esim', label: 'Dual eSIM'),
      ],
    ),
    CategoryAttribute(
      key: 'package_contents',
      label: 'Prateća oprema',
      type: AttributeType.select,
      icon: LucideIcons.package,
      options: [
        CategoryAttributeOption(value: 'full', label: 'Full pakovanje'),
        CategoryAttributeOption(value: 'telefon_punjac', label: 'Telefon i punjač / kabl'),
        CategoryAttributeOption(value: 'samo_telefon', label: 'Samo telefon'),
      ],
    ),
  ];

  /// Pronalazi atribut po ključu u svim definisanim šemama
  static CategoryAttribute? findAttributeByKey(String key) {
    final allLists = [
      carAttributes,
      tractorAttributes,
      realEstateApartmentAttributes,
      realEstateHouseAttributes,
      realEstateLandAttributes,
      phoneAttributes,
      _legacyPhoneAttributes,
    ];
    for (final list in allLists) {
      for (final a in list) {
        if (a.key == key) return a;
      }
    }
    return null;
  }
}
