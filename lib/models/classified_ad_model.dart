class ClassifiedAdModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double price;
  final String currency; // 'RSD' | 'EUR'
  final String priceType; // 'fixed' | 'negotiable' | 'call' | 'free'
  final String categoryId;
  final String? categoryName;
  final String condition; // 'new' | 'used' | 'not_applicable'
  final List<String> images;
  final String city;
  final String? phone;
  final bool phonePublic;
  final String status; // 'active' | 'sold' | 'archived'
  final String sellerType; // 'individual' | 'business' (Zakon o zaštiti potrošača)
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sellerName;
  final String? sellerAvatar;
  final bool? categoryConditionApplicable;
  final Map<String, dynamic> attributes;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final bool isUrgent;
  final int reportsCount;
  final int callClicksCount;
  final int sharesCount;

  const ClassifiedAdModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.price,
    this.currency = 'RSD',
    this.priceType = 'fixed',
    required this.categoryId,
    this.categoryName,
    this.condition = 'used',
    this.images = const [],
    required this.city,
    this.phone,
    this.phonePublic = true,
    this.status = 'active',
    this.sellerType = 'individual',
    this.viewsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sellerName,
    this.sellerAvatar,
    this.categoryConditionApplicable,
    this.attributes = const {},
    this.isFeatured = false,
    this.featuredUntil,
    this.isUrgent = false,
    this.reportsCount = 0,
    this.callClicksCount = 0,
    this.sharesCount = 0,
  });

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold';
  bool get isArchived => status == 'archived';
  bool get isRejected => status == 'rejected';
  bool get isFlagged => status == 'flagged';
  bool get isAvailable => isActive;
  bool get isCurrentlyFeatured =>
      isFeatured &&
      (featuredUntil == null || featuredUntil!.isAfter(DateTime.now()));

  // --- Deklaracija oglašivača (Zakon o zaštiti potrošača) ---
  bool get isBusinessSeller => sellerType == 'business';
  bool get isIndividualSeller => sellerType != 'business';
  String get sellerTypeLabel =>
      isBusinessSeller ? 'Pravno lice / Trgovac' : 'Fizičko lice';
  String get sellerTypeBadgeText =>
      isBusinessSeller ? 'Trgovac' : 'Fizičko lice';
  String get sellerTypeLegalDisclaimer => isBusinessSeller
      ? 'Oglašivač je registrovan trgovac / pravno lice i posluje u skladu sa Zakonom o zaštiti potrošača.'
      : 'Na kupovinu od fizičkog lica ne primenjuju se odredbe Zakona o zaštiti potrošača o pravu na jednostrani odustanak od ugovora u roku od 14 dana.';

  String get priceFormatted {
    if (priceType == 'free') return 'Besplatno';
    if (priceType == 'call') return 'Pozvati za cenu';
    if (priceType == 'negotiable' && price <= 0) return 'Cena po dogovoru';

    final formattedNum = price >= 1000
        ? price.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (m) => '${m[1]}.',
            )
        : price.toStringAsFixed(0);

    if (priceType == 'negotiable') {
      return '$formattedNum $currency (dogovor)';
    }
    return '$formattedNum $currency';
  }

  // --- Real Estate (Nekretnine) specifična svojstva ---
  static const Set<String> _realEstateCategoryIds = {
    'nekretnine',
    'stanovi',
    'prodaja_stanova',
    'izdavanje_stanova',
    'stan_na_dan',
    'kuce_domacinstva',
    'prodaja_kuca',
    'seoska_domacinstva',
    'izdavanje_kuca',
    'vikendice',
    'planinske_vikendice',
    'vikendice_reka_jezero',
    'brvnare_eko_kuce',
    'poljoprivredno_zemljiste',
    'njive_oranice',
    'vocnjaci_vinogradi',
    'sume_pasnjaci',
    'gradjevinski_placevi',
    'placevi_za_kuce',
    'industrijski_placevi',
    'poslovni_prostori',
    'lokali',
    'kancelarije',
    'magacini_hale',
    'garaze_parking',
    'prodaja_garaza',
    'izdavanje_garaza',
  };

  /// Da li je oglas u kategoriji nekretnina ili poseduje atribute nekretnina
  bool get isRealEstate {
    final cat = categoryId.toLowerCase().trim();
    if (_realEstateCategoryIds.contains(cat)) return true;
    if (attributes.containsKey('area_m2') || attributes.containsKey('land_area_ari')) return true;
    final catName = (categoryName ?? '').toLowerCase();
    return catName.contains('nekretnin') ||
        catName.contains('stan') ||
        catName.contains('kuć') ||
        catName.contains('kuc') ||
        catName.contains('plac') ||
        catName.contains('zemljišt') ||
        catName.contains('zemljist');
  }

  /// Kvadratura u m²
  double? get realEstateAreaM2 {
    final val = attributes['area_m2'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.trim());
    return null;
  }

  /// Površina placa / zemljišta u arima
  double? get realEstateLandAreaAri {
    final val = attributes['land_area_ari'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.trim());
    return null;
  }

  /// Broj soba (npr. "1.5", "2.0", "3.5")
  String? get realEstateRooms => attributes['rooms']?.toString();

  /// Sprat (npr. "2", "prizemlje")
  String? get realEstateFloor => attributes['floor']?.toString();

  /// Grejanje
  String? get realEstateHeating => attributes['heating']?.toString();

  /// Tip transakcije ('prodaja', 'izdavanje', 'na_dan')
  String? get realEstateTransactionType => attributes['transaction_type']?.toString();

  /// Cena po kvadratu (€/m² ili RSD/m²)
  double? get pricePerM2 {
    if (price <= 0) return null;
    final m2 = realEstateAreaM2;
    if (m2 != null && m2 > 0) {
      return price / m2;
    }
    return null;
  }

  /// Cena po aru (€/ar ili RSD/ar)
  double? get pricePerAr {
    if (price <= 0) return null;
    final ari = realEstateLandAreaAri;
    if (ari != null && ari > 0) {
      return price / ari;
    }
    return null;
  }


  /// Kategorije za koje stanje ("Novo" / "Polovno") nema smisla:
  /// - Životinje (mačići, mačke, psi, stoka, živina, ptice, pčele...)
  /// - Voće, povrće, sadnice, semena, stočna hrana, rasad
  /// - Usluge i poslovi
  /// - Nekretnine i zemljišta
  static const Set<String> _inapplicableCategoryIds = {
    // 1. Životinje
    'ljubimci',
    'psi',
    'lovacki_psi',
    'cuvari_ovcari',
    'mali_kucni_psi',
    'terijeri_gonici',
    'udomljavanje_pasa',
    'macke',
    'rasne_macke',
    'domace_macke',
    'domace_zivotinje',
    'stocarstvo_zivotinje',
    'krave_telad',
    'ovce_jagnjad',
    'koze_jarici',
    'svinje_prasad',
    'konji_magarci',
    'zivina_ptice',
    'kokoske_pilici',
    'curke',
    'patke_guske',
    'papagaji_ptice',
    'golubovi',
    'pcelarstvo',
    'pcelinja_drustva_matice',
    'hrana_psi_macke',
    'koncentrati_premiksi',

    // 2. Voće, povrće, rasad, semena, stočna hrana
    'sadnice_semena',
    'sadnice_voca',
    'sadnice_vinove_loze',
    'semenska_roba',
    'semenski_krompir_luk',
    'rasad_povrca',
    'stocna_hrana',
    'balirano_seno_lucerka',
    'balirana_slama',
    'kukuruz_stocni',
    'zitarice_stocne',
    'silaza_senaza',
    'mekinje_sacme',

    // 3. Usluge
    'usluge',
    'poljoprivredne_usluge',
    'oranje_setva',
    'zetva_kombajniranje',
    'baliranje_usluge',
    'orezivanje_prskanje_voca',
    'seca_cepanje_drva',
    'majstori_zanatlije',
    'vodoinstalaterske_usluge',
    'elektricarske_usluge',
    'molerski_gipsarski_radovi',
    'keramicari_plocice',
    'bravarske_usluge',
    'gradjevinske_usluge',
    'iskopi_bageri',
    'zidanje_betoniranje',
    'krovopokrivacki_radovi',
    'asfaltiranje_behaton',
    'rusenje_odvoz_suta',
    'prevoz_selidbe',
    'kombi_prevoz',
    'kamionski_prevoz',
    'slep_sluzba',
    'selidbe_usluge',
    'servis_mehanike',
    'servis_traktora',
    'automehanicari',
    'autolimari_farbari',
    'vulkanizerske_usluge',
    'poslovi_zaposlenje',
    'sezonski_poslovi',
    'poslovi_gradjevina',
    'poslovi_vozaci',
    'poslovi_ugostiteljstvo',

    // 4. Nekretnine
    'nekretnine',
    'stanovi',
    'prodaja_stanova',
    'izdavanje_stanova',
    'stan_na_dan',
    'kuce_domacinstva',
    'prodaja_kuca',
    'seoska_domacinstva',
    'izdavanje_kuca',
    'vikendice',
    'planinske_vikendice',
    'vikendice_reka_jezero',
    'brvnare_eko_kuce',
    'poljoprivredno_zemljiste',
    'njive_oranice',
    'vocnjaci_vinogradi',
    'sume_pasnjaci',
    'gradjevinski_placevi',
    'placevi_za_kuce',
    'industrijski_placevi',
    'poslovni_prostori',
    'lokali',
    'kancelarije',
    'magacini_hale',
    'garaze_parking',
    'prodaja_garaza',
    'izdavanje_garaza',
  };

  static const List<String> _equipmentKeywords = [
    'oprem',
    'masin',
    'alat',
    'delov',
    'pribor',
    'kavez',
    'boks',
    'kucic',
    'mlin',
    'seck',
    'pres',
    'kazan',
    'burad',
    'flas',
    'pump',
    'trake',
    'sistem',
    'ogrlice',
    'povoc',
    'povodac',
    'hranilic',
    'pojilic',
    'muzilic',
    'kosnic',
    'ramov',
    'centrifug',
    'odelo',
    'traktor',
    'kombajn',
    'prikljuc',
  ];

  static const Set<String> _inapplicableExactWords = {
    // Životinje
    'pas', 'psi', 'kucka', 'kuce', 'kucici', 'ker', 'kerovi',
    'bik', 'bikovi', 'tele', 'telad', 'krava', 'krave', 'junad', 'junica',
    'ovan', 'ovnovi', 'ovca', 'ovce', 'jagnje', 'jagnjad',
    'koza', 'koze', 'jarac', 'jarci', 'jaric', 'jarici',
    'svinja', 'svinje', 'prase', 'prasad', 'krmaca', 'krmace', 'nerast',
    'konj', 'konji', 'kobila', 'kobile', 'zdrebe', 'zdrebad', 'magarac', 'magarci',
    'pile', 'pilici', 'kokoska', 'kokoske', 'petao', 'petlovi',
    'curka', 'curke', 'curic', 'curici', 'patka', 'patke', 'guska', 'guske',
    'morka', 'morke', 'golub', 'golubovi', 'papagaj', 'papagaji', 'kanarinac',
    'ptica', 'ptice', 'pcela', 'pcele', 'roj', 'rojevi', 'matica', 'matice',
    'zivotinja', 'zivotinje', 'stoka', 'zivina',

    // Hrana, usevi, sirovine
    'seno', 'slama', 'sir', 'kajmak', 'mleko', 'med', 'orasi', 'ovas',
  };

  static const List<String> _inapplicableWordPrefixes = [
    // Životinje (mačići, mačke, štenci...)
    'macic', 'mack', 'stenc', 'stenad', 'stene', 'kucic',

    // Voće i povrće, sadnice, semena, plodovi
    'voce', 'povrc', 'jabuk', 'krusk', 'sljiv', 'malin', 'kupin', 'jagod',
    'tresnj', 'visnj', 'grozd', 'kajsij', 'breskv', 'dunj', 'lesnik', 'orah',
    'krompir', 'paradajz', 'paprik', 'kupus', 'pasulj', 'luk',
    'sargarep', 'cvekl', 'krastav', 'tikvic', 'grasak', 'grask', 'spanac',
    'zelje', 'kelerab', 'rotkvic', 'sadnic', 'rasad', 'semen', 'arpadzik',
    'psenic', 'kukuruz', 'jecam', 'jecm', 'lucerk', 'detelin', 'silaz',
    'senaz', 'mekinj', 'sacm', 'dzem', 'pekmez', 'ajvar',

    // Usluge
    'uslug', 'majstor', 'zanat', 'prevoz', 'selidb',

    // Nekretnine
    'nekretnin', 'plac', 'zemljist',
  ];

  static String _normalizeSerbian(String text) {
    var s = text.toLowerCase();
    const cyrToLat = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'ђ': 'dj', 'е': 'e',
      'ж': 'z', 'з': 'z', 'и': 'i', 'ј': 'j', 'к': 'k', 'л': 'l', 'љ': 'lj',
      'м': 'm', 'н': 'n', 'њ': 'nj', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's',
      'т': 't', 'ћ': 'c', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c', 'ч': 'c',
      'џ': 'dz', 'ш': 's',
    };
    cyrToLat.forEach((cyr, lat) {
      s = s.replaceAll(cyr, lat);
    });
    return s
        .replaceAll('č', 'c')
        .replaceAll('ć', 'c')
        .replaceAll('š', 's')
        .replaceAll('ž', 'z')
        .replaceAll('đ', 'dj');
  }

  /// Proverava da li kategorija ili oglas podržava stanje ("Novo" / "Polovno").
  /// Ako je poznata vrednost sa servera (categoryConditionApplicable), ona je primarni izvor istine.
  /// U suprotnom, koristi se lokalna fallback heuristika.
  static bool isConditionApplicableForCategory({
    String? categoryId,
    String? categoryName,
    String? title,
    bool? categoryConditionApplicable,
  }) {
    // 1. Ako baza eksplicitno kaže false -> NIKADA nije primenjivo
    if (categoryConditionApplicable == false) {
      return false;
    }

    // 2. Ako je ID kategorije na strogoj listi neprikladnih (nekretnine, usluge, životinje, usevi...)
    // -> NIKADA nije primenjivo (čak i ako keš ili klijent ima neusklađenu vrednost)
    final cleanCatId = categoryId?.trim().toLowerCase();
    if (cleanCatId != null && _inapplicableCategoryIds.contains(cleanCatId)) {
      return false;
    }

    // 3. Ako baza eksplicitno kaže true (i nije na strogoj crnoj listi)
    if (categoryConditionApplicable == true) {
      return true;
    }

    final combinedText = '${categoryName ?? ''} ${title ?? ''}'.trim();
    if (combinedText.isEmpty) return true;

    final norm = _normalizeSerbian(combinedText);

    // Ako tekst eksplicitno sadrži reč za opremu, mašinu ili alat, stanje JESTE primenjivo
    // (npr. "kavez za mačiće", "mlin za voće", "oprema za pčelarstvo")
    for (final eq in _equipmentKeywords) {
      if (norm.contains(eq)) return true;
    }

    final words = norm.split(RegExp(r'[^a-z0-9]+')).where((w) => w.isNotEmpty);
    for (final word in words) {
      if (_inapplicableExactWords.contains(word)) return false;
      for (final prefix in _inapplicableWordPrefixes) {
        if (word.startsWith(prefix)) return false;
      }
    }

    return true;
  }

  /// Da li je stanje primenjivo za ovaj oglas
  bool get isConditionApplicable => isConditionApplicableForCategory(
        categoryId: categoryId,
        categoryName: categoryName,
        title: title,
        categoryConditionApplicable: categoryConditionApplicable,
      );

  /// Da li treba prikazati bedž stanja ("Novo" / "Polovno")
  bool get showConditionBadge =>
      isConditionApplicable &&
      condition != 'not_applicable' &&
      (condition == 'new' || condition == 'used');

  String get conditionLabel {
    if (!isConditionApplicable || condition == 'not_applicable') {
      return '';
    }
    switch (condition) {
      case 'new':
        return 'Novo';
      case 'used':
        return 'Polovno';
      default:
        return '';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return 'pre $months ${months == 1 ? 'mesec' : 'meseca'}';
    }
    if (diff.inDays > 0) {
      return 'pre ${diff.inDays} ${diff.inDays == 1 ? 'dan' : 'dana'}';
    }
    if (diff.inHours > 0) {
      return 'pre ${diff.inHours} ${diff.inHours == 1 ? 'sat' : 'sata'}';
    }
    if (diff.inMinutes > 0) {
      return 'pre ${diff.inMinutes} min';
    }
    return 'Upravo objavljeno';
  }

  factory ClassifiedAdModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final cat = json['classified_categories'] as Map<String, dynamic>?;

    return ClassifiedAdModel(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['seller_id'] ?? '') as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'RSD',
      priceType: json['price_type'] as String? ?? 'fixed',
      categoryId: json['category_id'] as String? ?? '',
      categoryName: cat?['name'] as String?,
      condition: json['condition'] as String? ?? 'used',
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String?,
      phonePublic: json['phone_public'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      sellerType: json['seller_type'] as String? ?? 'individual',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sellerName: profile?['farm_name'] as String? ??
          profile?['display_name'] as String?,
      sellerAvatar: profile?['profile_image_url'] as String?,
      categoryConditionApplicable:
          cat?['is_condition_applicable'] as bool?,
      attributes: (json['attributes'] is Map)
          ? Map<String, dynamic>.from(json['attributes'] as Map)
          : const {},
      isFeatured: json['is_featured'] as bool? ?? false,
      featuredUntil: json['featured_until'] != null
          ? DateTime.tryParse(json['featured_until'].toString())
          : null,
      isUrgent: json['is_urgent'] as bool? ?? false,
      reportsCount: (json['reports_count'] as num?)?.toInt() ?? 0,
      callClicksCount: (json['call_clicks_count'] as num?)?.toInt() ?? 0,
      sharesCount: (json['shares_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson({
    bool includeId = true,
    bool includeCreatedAt = true,
  }) {
    return {
      if (includeId && id.isNotEmpty) 'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'price_type': priceType,
      'category_id': categoryId,
      'condition': condition,
      'images': images,
      'city': city,
      if (phone != null) 'phone': phone,
      'phone_public': phonePublic,
      'status': status,
      'seller_type': sellerType,
      'attributes': attributes,
      'is_featured': isFeatured,
      if (featuredUntil != null)
        'featured_until': featuredUntil!.toIso8601String(),
      'is_urgent': isUrgent,
      'reports_count': reportsCount,
      'call_clicks_count': callClicksCount,
      'shares_count': sharesCount,
      if (includeCreatedAt) 'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Mapa namenjena za ažuriranje oglasa od strane vlasnika (`UPDATE`).
  /// Izostavlja vlasničke, administrativne i analitičke kolone (`user_id`, `is_featured`,
  /// `featured_until`, `is_urgent`, `reports_count`, `call_clicks_count`, `shares_count`, `views_count`)
  /// kako izmene oglasa ne bi izazvale `42501` grešku na trigger-u ako se u međuvremenu promenio admin status.
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'price_type': priceType,
      'category_id': categoryId,
      'condition': condition,
      'images': images,
      'city': city,
      if (phone != null) 'phone': phone,
      'phone_public': phonePublic,
      'status': status,
      'seller_type': sellerType,
      'attributes': attributes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ClassifiedAdModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? price,
    String? currency,
    String? priceType,
    String? categoryId,
    String? categoryName,
    String? condition,
    List<String>? images,
    String? city,
    String? phone,
    bool clearPhone = false,
    bool? phonePublic,
    String? status,
    String? sellerType,
    int? viewsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerName,
    String? sellerAvatar,
    bool? categoryConditionApplicable,
    Map<String, dynamic>? attributes,
    bool? isFeatured,
    DateTime? featuredUntil,
    bool? isUrgent,
    int? reportsCount,
    int? callClicksCount,
    int? sharesCount,
  }) {
    return ClassifiedAdModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      priceType: priceType ?? this.priceType,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      city: city ?? this.city,
      phone: clearPhone ? null : (phone ?? this.phone),
      phonePublic: phonePublic ?? this.phonePublic,
      status: status ?? this.status,
      sellerType: sellerType ?? this.sellerType,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      categoryConditionApplicable:
          categoryConditionApplicable ?? this.categoryConditionApplicable,
      attributes: attributes ?? this.attributes,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      isUrgent: isUrgent ?? this.isUrgent,
      reportsCount: reportsCount ?? this.reportsCount,
      callClicksCount: callClicksCount ?? this.callClicksCount,
      sharesCount: sharesCount ?? this.sharesCount,
    );
  }
}
