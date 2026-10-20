import 'package:flutter/material.dart';

import 'classified_category_data.dart';
import 'classified_category_icons.dart';

export 'classified_category_data.dart';
export 'classified_category_icons.dart';

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
    final id = json['id'] as String;
    var name = json['name'] as String;
    var iconName = json['icon_name'] as String? ?? 'category';
    var parentId = json['parent_id'] as String?;

    if (id == 'ljubimci') {
      name = 'Kućni ljubimci';
    }
    if (id == 'domace_zivotinje' || id == 'stocarstvo_zivotinje') {
      parentId = 'poljoprivreda';
      name = 'Domaće životinje i stoka';
      if (iconName == 'pets' || iconName.isEmpty) {
        iconName = 'pig';
      }
    }
    if (id == 'zivinarstvo') {
      parentId = 'poljoprivreda';
      name = 'Živinarstvo i peradarstvo';
      iconName = 'egg';
    }
    if (id == 'stocarska_oprema') {
      parentId = 'poljoprivreda';
      name = 'Stočarska oprema i muzilice';
      iconName = 'precision_manufacturing';
    }
    if (id == 'pcelarstvo') {
      parentId = 'poljoprivreda';
    }
    if (id == 'kokoske_pilici' || id == 'curke' || id == 'patke_guske') {
      parentId = 'zivinarstvo';
    }
    if (id == 'koncentrati_premiksi') {
      parentId = 'stocna_hrana';
    }
    if (id == 'hranilice_pojilice_muzilice') {
      parentId = 'stocarska_oprema';
    }
    if (id == 'zivina_ptice') {
      name = 'Ptice i ostali kućni ljubimci';
      iconName = 'bird';
    }
    if (id == 'oprema_za_zivotinje') {
      name = 'Hrana i oprema za kućne ljubimce';
    }

    return ClassifiedCategoryModel(
      id: id,
      name: name,
      iconName: iconName,
      parentId: parentId,
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

  IconData get iconData => getCategoryIconData(iconName);

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

  /// Offline i inicijalni set kategorija sa kompletnim stablom stubova i podkategorija.
  /// Usklađeno sa zvaničnim nazivima iz baze i Google SEO hijerarhijom.
  /// Pun set i najnovije izmene se dinamički sinhronizuju iz Supabase baze (Single Source of Truth).
  static const List<ClassifiedCategoryModel> fallbackCategories =
      kClassifiedFallbackCategories;
}
