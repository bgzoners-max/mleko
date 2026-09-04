import 'package:flutter/material.dart';

class ClassifiedCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String? parentId;
  final int sortOrder;
  final List<ClassifiedCategoryModel> subcategories;

  const ClassifiedCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.parentId,
    this.sortOrder = 0,
    this.subcategories = const [],
  });

  bool get isRoot => parentId == null;

  factory ClassifiedCategoryModel.fromJson(
    Map<String, dynamic> json, {
    List<ClassifiedCategoryModel> subcategories = const [],
  }) {
    return ClassifiedCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String? ?? 'category',
      parentId: json['parent_id'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      subcategories: subcategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'parent_id': parentId,
      'sort_order': sortOrder,
    };
  }

  ClassifiedCategoryModel copyWith({
    List<ClassifiedCategoryModel>? subcategories,
  }) {
    return ClassifiedCategoryModel(
      id: id,
      name: name,
      iconName: iconName,
      parentId: parentId,
      sortOrder: sortOrder,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  IconData get iconData {
    switch (iconName) {
      case 'agriculture':
        return Icons.agriculture;
      case 'air':
        return Icons.air;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'anchor':
        return Icons.anchor;
      case 'apartment':
        return Icons.apartment;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'backpack':
        return Icons.backpack;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'battery_full':
        return Icons.battery_full;
      case 'bed':
        return Icons.bed;
      case 'blender':
        return Icons.blender;
      case 'blinds':
        return Icons.blinds;
      case 'build':
        return Icons.build;
      case 'business':
        return Icons.business;
      case 'cabin':
        return Icons.cabin;
      case 'cable':
        return Icons.cable;
      case 'car_repair':
        return Icons.car_repair;
      case 'carpenter':
        return Icons.carpenter;
      case 'chair':
        return Icons.chair;
      case 'checkroom':
        return Icons.checkroom;
      case 'child_care':
        return Icons.child_care;
      case 'child_friendly':
        return Icons.child_friendly;
      case 'clean_hands':
        return Icons.clean_hands;
      case 'computer':
        return Icons.computer;
      case 'connected_tv':
        return Icons.connected_tv;
      case 'construction':
        return Icons.construction;
      case 'countertops':
        return Icons.countertops;
      case 'cruelty_free':
        return Icons.cruelty_free;
      case 'curtains':
        return Icons.curtains;
      case 'cyclone':
        return Icons.cyclone;
      case 'deck':
        return Icons.deck;
      case 'delete':
        return Icons.delete;
      case 'developer_board':
        return Icons.developer_board;
      case 'diamond':
        return Icons.diamond;
      case 'dialpad':
        return Icons.dialpad;
      case 'directions_car':
        return Icons.directions_car;
      case 'dishwasher':
        return Icons.kitchen;
      case 'door_front':
        return Icons.door_front_door;
      case 'door_sliding':
        return Icons.door_sliding;
      case 'egg':
        return Icons.egg;
      case 'electric_bike':
        return Icons.electric_bike;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'factory':
        return Icons.factory;
      case 'faucet':
        return Icons.water_drop;
      case 'fence':
        return Icons.fence;
      case 'fireplace':
        return Icons.fireplace;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'forest':
        return Icons.forest;
      case 'format_paint':
        return Icons.format_paint;
      case 'foundation':
        return Icons.foundation;
      case 'garage':
        return Icons.garage;
      case 'grain':
        return Icons.grain;
      case 'grass':
        return Icons.grass;
      case 'grid_view':
        return Icons.grid_view;
      case 'handyman':
        return Icons.handyman;
      case 'hardware':
        return Icons.hardware;
      case 'headphones':
        return Icons.headphones;
      case 'headset':
        return Icons.headset;
      case 'healing':
        return Icons.healing;
      case 'heat_pump':
        return Icons.heat_pump;
      case 'highlight':
        return Icons.highlight;
      case 'hiking':
        return Icons.hiking;
      case 'hive':
        return Icons.hive;
      case 'holiday_village':
        return Icons.holiday_village;
      case 'home':
        return Icons.home;
      case 'home_work':
        return Icons.home_work;
      case 'hotel':
        return Icons.hotel;
      case 'house':
        return Icons.house;
      case 'hvac':
        return Icons.hvac;
      case 'image':
        return Icons.image;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'keyboard':
        return Icons.keyboard;
      case 'kitchen':
        return Icons.kitchen;
      case 'landscape':
        return Icons.landscape;
      case 'laptop':
        return Icons.laptop;
      case 'laptop_chromebook':
        return Icons.laptop_chromebook;
      case 'laptop_mac':
        return Icons.laptop_mac;
      case 'layers':
        return Icons.layers;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'link':
        return Icons.link;
      case 'liquor':
        return Icons.liquor;
      case 'local_dining':
        return Icons.local_dining;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'lock':
        return Icons.lock;
      case 'luggage':
        return Icons.luggage;
      case 'meeting_room':
        return Icons.meeting_room;
      case 'memory':
        return Icons.memory;
      case 'menu_book':
        return Icons.menu_book;
      case 'mic':
        return Icons.mic;
      case 'microwave':
      case 'oven_gen':
        return Icons.microwave;
      case 'mode_fan':
        return Icons.air;
      case 'monitor':
      case 'desktop_windows':
        return Icons.monitor;
      case 'music_note':
        return Icons.music_note;
      case 'outdoor_grill':
        return Icons.outdoor_grill;
      case 'outlet':
        return Icons.outlet;
      case 'paid':
        return Icons.paid;
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'pets':
        return Icons.pets;
      case 'phishing':
        return Icons.phishing;
      case 'piano':
        return Icons.piano;
      case 'plumbing':
        return Icons.plumbing;
      case 'pool':
        return Icons.pool;
      case 'power':
        return Icons.power;
      case 'precision_manufacturing':
        return Icons.precision_manufacturing;
      case 'print':
        return Icons.print;
      case 'propane_tank':
        return Icons.propane_tank;
      case 'radiator':
        return Icons.hvac;
      case 'reorder':
        return Icons.reorder;
      case 'roofing':
        return Icons.roofing;
      case 'router':
        return Icons.router;
      case 'rv_hookup':
        return Icons.rv_hookup;
      case 'safety_divider':
        return Icons.safety_divider;
      case 'sailing':
        return Icons.sailing;
      case 'sanitizer':
        return Icons.sanitizer;
      case 'scatter_plot':
        return Icons.scatter_plot;
      case 'school':
        return Icons.school;
      case 'screen_lock_portrait':
        return Icons.screen_lock_portrait;
      case 'screenshot':
        return Icons.screenshot;
      case 'sensor_window':
        return Icons.sensor_window;
      case 'settings':
        return Icons.settings;
      case 'shelves':
        return Icons.shelves;
      case 'shield':
        return Icons.shield;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'shower':
        return Icons.shower;
      case 'smart_toy':
        return Icons.smart_toy;
      case 'smartphone':
        return Icons.smartphone;
      case 'solar_power':
        return Icons.solar_power;
      case 'soup_kitchen':
        return Icons.soup_kitchen;
      case 'spa':
        return Icons.spa;
      case 'speaker':
        return Icons.speaker;
      case 'sports_esports':
      case 'videogame_asset':
        return Icons.sports_esports;
      case 'sports_mma':
        return Icons.sports_mma;
      case 'sports_motorsports':
        return Icons.sports_motorsports;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'square':
        return Icons.square;
      case 'storage':
        return Icons.storage;
      case 'storefront':
        return Icons.storefront;
      case 'straighten':
        return Icons.straighten;
      case 'support_agent':
        return Icons.support_agent;
      case 'table_restaurant':
        return Icons.table_restaurant;
      case 'tablet':
        return Icons.tablet;
      case 'terrain':
        return Icons.terrain;
      case 'texture':
        return Icons.texture;
      case 'tire_repair':
        return Icons.tire_repair;
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
      case 'tv':
      case 'tv_gen':
        return Icons.tv;
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'vertical_align_top':
        return Icons.vertical_align_top;
      case 'videocam':
        return Icons.videocam;
      case 'view_agenda':
        return Icons.view_agenda;
      case 'view_module':
        return Icons.view_module;
      case 'view_quilt':
        return Icons.view_quilt;
      case 'visibility':
        return Icons.visibility;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'warehouse':
        return Icons.warehouse;
      case 'watch':
        return Icons.watch;
      case 'water':
      case 'water_drop':
        return Icons.water_drop;
      case 'water_damage':
        return Icons.water_damage;
      case 'water_heater':
        return Icons.water_drop;
      case 'wb_shade':
        return Icons.wb_shade;
      case 'wine_bar':
        return Icons.wine_bar;
      case 'work':
        return Icons.work;
      case 'yard':
        return Icons.yard;
      default:
        return Icons.category;
    }
  }

  static int compareSerbian(String a, String b) {
    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll('č', 'c~1')
          .replaceAll('ć', 'c~2')
          .replaceAll('dž', 'd~1')
          .replaceAll('đ', 'd~2')
          .replaceAll('lj', 'l~1')
          .replaceAll('nj', 'n~1')
          .replaceAll('š', 's~1')
          .replaceAll('ž', 'z~1');
    }

    return normalize(a).compareTo(normalize(b));
  }

  static const List<ClassifiedCategoryModel> fallbackCategories = [
    ClassifiedCategoryModel(
      id: 'dom_basta',
      name: 'Dom i bašta',
      iconName: 'chair',
      sortOrder: 10,
      subcategories: [
        ClassifiedCategoryModel(id: 'namestaj', name: 'Nameštaj za dnevnu i spavaću sobu', iconName: 'chair', parentId: 'dom_basta', sortOrder: 10),
        ClassifiedCategoryModel(id: 'kuhinje_trpezarije', name: 'Kuhinje i trpezarije', iconName: 'table_restaurant', parentId: 'dom_basta', sortOrder: 20),
        ClassifiedCategoryModel(id: 'bela_tehnika', name: 'Bela tehnika i kućni aparati', iconName: 'kitchen', parentId: 'dom_basta', sortOrder: 30),
        ClassifiedCategoryModel(id: 'basta_dvoriste', name: 'Dvorište, bašta i terase', iconName: 'yard', parentId: 'dom_basta', sortOrder: 40),
        ClassifiedCategoryModel(id: 'grejanje_klima', name: 'Grejanje, peći i klimatizacija', iconName: 'fireplace', parentId: 'dom_basta', sortOrder: 50),
        ClassifiedCategoryModel(id: 'rasveta_dekoracija', name: 'Rasveta, tepisi i dekoracija', iconName: 'lightbulb', parentId: 'dom_basta', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'gradjevinarstvo',
      name: 'Građevinarstvo',
      iconName: 'foundation',
      sortOrder: 20,
      subcategories: [
        ClassifiedCategoryModel(id: 'gradjevinski_materijal', name: 'Građevinski materijali', iconName: 'foundation', parentId: 'gradjevinarstvo', sortOrder: 10),
        ClassifiedCategoryModel(id: 'krovni_pokrivaci', name: 'Krovni pokrivači i limarija', iconName: 'roofing', parentId: 'gradjevinarstvo', sortOrder: 20),
        ClassifiedCategoryModel(id: 'stolarija', name: 'Stolarija (PVC, ALU, drvo)', iconName: 'door_front', parentId: 'gradjevinarstvo', sortOrder: 30),
        ClassifiedCategoryModel(id: 'izolacija_fasade', name: 'Izolacija i fasade', iconName: 'layers', parentId: 'gradjevinarstvo', sortOrder: 40),
        ClassifiedCategoryModel(id: 'vodovod_sanitarije', name: 'Vodovod, kanalizacija i sanitarije', iconName: 'plumbing', parentId: 'gradjevinarstvo', sortOrder: 50),
        ClassifiedCategoryModel(id: 'elektroinstalacije', name: 'Elektroinstalacije', iconName: 'electrical_services', parentId: 'gradjevinarstvo', sortOrder: 60),
        ClassifiedCategoryModel(id: 'montazni_objekti', name: 'Montažni objekti, ograde i kapije', iconName: 'fence', parentId: 'gradjevinarstvo', sortOrder: 70),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'ljubimci',
      name: 'Ljubimci',
      iconName: 'pets',
      sortOrder: 30,
      subcategories: [
        ClassifiedCategoryModel(id: 'psi', name: 'Psi i štenci', iconName: 'pets', parentId: 'ljubimci', sortOrder: 10),
        ClassifiedCategoryModel(id: 'macke', name: 'Mačke i mačići', iconName: 'pets', parentId: 'ljubimci', sortOrder: 20),
        ClassifiedCategoryModel(id: 'domace_zivotinje', name: 'Domaće životinje i stoka', iconName: 'pets', parentId: 'ljubimci', sortOrder: 30),
        ClassifiedCategoryModel(id: 'zivina_ptice', name: 'Živina i ptice', iconName: 'egg', parentId: 'ljubimci', sortOrder: 40),
        ClassifiedCategoryModel(id: 'pcelarstvo', name: 'Pčelarstvo', iconName: 'hive', parentId: 'ljubimci', sortOrder: 50),
        ClassifiedCategoryModel(id: 'oprema_za_zivotinje', name: 'Hrana i oprema za životinje', iconName: 'shopping_bag', parentId: 'ljubimci', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'masine_alati',
      name: 'Mašine i alati',
      iconName: 'handyman',
      sortOrder: 40,
      subcategories: [
        ClassifiedCategoryModel(id: 'elektro_aku_alati', name: 'Električni i aku alati', iconName: 'handyman', parentId: 'masine_alati', sortOrder: 10),
        ClassifiedCategoryModel(id: 'rucni_alati', name: 'Ručni alati i setovi', iconName: 'build', parentId: 'masine_alati', sortOrder: 20),
        ClassifiedCategoryModel(id: 'radionicke_masine', name: 'Radioničke mašine i strugovi', iconName: 'precision_manufacturing', parentId: 'masine_alati', sortOrder: 30),
        ClassifiedCategoryModel(id: 'zavarivanje', name: 'Aparati za varenje i lemljenje', iconName: 'hardware', parentId: 'masine_alati', sortOrder: 40),
        ClassifiedCategoryModel(id: 'kompresori_pneumatika', name: 'Kompresori i pneumatski alati', iconName: 'air', parentId: 'masine_alati', sortOrder: 50),
        ClassifiedCategoryModel(id: 'zastitna_oprema', name: 'Zaštitna i radna oprema', iconName: 'shield', parentId: 'masine_alati', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'nekretnine',
      name: 'Nekretnine',
      iconName: 'home_work',
      sortOrder: 50,
      subcategories: [
        ClassifiedCategoryModel(id: 'stanovi', name: 'Stanovi', iconName: 'apartment', parentId: 'nekretnine', sortOrder: 10),
        ClassifiedCategoryModel(id: 'kuce_domacinstva', name: 'Kuće i seoska domaćinstva', iconName: 'house', parentId: 'nekretnine', sortOrder: 20),
        ClassifiedCategoryModel(id: 'vikendice', name: 'Vikendice i brvnare', iconName: 'cabin', parentId: 'nekretnine', sortOrder: 30),
        ClassifiedCategoryModel(id: 'poljoprivredno_zemljiste', name: 'Poljoprivredno zemljište', iconName: 'terrain', parentId: 'nekretnine', sortOrder: 40),
        ClassifiedCategoryModel(id: 'gradjevinski_placevi', name: 'Građevinski placevi', iconName: 'landscape', parentId: 'nekretnine', sortOrder: 50),
        ClassifiedCategoryModel(id: 'poslovni_prostori', name: 'Poslovni prostori, hale i lokali', iconName: 'storefront', parentId: 'nekretnine', sortOrder: 60),
        ClassifiedCategoryModel(id: 'garaze_parking', name: 'Garaže i parking mesta', iconName: 'garage', parentId: 'nekretnine', sortOrder: 70),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'odeca_obuca',
      name: 'Odeća i obuća',
      iconName: 'checkroom',
      sortOrder: 60,
      subcategories: [
        ClassifiedCategoryModel(id: 'muska_odeca', name: 'Muška odeća', iconName: 'checkroom', parentId: 'odeca_obuca', sortOrder: 10),
        ClassifiedCategoryModel(id: 'zenska_odeca', name: 'Ženska odeća', iconName: 'checkroom', parentId: 'odeca_obuca', sortOrder: 20),
        ClassifiedCategoryModel(id: 'obuca', name: 'Muška i ženska obuća', iconName: 'hiking', parentId: 'odeca_obuca', sortOrder: 30),
        ClassifiedCategoryModel(id: 'decija_garderoba', name: 'Dečija odeća i obuća', iconName: 'child_care', parentId: 'odeca_obuca', sortOrder: 40),
        ClassifiedCategoryModel(id: 'torbe_rancevi', name: 'Torbe, rančevi i novčanici', iconName: 'backpack', parentId: 'odeca_obuca', sortOrder: 50),
        ClassifiedCategoryModel(id: 'nakit_satovi', name: 'Nakit, ručni satovi i naočare', iconName: 'diamond', parentId: 'odeca_obuca', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'poljoprivreda',
      name: 'Poljoprivreda',
      iconName: 'agriculture',
      sortOrder: 70,
      subcategories: [
        ClassifiedCategoryModel(id: 'traktori_kombajni', name: 'Traktori i kombajni', iconName: 'agriculture', parentId: 'poljoprivreda', sortOrder: 10),
        ClassifiedCategoryModel(id: 'prikljucne_masine', name: 'Priključne mašine', iconName: 'handyman', parentId: 'poljoprivreda', sortOrder: 20),
        ClassifiedCategoryModel(id: 'delovi_za_traktore', name: 'Rezervni delovi za traktore i mehanizaciju', iconName: 'settings', parentId: 'poljoprivreda', sortOrder: 30),
        ClassifiedCategoryModel(id: 'stocna_hrana', name: 'Stočna hrana, seno i žitarice', iconName: 'grass', parentId: 'poljoprivreda', sortOrder: 40),
        ClassifiedCategoryModel(id: 'sadnice_semena', name: 'Sadnice, semena i rasad', iconName: 'yard', parentId: 'poljoprivreda', sortOrder: 50),
        ClassifiedCategoryModel(id: 'navodnjavanje_plastenici', name: 'Navodnjavanje i plastenici', iconName: 'water_drop', parentId: 'poljoprivreda', sortOrder: 60),
        ClassifiedCategoryModel(id: 'prerada_voca_oprema', name: 'Oprema za preradu voća i pića', iconName: 'liquor', parentId: 'poljoprivreda', sortOrder: 70),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'sport_hobi',
      name: 'Sport i hobi',
      iconName: 'sports_soccer',
      sortOrder: 80,
      subcategories: [
        ClassifiedCategoryModel(id: 'lov_oprema', name: 'Lov i lovačka oprema', iconName: 'forest', parentId: 'sport_hobi', sortOrder: 10),
        ClassifiedCategoryModel(id: 'ribolov_pecanje', name: 'Ribolov i pecanje', iconName: 'phishing', parentId: 'sport_hobi', sortOrder: 20),
        ClassifiedCategoryModel(id: 'bicikli_oprema', name: 'Bicikli i oprema za bicikle', iconName: 'pedal_bike', parentId: 'sport_hobi', sortOrder: 30),
        ClassifiedCategoryModel(id: 'fitnes_treninzi', name: 'Fitnes i sprave za vežbanje', iconName: 'fitness_center', parentId: 'sport_hobi', sortOrder: 40),
        ClassifiedCategoryModel(id: 'muzicki_instrumenti', name: 'Muzički instrumenti', iconName: 'music_note', parentId: 'sport_hobi', sortOrder: 50),
        ClassifiedCategoryModel(id: 'kolekcionarstvo', name: 'Kolekcionarstvo i antikviteti', iconName: 'auto_awesome', parentId: 'sport_hobi', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'tehnika',
      name: 'Tehnika',
      iconName: 'laptop',
      sortOrder: 90,
      subcategories: [
        ClassifiedCategoryModel(id: 'laptopovi', name: 'Laptopovi i prenosni računari', iconName: 'laptop', parentId: 'tehnika', sortOrder: 10),
        ClassifiedCategoryModel(id: 'desktop_komponente', name: 'Desktop računari i komponente', iconName: 'computer', parentId: 'tehnika', sortOrder: 20),
        ClassifiedCategoryModel(id: 'monitori_periferije', name: 'Monitori, tastature i miševi', iconName: 'monitor', parentId: 'tehnika', sortOrder: 30),
        ClassifiedCategoryModel(id: 'televizori_video', name: 'Televizori i video oprema', iconName: 'tv', parentId: 'tehnika', sortOrder: 40),
        ClassifiedCategoryModel(id: 'konzole_igrice', name: 'Konzole i igrice', iconName: 'sports_esports', parentId: 'tehnika', sortOrder: 50),
        ClassifiedCategoryModel(id: 'video_nadzor_mreze', name: 'Video nadzor i mrežna oprema', iconName: 'videocam', parentId: 'tehnika', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'telefoni',
      name: 'Telefoni',
      iconName: 'smartphone',
      sortOrder: 100,
      subcategories: [
        ClassifiedCategoryModel(
          id: 'smartfoni',
          name: 'Pametni telefoni (Smartphones)',
          iconName: 'smartphone',
          parentId: 'telefoni',
          sortOrder: 10,
          subcategories: [
            ClassifiedCategoryModel(id: 'apple', name: 'Apple', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 10),
            ClassifiedCategoryModel(id: 'samsung', name: 'Samsung', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 20),
            ClassifiedCategoryModel(id: 'xiaomi', name: 'Xiaomi', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 30),
            ClassifiedCategoryModel(id: 'redmi', name: 'Redmi', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 40),
            ClassifiedCategoryModel(id: 'poco', name: 'POCO', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 50),
            ClassifiedCategoryModel(id: 'honor', name: 'Honor', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 60),
            ClassifiedCategoryModel(id: 'motorola', name: 'Motorola', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 70),
            ClassifiedCategoryModel(id: 'realme', name: 'Realme', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 80),
            ClassifiedCategoryModel(id: 'vivo', name: 'Vivo', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 90),
            ClassifiedCategoryModel(id: 'infinix', name: 'Infinix', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 100),
            ClassifiedCategoryModel(id: 'tecno', name: 'Tecno', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 110),
            ClassifiedCategoryModel(id: 'google', name: 'Google', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 120),
            ClassifiedCategoryModel(id: 'nothing', name: 'Nothing', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 130),
            ClassifiedCategoryModel(id: 'cmf_nothing', name: 'CMF by Nothing', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 140),
            ClassifiedCategoryModel(id: 'huawei', name: 'Huawei', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 150),
            ClassifiedCategoryModel(id: 'asus', name: 'Asus', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 160),
            ClassifiedCategoryModel(id: 'asus_rog', name: 'ROG', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 170),
            ClassifiedCategoryModel(id: 'asus_zenfone', name: 'Zenfone', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 180),
            ClassifiedCategoryModel(id: 'sony', name: 'Sony', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 190),
            ClassifiedCategoryModel(id: 'zte', name: 'ZTE', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 200),
            ClassifiedCategoryModel(id: 'nubia', name: 'Nubia', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 210),
            ClassifiedCategoryModel(id: 'tcl', name: 'TCL', iconName: 'smartphone', parentId: 'smartfoni', sortOrder: 220),
          ],
        ),
        ClassifiedCategoryModel(
          id: 'robusni_telefoni',
          name: 'Robusni telefoni (Rugged / Outdoor)',
          iconName: 'shield',
          parentId: 'telefoni',
          sortOrder: 20,
          subcategories: [
            ClassifiedCategoryModel(id: 'cat', name: 'CAT', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 10),
            ClassifiedCategoryModel(id: 'blackview', name: 'Blackview', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 20),
            ClassifiedCategoryModel(id: 'ulefone', name: 'Ulefone', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 30),
            ClassifiedCategoryModel(id: 'doogee', name: 'Doogee', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 40),
            ClassifiedCategoryModel(id: 'cubot', name: 'Cubot', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 50),
            ClassifiedCategoryModel(id: 'oukitel', name: 'Oukitel', iconName: 'shield', parentId: 'robusni_telefoni', sortOrder: 60),
          ],
        ),
        ClassifiedCategoryModel(
          id: 'klasicni_telefoni',
          name: 'Klasični telefoni (Dugmaši / Za starije)',
          iconName: 'dialpad',
          parentId: 'telefoni',
          sortOrder: 30,
          subcategories: [
            ClassifiedCategoryModel(id: 'nokia_hmd', name: 'Nokia / HMD', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 10),
            ClassifiedCategoryModel(id: 'meanit', name: 'MeanIT', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 20),
            ClassifiedCategoryModel(id: 'denver', name: 'Denver', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 30),
            ClassifiedCategoryModel(id: 'panasonic', name: 'Panasonic', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 40),
            ClassifiedCategoryModel(id: 'maxcom', name: 'Maxcom', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 50),
            ClassifiedCategoryModel(id: 'doro', name: 'Doro', iconName: 'dialpad', parentId: 'klasicni_telefoni', sortOrder: 60),
          ],
        ),
        ClassifiedCategoryModel(id: 'maske_futrole', name: 'Maske, futrole i zaštitna stakla', iconName: 'screen_lock_portrait', parentId: 'telefoni', sortOrder: 40),
        ClassifiedCategoryModel(id: 'punjaci_baterije', name: 'Punjači, kablovi i powerbank', iconName: 'battery_charging_full', parentId: 'telefoni', sortOrder: 50),
        ClassifiedCategoryModel(id: 'slusalice_audio', name: 'Slušalice i prenosivi zvučnici', iconName: 'headphones', parentId: 'telefoni', sortOrder: 60),
        ClassifiedCategoryModel(id: 'pametni_satovi', name: 'Pametni satovi i fitnes narukvice', iconName: 'watch', parentId: 'telefoni', sortOrder: 70),
        ClassifiedCategoryModel(id: 'delovi_telefoni', name: 'Rezervni delovi za telefone', iconName: 'memory', parentId: 'telefoni', sortOrder: 80),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'usluge',
      name: 'Usluge',
      iconName: 'work',
      sortOrder: 110,
      subcategories: [
        ClassifiedCategoryModel(id: 'poljoprivredne_usluge', name: 'Poljoprivredne i terenske usluge', iconName: 'agriculture', parentId: 'usluge', sortOrder: 10),
        ClassifiedCategoryModel(id: 'majstori_zanatlije', name: 'Majstorske i zanatske usluge', iconName: 'handyman', parentId: 'usluge', sortOrder: 20),
        ClassifiedCategoryModel(id: 'gradjevinske_usluge', name: 'Građevinski radovi i iskop', iconName: 'construction', parentId: 'usluge', sortOrder: 30),
        ClassifiedCategoryModel(id: 'prevoz_selidbe', name: 'Prevoz tereta, selidbe i šlep služba', iconName: 'local_shipping', parentId: 'usluge', sortOrder: 40),
        ClassifiedCategoryModel(id: 'servis_mehanike', name: 'Servis mehanizacije i vozila', iconName: 'car_repair', parentId: 'usluge', sortOrder: 50),
        ClassifiedCategoryModel(id: 'poslovi_zaposlenje', name: 'Poslovi i ponuda zaposlenja', iconName: 'work', parentId: 'usluge', sortOrder: 60),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'vozila',
      name: 'Vozila',
      iconName: 'directions_car',
      sortOrder: 120,
      subcategories: [
        ClassifiedCategoryModel(id: 'automobili', name: 'Automobili', iconName: 'directions_car', parentId: 'vozila', sortOrder: 10),
        ClassifiedCategoryModel(id: 'auto_delovi', name: 'Auto delovi i oprema', iconName: 'build', parentId: 'vozila', sortOrder: 20),
        ClassifiedCategoryModel(id: 'teretna_vozila', name: 'Dostavna i teretna vozila', iconName: 'local_shipping', parentId: 'vozila', sortOrder: 30),
        ClassifiedCategoryModel(id: 'prikolice', name: 'Prikolice', iconName: 'rv_hookup', parentId: 'vozila', sortOrder: 40),
        ClassifiedCategoryModel(id: 'motocikli_atv', name: 'Motocikli, skuteri i kvadovi (ATV)', iconName: 'two_wheeler', parentId: 'vozila', sortOrder: 50),
        ClassifiedCategoryModel(id: 'plovila_camci', name: 'Plovila i čamci', iconName: 'sailing', parentId: 'vozila', sortOrder: 60),
      ],
    ),
  ];
}
