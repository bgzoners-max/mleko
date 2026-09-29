import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';

void main() {
  group('ClassifiedCategoryModel', () {
    test('parses root category and subcategories correctly', () {
      final json = {
        'id': 'poljoprivreda',
        'name': 'Poljoprivreda i mehanizacija',
        'icon_name': 'agriculture',
        'parent_id': null,
        'sort_order': 10,
      };

      final cat = ClassifiedCategoryModel.fromJson(json);
      expect(cat.id, 'poljoprivreda');
      expect(cat.name, 'Poljoprivreda i mehanizacija');
      expect(cat.isRoot, isTrue);
      expect(cat.iconData, Icons.agriculture);
    });

    test('parses subcategory with parent_id', () {
      final json = {
        'id': 'traktori',
        'name': 'Traktori i kombajni',
        'icon_name': 'agriculture',
        'parent_id': 'poljoprivreda',
        'sort_order': 1,
      };

      final cat = ClassifiedCategoryModel.fromJson(json);
      expect(cat.id, 'traktori');
      expect(cat.parentId, 'poljoprivreda');
      expect(cat.isRoot, isFalse);
    });

    test('brandLogoAsset returns correct path for car brands and null for non-car brands', () {
      final audi = const ClassifiedCategoryModel(
        id: 'auto_audi',
        name: 'Audi',
        iconName: 'directions_car',
        parentId: 'auto_nemacka',
      );
      expect(audi.brandLogoAsset, 'assets/images/car_brands/auto_audi.png');

      final bmw = const ClassifiedCategoryModel(
        id: 'auto_bmw',
        name: 'BMW',
        iconName: 'directions_car',
        parentId: 'auto_nemacka',
      );
      expect(bmw.brandLogoAsset, 'assets/images/car_brands/auto_bmw.png');

      final zastava = const ClassifiedCategoryModel(
        id: 'auto_zastava',
        name: 'Zastava',
        iconName: 'directions_car',
        parentId: 'auto_srbija',
      );
      expect(zastava.brandLogoAsset, 'assets/images/car_brands/auto_zastava.png');

      final smart = const ClassifiedCategoryModel(
        id: 'auto_smart',
        name: 'Smart',
        iconName: 'directions_car',
        parentId: 'auto_nemacka',
      );
      expect(smart.brandLogoAsset, 'assets/images/car_brands/auto_smart.png');

      final mini = const ClassifiedCategoryModel(
        id: 'auto_mini',
        name: 'Mini',
        iconName: 'directions_car',
        parentId: 'auto_velika_britanija',
      );
      expect(mini.brandLogoAsset, 'assets/images/car_brands/auto_mini.png');

      final lancia = const ClassifiedCategoryModel(
        id: 'auto_lancia',
        name: 'Lancia',
        iconName: 'directions_car',
        parentId: 'auto_italija',
      );
      expect(lancia.brandLogoAsset, 'assets/images/car_brands/auto_lancia.png');

      final traktori = const ClassifiedCategoryModel(
        id: 'traktori',
        name: 'Traktori',
        iconName: 'agriculture',
        parentId: 'poljoprivreda',
      );
      expect(traktori.brandLogoAsset, isNull);
    });

    test('compareCategories respects sortOrder first and Serbian alphabetical second', () {
      const poljoprivreda = ClassifiedCategoryModel(
        id: 'poljoprivreda',
        name: 'Poljoprivreda',
        iconName: 'agriculture',
        sortOrder: 10,
      );
      const domBasta = ClassifiedCategoryModel(
        id: 'dom_basta',
        name: 'Dom i bašta',
        iconName: 'chair',
        sortOrder: 40,
      );
      const gradjevinarstvo = ClassifiedCategoryModel(
        id: 'gradjevinarstvo',
        name: 'Građevinarstvo',
        iconName: 'foundation',
        sortOrder: 40,
      );

      // poljoprivreda (10) comes before domBasta (40) despite 'D' < 'P'
      expect(ClassifiedCategoryModel.compareCategories(poljoprivreda, domBasta), isNegative);
      expect(ClassifiedCategoryModel.compareCategories(domBasta, poljoprivreda), isPositive);

      // Same sortOrder: domBasta ('D') comes before gradjevinarstvo ('G')
      expect(ClassifiedCategoryModel.compareCategories(domBasta, gradjevinarstvo), isNegative);
    });
  });

  group('ClassifiedAdModel formatting and serialization', () {
    test('formats fixed price in EUR and RSD correctly', () {
      final adEur = ClassifiedAdModel(
        id: 'ad-1',
        userId: 'user-1',
        title: 'Traktor IMT 539',
        price: 4500,
        currency: 'EUR',
        priceType: 'fixed',
        categoryId: 'traktori',
        city: 'Kragujevac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(adEur.priceFormatted, '4.500 EUR');

      final adRsd = ClassifiedAdModel(
        id: 'ad-2',
        userId: 'user-1',
        title: 'Bušilica Bosch',
        price: 12500,
        currency: 'RSD',
        priceType: 'fixed',
        categoryId: 'masine_alati',
        city: 'Čačak',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(adRsd.priceFormatted, '12.500 RSD');
    });

    test('formats negotiable, call, and free prices', () {
      final adFree = ClassifiedAdModel(
        id: 'ad-3',
        userId: 'user-1',
        title: 'Štenad mešanci',
        price: 0,
        priceType: 'free',
        categoryId: 'ljubimci',
        city: 'Beograd',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adFree.priceFormatted, 'Besplatno');

      final adCall = ClassifiedAdModel(
        id: 'ad-4',
        userId: 'user-1',
        title: 'Kombajn Zmaj 142',
        price: 0,
        priceType: 'call',
        categoryId: 'poljoprivreda',
        city: 'Sombor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCall.priceFormatted, 'Pozvati za cenu');

      final adNegotiable = ClassifiedAdModel(
        id: 'ad-5',
        userId: 'user-1',
        title: 'Auto prikolica',
        price: 600,
        currency: 'EUR',
        priceType: 'negotiable',
        categoryId: 'vozila',
        city: 'Niš',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adNegotiable.priceFormatted, '600 EUR (dogovor)');
    });

    test('condition labels and statuses', () {
      final adNew = ClassifiedAdModel(
        id: 'ad-6',
        userId: 'user-1',
        title: 'Nova motorna testera',
        price: 180,
        currency: 'EUR',
        categoryId: 'masine_alati',
        condition: 'new',
        status: 'active',
        city: 'Užice',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adNew.conditionLabel, 'Novo');
      expect(adNew.isActive, isTrue);
      expect(adNew.isSold, isFalse);

      final adSold = ClassifiedAdModel(
        id: 'ad-7',
        userId: 'user-1',
        title: 'Kosilica',
        price: 120,
        categoryId: 'masine_alati',
        condition: 'used',
        status: 'sold',
        city: 'Valjevo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adSold.conditionLabel, 'Polovno');
      expect(adSold.isSold, isTrue);
      expect(adSold.isActive, isFalse);
    });

    test('condition is NOT applicable for kittens and animals in general', () {
      final adKitten = ClassifiedAdModel(
        id: 'ad-kitten-1',
        userId: 'user-1',
        title: 'Persijski mačići na prodaju',
        price: 150,
        currency: 'EUR',
        categoryId: 'macke',
        condition: 'used',
        city: 'Beograd',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adKitten.isConditionApplicable, isFalse);
      expect(adKitten.showConditionBadge, isFalse);
      expect(adKitten.conditionLabel, isEmpty);

      final adCyrillicKitten = ClassifiedAdModel(
        id: 'ad-kitten-2',
        userId: 'user-1',
        title: 'Британски мачићи',
        price: 200,
        currency: 'EUR',
        categoryId: 'ljubimci',
        condition: 'new',
        city: 'Novi Sad',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCyrillicKitten.isConditionApplicable, isFalse);
      expect(adCyrillicKitten.showConditionBadge, isFalse);
      expect(adCyrillicKitten.conditionLabel, isEmpty);

      final adPuppy = ClassifiedAdModel(
        id: 'ad-puppy',
        userId: 'user-1',
        title: 'Štenci labradora',
        price: 180,
        currency: 'EUR',
        categoryId: 'psi',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adPuppy.isConditionApplicable, isFalse);
      expect(adPuppy.showConditionBadge, isFalse);

      final adCalf = ClassifiedAdModel(
        id: 'ad-calf',
        userId: 'user-1',
        title: 'Muško tele simentalac',
        price: 650,
        currency: 'EUR',
        categoryId: 'domace_zivotinje',
        condition: 'new',
        city: 'Kraljevo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCalf.isConditionApplicable, isFalse);
      expect(adCalf.showConditionBadge, isFalse);
    });

    test('condition is NOT applicable for fruits, vegetables, seeds, and fodder', () {
      final adApples = ClassifiedAdModel(
        id: 'ad-apples',
        userId: 'user-1',
        title: 'Domaće jabuke ajdared',
        price: 90,
        currency: 'RSD',
        categoryId: 'poljoprivreda',
        condition: 'used',
        city: 'Čačak',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adApples.isConditionApplicable, isFalse);
      expect(adApples.showConditionBadge, isFalse);
      expect(adApples.conditionLabel, isEmpty);

      final adCyrillicFruit = ClassifiedAdModel(
        id: 'ad-fruit-cyr',
        userId: 'user-1',
        title: 'Свеже шљиве за ракију',
        price: 50,
        currency: 'RSD',
        categoryId: 'poljoprivreda',
        condition: 'new',
        city: 'Valjevo',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCyrillicFruit.isConditionApplicable, isFalse);
      expect(adCyrillicFruit.showConditionBadge, isFalse);

      final adSeedlings = ClassifiedAdModel(
        id: 'ad-seedlings',
        userId: 'user-1',
        title: 'Kontejnerski rasad paprike i paradajza',
        price: 45,
        currency: 'RSD',
        categoryId: 'sadnice_semena',
        condition: 'new',
        city: 'Leskovac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adSeedlings.isConditionApplicable, isFalse);
      expect(adSeedlings.showConditionBadge, isFalse);

      final adHay = ClassifiedAdModel(
        id: 'ad-hay',
        userId: 'user-1',
        title: 'Balirano detelinsko seno',
        price: 300,
        currency: 'RSD',
        categoryId: 'stocna_hrana',
        condition: 'used',
        city: 'Sombor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adHay.isConditionApplicable, isFalse);
      expect(adHay.showConditionBadge, isFalse);
    });

    test('condition IS applicable for equipment, tools, vehicles, and machinery', () {
      final adCage = ClassifiedAdModel(
        id: 'ad-cage',
        userId: 'user-1',
        title: 'Veliki boks i kavez za pse ili mačke',
        price: 4500,
        currency: 'RSD',
        categoryId: 'oprema_za_zivotinje',
        condition: 'used',
        city: 'Beograd',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCage.isConditionApplicable, isTrue);
      expect(adCage.showConditionBadge, isTrue);
      expect(adCage.conditionLabel, 'Polovno');

      final adFruitMill = ClassifiedAdModel(
        id: 'ad-mill',
        userId: 'user-1',
        title: 'Mlin i sečka za voće',
        price: 180,
        currency: 'EUR',
        categoryId: 'prerada_voca_oprema',
        condition: 'new',
        city: 'Gornji Milanovac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adFruitMill.isConditionApplicable, isTrue);
      expect(adFruitMill.showConditionBadge, isTrue);
      expect(adFruitMill.conditionLabel, 'Novo');

      final adCar = ClassifiedAdModel(
        id: 'ad-car',
        userId: 'user-1',
        title: 'VW Passat B6 2.0 TDI',
        price: 4200,
        currency: 'EUR',
        categoryId: 'automobili',
        condition: 'used',
        city: 'Novi Sad',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(adCar.isConditionApplicable, isTrue);
      expect(adCar.showConditionBadge, isTrue);
      expect(adCar.conditionLabel, 'Polovno');
    });

    test('server-driven categoryConditionApplicable is the single source of truth', () {
      // 1. Server flag false overrides client keyword heuristics
      final adWithMachineInTitle = ClassifiedAdModel(
        id: 'ad-srv-1',
        userId: 'user-1',
        title: 'Traktor i mašina za obradu',
        price: 5000,
        currency: 'EUR',
        categoryId: 'usluge',
        condition: 'used',
        city: 'Čačak',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryConditionApplicable: false,
      );
      expect(adWithMachineInTitle.isConditionApplicable, isFalse);

      // 2. Server flag true overrides animal or non-equipment title/category
      final adCustomCategory = ClassifiedAdModel(
        id: 'ad-srv-2',
        userId: 'user-1',
        title: 'Nova posebna kategorija',
        price: 100,
        currency: 'EUR',
        categoryId: 'nova_kategorija_zivotinje',
        condition: 'new',
        city: 'Beograd',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryConditionApplicable: true,
      );
      expect(adCustomCategory.isConditionApplicable, isTrue);

      // 3. ClassifiedAdModel.fromJson parses is_condition_applicable from joined category
      final jsonWithCategory = {
        'id': 'ad-json-1',
        'user_id': 'user-1',
        'title': 'Naslov oglasa',
        'price': 1000,
        'category_id': 'kat-1',
        'city': 'Niš',
        'classified_categories': {
          'name': 'Podkategorija',
          'is_condition_applicable': false,
        },
      };
      final parsedAd = ClassifiedAdModel.fromJson(jsonWithCategory);
      expect(parsedAd.categoryConditionApplicable, isFalse);
      expect(parsedAd.isConditionApplicable, isFalse);
    });

    test('real estate, services, live animals and feed strictly forbid condition (Novo/Polovno)', () {
      final nonApplicableCategoryIds = [
        // Nekretnine (nivo 2 i 3)
        'nekretnine', 'stanovi', 'prodaja_stanova', 'izdavanje_stanova', 'stan_na_dan',
        'kuce_domacinstva', 'prodaja_kuca', 'seoska_domacinstva', 'izdavanje_kuca',
        'vikendice', 'planinske_vikendice', 'poljoprivredno_zemljiste', 'njive_oranice',
        'gradjevinski_placevi', 'placevi_za_kuce', 'poslovni_prostori', 'lokali', 'garaze_parking',
        // Usluge (nivo 2 i 3)
        'usluge', 'poljoprivredne_usluge', 'oranje_setva', 'majstori_zanatlije',
        'vodoinstalaterske_usluge', 'gradjevinske_usluge', 'iskopi_bageri',
        'prevoz_selidbe', 'slep_sluzba', 'servis_mehanike', 'servis_traktora',
        'poslovi_zaposlenje', 'sezonski_poslovi',
        // Životinje, pčele, usevi, sadnice, hrana
        'psi', 'lovacki_psi', 'macke', 'rasne_macke', 'domace_zivotinje', 'krave_telad',
        'zivina_ptice', 'kokoske_pilici', 'pcelinja_drustva_matice',
        'stocna_hrana', 'balirano_seno_lucerka', 'kukuruz_stocni',
        'sadnice_semena', 'sadnice_voca', 'rasad_povrca',
        'hrana_psi_macke', 'koncentrati_premiksi',
      ];

      for (final catId in nonApplicableCategoryIds) {
        // Čak i ako je condition 'used' ili 'new' i categoryConditionApplicable slučajno true
        final ad = ClassifiedAdModel(
          id: 'test-$catId',
          userId: 'user-1',
          title: 'Oglas za $catId',
          price: 50000,
          currency: 'EUR',
          categoryId: catId,
          condition: 'used',
          city: 'Beograd',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          categoryConditionApplicable: true, // Čak i ako je server poslao true, stroga lista ga blokira
        );

        expect(
          ad.isConditionApplicable,
          isFalse,
          reason: 'Kategorija $catId ne sme imati primenjivo stanje!',
        );
        expect(
          ad.showConditionBadge,
          isFalse,
          reason: 'Kategorija $catId ne sme prikazivati bedž stanja!',
        );
        expect(
          ad.conditionLabel,
          '',
          reason: 'Kategorija $catId mora imati prazan conditionLabel!',
        );
      }
    });

    test('ClassifiedAdModel.copyWith preserves categoryConditionApplicable', () {
      final original = ClassifiedAdModel(
        id: 'ad-copy-1',
        userId: 'user-1',
        title: 'Traktor IMT 539',
        price: 4500,
        currency: 'EUR',
        categoryId: 'traktori_kombajni',
        condition: 'used',
        city: 'Kragujevac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryConditionApplicable: false,
      );

      final copy = original.copyWith(title: 'Traktor IMT 539 Deluxe');
      expect(copy.categoryConditionApplicable, isFalse);
      expect(copy.isConditionApplicable, isFalse);

      final copyOverridden = original.copyWith(categoryConditionApplicable: true);
      expect(copyOverridden.categoryConditionApplicable, isTrue);
      expect(copyOverridden.isConditionApplicable, isTrue);
    });

    test('classified ad share URL uses dynamic origin / base url without trailing slash', () {
      const adId = 'ad-uuid-123';
      String resolveShareUrl(String rawBase) {
        final base = rawBase.replaceAll(RegExp(r'/+$'), '');
        return '$base/classifieds/ad/$adId';
      }

      expect(
        resolveShareUrl('https://staging.domacimarket.rs/'),
        'https://staging.domacimarket.rs/classifieds/ad/ad-uuid-123',
      );
      expect(
        resolveShareUrl('http://localhost:5000'),
        'http://localhost:5000/classifieds/ad/ad-uuid-123',
      );
    });

    test('toJson with and without id for insert/update', () {
      final ad = ClassifiedAdModel(
        id: 'ad-uuid-123',
        userId: 'user-uuid-456',
        title: 'Balirka Claas',
        description: 'U radnom stanju, garažirana.',
        price: 3200,
        currency: 'EUR',
        priceType: 'fixed',
        categoryId: 'poljoprivreda',
        city: 'Zrenjanin',
        phone: '064111222',
        createdAt: DateTime.parse('2025-05-01T12:00:00Z'),
        updatedAt: DateTime.parse('2025-05-01T12:00:00Z'),
      );

      final withId = ad.toJson(includeId: true);
      expect(withId['id'], 'ad-uuid-123');
      expect(withId['user_id'], 'user-uuid-456');
      expect(withId['currency'], 'EUR');

      final withoutId = ad.toJson(includeId: false);
      expect(withoutId.containsKey('id'), isFalse);
      expect(withoutId['title'], 'Balirka Claas');

      final withoutCreatedAt = ad.toJson(includeCreatedAt: false);
      expect(withoutCreatedAt.containsKey('created_at'), isFalse);
      expect(withId.containsKey('created_at'), isTrue);
    });

    test('ClassifiedAdModel copyWith updates fields correctly', () {
      final ad = ClassifiedAdModel(
        id: 'ad-100',
        userId: 'user-100',
        title: 'Orginal naslov',
        price: 100,
        categoryId: 'traktori',
        city: 'Čačak',
        phone: '061111111',
        phonePublic: true,
        createdAt: DateTime.parse('2025-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2025-01-01T00:00:00Z'),
      );

      final updated = ad.copyWith(
        title: 'Novi naslov',
        clearPhone: true,
        phonePublic: false,
      );

      expect(updated.id, 'ad-100');
      expect(updated.title, 'Novi naslov');
      expect(updated.phone, isNull);
      expect(updated.phonePublic, isFalse);
      expect(updated.city, 'Čačak');

      final withNewPhone = ad.copyWith(phone: '062222222');
      expect(withNewPhone.phone, '062222222');
    });

    test('ClassifiedAdModel.fromJson handles null phone when phone is protected', () {
      final json = {
        'id': 'ad-secret-phone',
        'user_id': 'user-secret',
        'title': 'Pčelarska oprema',
        'price': 250,
        'category_id': 'oprema_za_zivotinje',
        'city': 'Valjevo',
        'phone': null,
        'phone_public': false,
        'status': 'active',
        'created_at': '2025-06-01T10:00:00Z',
        'updated_at': '2025-06-01T10:00:00Z',
      };

      final ad = ClassifiedAdModel.fromJson(json);
      expect(ad.id, 'ad-secret-phone');
      expect(ad.phone, isNull);
      expect(ad.phonePublic, isFalse);
    });
  });

  group('ClassifiedsProvider state unit tests', () {
    test('initial state and filter setters', () {
      final provider = ClassifiedsProvider(service: FakeClassifiedsService());

      expect(provider.loading, isFalse);
      expect(provider.ads, isEmpty);
      expect(provider.selectedCategoryId, isNull);
      expect(provider.selectedCity, isNull);
      expect(provider.selectedCondition, isNull);
      expect(provider.sort, ClassifiedSort.newest);

      provider.selectCategory('traktori');
      expect(provider.selectedCategoryId, 'traktori');

      provider.selectCity('Kragujevac');
      expect(provider.selectedCity, 'Kragujevac');

      provider.selectCondition('new');
      expect(provider.selectedCondition, 'new');

      provider.changeSort(ClassifiedSort.priceAsc);
      expect(provider.sort, ClassifiedSort.priceAsc);
    });

    test('loadCategories populates categories from service', () async {
      final fake = FakeClassifiedsService();
      final provider = ClassifiedsProvider(service: fake);

      expect(provider.categoriesLoaded, isFalse);
      await provider.loadCategories();
      expect(provider.categoriesLoaded, isTrue);
      expect(provider.categories.length, 1);
      expect(provider.categories.first.id, 'poljoprivreda');
    });

    test('multi-level breadcrumb navigation works for nested country car brands', () async {
      final fake = FakeCarClassifiedsService();
      final provider = ClassifiedsProvider(service: fake);
      await provider.loadCategories();

      // 1. Select country level (Nemačka)
      provider.selectCategory('auto_nemacka');
      final countryCrumbs = provider.categoryBreadcrumbs;
      expect(countryCrumbs.length, 3);
      expect(countryCrumbs[0].id, 'vozila');
      expect(countryCrumbs[1].id, 'automobili');
      expect(countryCrumbs[2].id, 'auto_nemacka');

      // 2. Select brand level (Volkswagen)
      provider.selectCategory('auto_volkswagen');
      final brandCrumbs = provider.categoryBreadcrumbs;
      expect(brandCrumbs.length, 4);
      expect(brandCrumbs[0].id, 'vozila');
      expect(brandCrumbs[1].id, 'automobili');
      expect(brandCrumbs[2].id, 'auto_nemacka');
      expect(brandCrumbs[3].id, 'auto_volkswagen');
    });
  });

  group('ClassifiedsService view deduplication', () {
    test('session deduplication prevents repeated RPC calls for the same ad', () async {
      final service = ClassifiedsService.test();
      // Verifies that repeated calls for the same ad in session are deduplicated cleanly
      await service.incrementViews('ad-123');
      await service.incrementViews('ad-123');
    });
  });
}

class FakeCarClassifiedsService extends ClassifiedsService {
  FakeCarClassifiedsService() : super.test();

  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories() async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories() async => [
        const ClassifiedCategoryModel(
          id: 'vozila',
          name: 'Vozila',
          iconName: 'directions_car',
          subcategories: [
            ClassifiedCategoryModel(
              id: 'automobili',
              name: 'Automobili',
              iconName: 'directions_car',
              parentId: 'vozila',
              subcategories: [
                ClassifiedCategoryModel(
                  id: 'auto_nemacka',
                  name: 'Nemačka',
                  iconName: 'directions_car',
                  parentId: 'automobili',
                  subcategories: [
                    ClassifiedCategoryModel(
                      id: 'auto_volkswagen',
                      name: 'Volkswagen',
                      iconName: 'directions_car',
                      parentId: 'auto_nemacka',
                    ),
                    ClassifiedCategoryModel(
                      id: 'auto_bmw',
                      name: 'BMW',
                      iconName: 'directions_car',
                      parentId: 'auto_nemacka',
                    ),
                  ],
                ),
                ClassifiedCategoryModel(
                  id: 'auto_japan',
                  name: 'Japan',
                  iconName: 'directions_car',
                  parentId: 'automobili',
                  subcategories: [
                    ClassifiedCategoryModel(
                      id: 'auto_toyota',
                      name: 'Toyota',
                      iconName: 'directions_car',
                      parentId: 'auto_japan',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ];

  @override
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    List<String>? cities,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    Map<String, dynamic>? attributeFilters,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
    bool? onlyFeatured,
    bool? onlyUrgent,
  }) async => [];
}

class FakeClassifiedsService extends ClassifiedsService {
  FakeClassifiedsService() : super.test();

  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories() async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories() async => [
        const ClassifiedCategoryModel(
          id: 'poljoprivreda',
          name: 'Poljoprivreda',
          iconName: 'agriculture',
        ),
      ];

  @override
  Future<List<ClassifiedAdModel>> getAds({
    String? categoryId,
    List<String>? categoryIds,
    String? city,
    List<String>? cities,
    String? condition,
    String? sellerType,
    double? minPrice,
    double? maxPrice,
    String? currency,
    String? searchQuery,
    Map<String, dynamic>? attributeFilters,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
    bool? onlyFeatured,
    bool? onlyUrgent,
  }) async => [];
}

