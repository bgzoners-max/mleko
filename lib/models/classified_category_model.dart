import 'package:flutter/material.dart';

class ClassifiedCategoryModel {
  final String id;
  final String name;
  final String iconName;
  final String? parentId;
  final int sortOrder;
  final bool isConditionApplicable;
  final List<ClassifiedCategoryModel> subcategories;
  final int adCount;

  const ClassifiedCategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.parentId,
    this.sortOrder = 0,
    this.isConditionApplicable = true,
    this.subcategories = const [],
    this.adCount = 0,
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
      isConditionApplicable:
          (json['is_condition_applicable'] as bool?) ?? true,
      subcategories: subcategories,
      adCount: (json['ad_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'parent_id': parentId,
      'sort_order': sortOrder,
      'is_condition_applicable': isConditionApplicable,
      'ad_count': adCount,
    };
  }

  ClassifiedCategoryModel copyWith({
    bool? isConditionApplicable,
    List<ClassifiedCategoryModel>? subcategories,
    int? adCount,
  }) {
    return ClassifiedCategoryModel(
      id: id,
      name: name,
      iconName: iconName,
      parentId: parentId,
      sortOrder: sortOrder,
      isConditionApplicable:
          isConditionApplicable ?? this.isConditionApplicable,
      subcategories: subcategories ?? this.subcategories,
      adCount: adCount ?? this.adCount,
    );
  }

  static const Set<String> _carBrandIds = {
    'auto_volkswagen',
    'auto_bmw',
    'auto_mercedes_benz',
    'auto_audi',
    'auto_porsche',
    'auto_opel',
    'auto_toyota',
    'auto_honda',
    'auto_nissan',
    'auto_mazda',
    'auto_subaru',
    'auto_suzuki',
    'auto_mitsubishi',
    'auto_lexus',
    'auto_hyundai',
    'auto_kia',
    'auto_ford',
    'auto_chevrolet',
    'auto_tesla',
    'auto_jeep',
    'auto_cadillac',
    'auto_rivian',
    'auto_fiat',
    'auto_alfa_romeo',
    'auto_ferrari',
    'auto_maserati',
    'auto_lamborghini',
    'auto_renault',
    'auto_peugeot',
    'auto_citroen',
    'auto_bugatti',
    'auto_jaguar',
    'auto_land_rover',
    'auto_aston_martin',
    'auto_bentley',
    'auto_rolls_royce',
    'auto_byd',
    'auto_nio',
    'auto_xpeng',
    'auto_zeekr',
    'auto_mg',
    'auto_volvo',
    'auto_polestar',
    'auto_skoda',
    'auto_seat',
    'auto_cupra',
    'auto_dacia',
    'auto_lada',
    'auto_zastava',
    'auto_smart',
    'auto_mini',
    'auto_lancia',
    'auto_saab',
    'auto_chrysler',
    'auto_dodge',
    'auto_daewoo',
    'auto_geely',
    'auto_chery',
    'auto_infiniti',
    'auto_isuzu',
    'auto_ds',
    'auto_ssangyong',
    'auto_rover',
    'auto_genesis',
  };

  static const Set<String> _phoneBrandIds = {
    'apple',
    'samsung',
    'xiaomi',
    'redmi',
    'poco',
    'honor',
    'motorola',
    'realme',
    'vivo',
    'infinix',
    'tecno',
    'google',
    'nothing',
    'cmf_nothing',
    'huawei',
    'asus',
    'asus_rog',
    'asus_zenfone',
    'sony',
    'zte',
    'nubia',
    'tcl',
    'smartfoni_ostalo',
    'ostali_smartfoni',
    'nokia_hmd',
    'cat',
  };

  /// Proverava da li je dati ID kategorije brend mobilnog telefona
  static bool isPhoneBrand(String? id) =>
      id != null && _phoneBrandIds.contains(id.toLowerCase());

  /// Vraća hijerarhijsku putanju kategorija od korena do traženog ID-ja (npr. [Telefoni, Smartfoni, Redmi])
  static List<ClassifiedCategoryModel> findPath(
    String targetId,
    List<ClassifiedCategoryModel> nodes,
  ) {
    final path = <ClassifiedCategoryModel>[];
    _findPathRecursive(targetId, nodes, path);
    return path;
  }

  static bool _findPathRecursive(
    String targetId,
    List<ClassifiedCategoryModel> nodes,
    List<ClassifiedCategoryModel> currentPath,
  ) {
    for (final node in nodes) {
      currentPath.add(node);
      if (node.id == targetId) return true;
      if (_findPathRecursive(targetId, node.subcategories, currentPath)) {
        return true;
      }
      currentPath.removeLast();
    }
    return false;
  }

  static const Set<String> _tractorBrandIds = {
    'traktori_imt_imr',
    'traktori_belarus',
    'traktori_zetor_ursus',
    'traktori_zapadni',
  };

  /// Vraća putanju do zvaničnog logotipa brenda (automobili, telefoni, traktori) ako je dostupna.
  String? get brandLogoAsset {
    if (_carBrandIds.contains(id)) {
      return 'assets/images/car_brands/$id.png';
    }
    if (_phoneBrandIds.contains(id)) {
      return 'assets/images/phone_brands/$id.png';
    }
    if (_tractorBrandIds.contains(id)) {
      return 'assets/images/tractor_brands/$id.png';
    }
    return null;
  }

  IconData get iconData {
    switch (iconName) {
      case 'accessible':
        return Icons.accessible;
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
      case 'brush':
        return Icons.brush;
      case 'build':
        return Icons.build;
      case 'business':
        return Icons.business;
      case 'business_center':
        return Icons.business_center;
      case 'cabin':
        return Icons.cabin;
      case 'cable':
        return Icons.cable;
      case 'camera_alt':
        return Icons.camera_alt;
      case 'campaign':
        return Icons.campaign;
      case 'car_repair':
        return Icons.car_repair;
      case 'carpenter':
        return Icons.carpenter;
      case 'celebration':
        return Icons.celebration;
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
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'computer':
        return Icons.computer;
      case 'coffee':
        return Icons.coffee;
      case 'connected_tv':
        return Icons.connected_tv;
      case 'construction':
        return Icons.construction;
      case 'content_cut':
        return Icons.content_cut;
      case 'countertops':
        return Icons.countertops;
      case 'cruelty_free':
        return Icons.cruelty_free;
      case 'cottage':
        return Icons.cottage;
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
      case 'devices':
        return Icons.devices;
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
      case 'downhill_skiing':
        return Icons.downhill_skiing;
      case 'eco':
        return Icons.eco;
      case 'egg':
        return Icons.egg;
      case 'electric_bike':
        return Icons.electric_bike;
      case 'electric_scooter':
        return Icons.electric_scooter;
      case 'electrical_services':
        return Icons.electrical_services;
      case 'extension':
        return Icons.extension;
      case 'face':
        return Icons.face;
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
      case 'flag':
        return Icons.flag;
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
      case 'health_and_safety':
        return Icons.health_and_safety;
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
      case 'local_florist':
        return Icons.local_florist;
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
      case 'palette':
        return Icons.palette;
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
      case 'public':
        return Icons.public;
      case 'radiator':
        return Icons.hvac;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'reorder':
        return Icons.reorder;
      case 'restaurant':
        return Icons.restaurant;
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
      case 'sports_basketball':
        return Icons.sports_basketball;
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
      case 'skateboarding':
        return Icons.skateboarding;
      case 'square':
        return Icons.square;
      case 'storage':
        return Icons.storage;
      case 'storefront':
        return Icons.storefront;
      case 'straighten':
        return Icons.straighten;
      case 'stroller':
        return Icons.stroller;
      case 'support_agent':
        return Icons.support_agent;
      case 'surfing':
        return Icons.surfing;
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
      case 'toys':
        return Icons.toys;
      case 'track_changes':
        return Icons.track_changes;
      case 'transfer_within_a_station':
        return Icons.transfer_within_a_station;
      case 'translate':
        return Icons.translate;
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
        // U Flutter Icons klasi ne postoji 'water_heater' (to je noviji Google Material Symbol, a Flutter koristi MaterialIcons font).
        // Za kategoriju Bojleri kao najbliži semantički pandan koristi se heat_pump.
        return Icons.heat_pump;
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

  static final Map<String, String> _serbianKeyCache = <String, String>{};
  static const int _serbianKeyCacheLimit = 2000;

  /// Normalizacija za srpsku abecedu. Memoizovana jer se komparator poziva
  /// O(n log n) puta tokom sortiranja nad istim imenima kategorija.
  static String _serbianKey(String s) {
    final cached = _serbianKeyCache[s];
    if (cached != null) return cached;
    final key = s
        .toLowerCase()
        .replaceAll('č', 'c~1')
        .replaceAll('ć', 'c~2')
        .replaceAll('dž', 'd~1')
        .replaceAll('đ', 'd~2')
        .replaceAll('lj', 'l~1')
        .replaceAll('nj', 'n~1')
        .replaceAll('š', 's~1')
        .replaceAll('ž', 'z~1');
    // Ograniči rast keša; imena kategorija su mala i stabilna.
    if (_serbianKeyCache.length >= _serbianKeyCacheLimit) {
      _serbianKeyCache.clear();
    }
    _serbianKeyCache[s] = key;
    return key;
  }

  static int compareSerbian(String a, String b) =>
      _serbianKey(a).compareTo(_serbianKey(b));

  /// Primarno sortiranje po definisanom redosledu iz baze (sortOrder),
  /// a sekundarno po srpskoj abecedi za kategorije sa istim prioritetom.
  static int compareCategories(ClassifiedCategoryModel a, ClassifiedCategoryModel b) {
    if (a.sortOrder != b.sortOrder) {
      return a.sortOrder.compareTo(b.sortOrder);
    }
    return compareSerbian(a.name, b.name);
  }

  /// Minimalni offline fallback za slučaj prvog pokretanja bez interneta i keša.
  /// Usklađeno sa redosledom stubova iz baze (migracija 20260903120000).
  /// Pun set i sve hijerarhije podkategorija se dinamički učitavaju iz Supabase baze (Single Source of Truth)
  /// i automatski keširaju u SharedPreferences.
  static const List<ClassifiedCategoryModel> fallbackCategories = [
    ClassifiedCategoryModel(id: 'poljoprivreda', name: 'Poljoprivreda', iconName: 'agriculture', sortOrder: 10),
    ClassifiedCategoryModel(id: 'vozila', name: 'Vozila', iconName: 'directions_car', sortOrder: 20),
    ClassifiedCategoryModel(id: 'masine_alati', name: 'Mašine i alati', iconName: 'handyman', sortOrder: 30),
    ClassifiedCategoryModel(id: 'dom_basta', name: 'Dom i bašta', iconName: 'chair', sortOrder: 40),
    ClassifiedCategoryModel(id: 'telefoni', name: 'Telefoni', iconName: 'smartphone', sortOrder: 50),
    ClassifiedCategoryModel(id: 'tehnika', name: 'Tehnika', iconName: 'laptop', sortOrder: 60),
    ClassifiedCategoryModel(id: 'nekretnine', name: 'Nekretnine', iconName: 'home_work', sortOrder: 70, isConditionApplicable: false),
    ClassifiedCategoryModel(id: 'gradjevinarstvo', name: 'Građevinarstvo', iconName: 'foundation', sortOrder: 80),
    ClassifiedCategoryModel(id: 'odeca_obuca', name: 'Odeća i obuća', iconName: 'checkroom', sortOrder: 90),
    ClassifiedCategoryModel(id: 'deca_bebe', name: 'Sve za decu i bebe', iconName: 'child_friendly', sortOrder: 95),
    ClassifiedCategoryModel(id: 'sport_hobi', name: 'Sport i hobi', iconName: 'sports_soccer', sortOrder: 100),
    ClassifiedCategoryModel(id: 'ljubimci', name: 'Ljubimci', iconName: 'pets', sortOrder: 110, isConditionApplicable: false),
    ClassifiedCategoryModel(id: 'usluge', name: 'Usluge', iconName: 'work', sortOrder: 120, isConditionApplicable: false),
    ClassifiedCategoryModel(id: 'zdravlje_lepota', name: 'Zdravlje i lepota', iconName: 'spa', sortOrder: 130),
    ClassifiedCategoryModel(id: 'knjige_edukacija', name: 'Knjige i edukacija', iconName: 'menu_book', sortOrder: 140),
    ClassifiedCategoryModel(id: 'umetnost_rukotvorine', name: 'Umetnost i rukotvorine', iconName: 'palette', sortOrder: 150),
  ];
}
