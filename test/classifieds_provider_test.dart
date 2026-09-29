import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/constants/serbian_districts.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/models/classified_subscription_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/services/classifieds/classified_subscriptions_service.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';

class FakeClassifiedsService implements ClassifiedsService {
  List<ClassifiedCategoryModel> categoriesToReturn = [];
  Map<String, int> countsToReturn = {};
  List<ClassifiedAdModel> adsToReturn = [];

  // Captured query params from the last getAds call
  String? lastCategoryId;
  List<String>? lastCategoryIds;
  String? lastCity;
  List<String>? lastCities;
  double? lastMinPrice;
  double? lastMaxPrice;
  String? lastCondition;
  String? lastSellerType;
  String? lastSearchQuery;
  Map<String, dynamic>? lastAttributeFilters;
  bool? lastOnlyFeatured;
  bool? lastOnlyUrgent;
  ClassifiedSort? lastSort;

  Completer<List<ClassifiedAdModel>>? controlledCompleter;

  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories() async => categoriesToReturn;

  @override
  Future<List<ClassifiedCategoryModel>> getCategories() async => categoriesToReturn;

  @override
  Future<Map<String, int>> getCategoryAdCounts() async => countsToReturn;

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
    bool? onlyFeatured,
    bool? onlyUrgent,
    ClassifiedSort sort = ClassifiedSort.newest,
    int limit = 24,
    int offset = 0,
    DateTime? lastCreatedAt,
  }) async {
    lastCategoryId = categoryId;
    lastCategoryIds = categoryIds;
    lastCity = city;
    lastCities = cities;
    lastMinPrice = minPrice;
    lastMaxPrice = maxPrice;
    lastCondition = condition;
    lastSellerType = sellerType;
    lastSearchQuery = searchQuery;
    lastAttributeFilters = attributeFilters;
    lastOnlyFeatured = onlyFeatured;
    lastOnlyUrgent = onlyUrgent;
    lastSort = sort;

    if (controlledCompleter != null) {
      return controlledCompleter!.future;
    }
    return adsToReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSubscriptionsService implements ClassifiedSubscriptionsService {
  List<ClassifiedSubscriptionModel> subsToReturn = [];

  @override
  Future<List<ClassifiedSubscriptionModel>> getSubscriptions() async => subsToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeClassifiedsService fakeService;
  late FakeSubscriptionsService fakeSubService;
  late ClassifiedsProvider provider;

  final List<ClassifiedCategoryModel> sampleTree = const [
    ClassifiedCategoryModel(
      id: 'automobili',
      name: 'Automobili',
      iconName: 'directions_car',
      sortOrder: 1,
      isConditionApplicable: true,
      subcategories: [
        ClassifiedCategoryModel(
          id: 'auto-nemacki',
          name: 'Nemačka vozila',
          iconName: 'directions_car',
          sortOrder: 1,
          isConditionApplicable: true,
          subcategories: [
            ClassifiedCategoryModel(
              id: 'audi',
              name: 'Audi',
              iconName: 'directions_car',
              sortOrder: 1,
              isConditionApplicable: true,
            ),
            ClassifiedCategoryModel(
              id: 'bmw',
              name: 'BMW',
              iconName: 'directions_car',
              sortOrder: 2,
              isConditionApplicable: true,
            ),
          ],
        ),
      ],
    ),
    ClassifiedCategoryModel(
      id: 'stoka',
      name: 'Domaće životinje',
      iconName: 'pets',
      sortOrder: 2,
      isConditionApplicable: false, // Condition 'Novo/Polovno' not applicable
    ),
  ];

  setUp(() {
    fakeService = FakeClassifiedsService();
    fakeSubService = FakeSubscriptionsService();
    fakeService.categoriesToReturn = List.from(sampleTree);
    provider = ClassifiedsProvider(
      service: fakeService,
      subscriptionService: fakeSubService,
    );
  });

  group('ClassifiedsProvider Search & Category Subtree Resolution', () {
    test('selecting parent category resolves all descendant IDs for query', () async {
      await provider.loadCategories();
      expect(provider.categoriesLoaded, isTrue);

      // Select root 'automobili' -> must resolve ['automobili', 'auto-nemacki', 'audi', 'bmw']
      provider.selectCategory('automobili');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCategoryId, equals('automobili'));
      expect(fakeService.lastCategoryIds, isNotNull);
      expect(fakeService.lastCategoryIds, containsAll(['automobili', 'auto-nemacki', 'audi', 'bmw']));
    });

    test('selecting leaf category passes only the leaf category ID', () async {
      await provider.loadCategories();
      provider.selectCategory('audi');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCategoryId, equals('audi'));
      expect(fakeService.lastCategoryIds, equals(['audi']));
    });

    test('categoryBreadcrumbs returns accurate hierarchical path', () async {
      await provider.loadCategories();
      provider.selectCategory('audi');

      final crumbs = provider.categoryBreadcrumbs;
      expect(crumbs.length, equals(3));
      expect(crumbs[0].id, equals('automobili'));
      expect(crumbs[1].id, equals('auto-nemacki'));
      expect(crumbs[2].id, equals('audi'));

      expect(provider.activeRootCategory?.id, equals('automobili'));
      expect(provider.activeSecondaryCategory?.id, equals('auto-nemacki'));
      expect(provider.activeTertiaryCategory?.id, equals('audi'));
    });
  });

  group('ClassifiedsProvider City & District Filtering', () {
    test('selectDistrict maps cities through SerbianDistricts and clears city', () async {
      provider.selectCity('Beograd');
      expect(provider.selectedCity, equals('Beograd'));
      expect(provider.selectedDistrict, isNull);

      final district = SerbianDistricts.all.first; // e.g. Severnobački
      provider.selectDistrict(district.id);
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedDistrict, equals(district.id));
      expect(provider.selectedCity, isNull);
      expect(fakeService.lastCity, isNull);
      expect(fakeService.lastCities, equals(district.cities));
    });

    test('selectCity clears district and passes city', () async {
      provider.selectDistrict('juznobacki');
      expect(provider.selectedDistrict, equals('juznobacki'));

      provider.selectCity('Novi Sad');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCity, equals('Novi Sad'));
      expect(provider.selectedDistrict, isNull);
      expect(fakeService.lastCity, equals('Novi Sad'));
      expect(fakeService.lastCities, isNull);
    });
  });

  group('ClassifiedsProvider Condition Applicability', () {
    test('condition is automatically cleared when category does not support conditions', () async {
      await provider.loadCategories();

      // Step 1: select category that supports condition and pick condition
      provider.selectCategory('automobili');
      provider.selectCondition('Polovno');
      expect(provider.selectedCondition, equals('Polovno'));
      expect(provider.isConditionApplicableForSelectedCategory, isTrue);

      // Step 2: switch to category where isConditionApplicable is false
      provider.selectCategory('stoka');
      expect(provider.isConditionApplicableForSelectedCategory, isFalse);
      expect(provider.selectedCondition, isNull);
    });
  });

  group('ClassifiedsProvider Dynamic Attribute Filters & Clearing', () {
    test('setAttributeFilter adds and updates attributes', () async {
      provider.setAttributeFilter('fuel', 'Dizel');
      provider.setAttributeFilter('transmission', 'Manuelni');
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedAttributes['fuel'], equals('Dizel'));
      expect(provider.selectedAttributes['transmission'], equals('Manuelni'));
      expect(fakeService.lastAttributeFilters?['fuel'], equals('Dizel'));

      // Setting empty or whitespace value removes key
      provider.setAttributeFilter('fuel', '   ');
      expect(provider.selectedAttributes.containsKey('fuel'), isFalse);

      // removeAttributeFilter removes specified key
      provider.removeAttributeFilter('transmission');
      expect(provider.selectedAttributes.isEmpty, isTrue);
    });

    test('clearAttributeFilters clears attributes and resets featured/urgent filters', () async {
      provider.setAttributeFilter('brand', 'VW');
      provider.setOnlyFeatured(true);
      provider.setOnlyUrgent(true);

      provider.clearAttributeFilters();
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedAttributes.isEmpty, isTrue);
      expect(provider.onlyFeatured, isFalse);
      expect(provider.onlyUrgent, isFalse);
    });

    test('clearAllFilters resets all search and filter properties', () async {
      provider.selectCategory('automobili');
      provider.selectCity('Nis');
      provider.selectCondition('Novo');
      provider.search('gume');
      provider.setPriceRange(minPrice: 100, maxPrice: 5000);
      provider.setAttributeFilter('color', 'Crvena');
      provider.setOnlyFeatured(true);

      provider.clearAllFilters();
      await Future<void>.delayed(Duration.zero);

      expect(provider.selectedCategoryId, isNull);
      expect(provider.selectedCity, isNull);
      expect(provider.selectedDistrict, isNull);
      expect(provider.selectedCondition, isNull);
      expect(provider.searchQuery, isNull);
      expect(provider.minPrice, isNull);
      expect(provider.maxPrice, isNull);
      expect(provider.selectedAttributes.isEmpty, isTrue);
      expect(provider.onlyFeatured, isFalse);
      expect(provider.onlyUrgent, isFalse);
    });
  });

  group('ClassifiedsProvider Race Condition Safety', () {
    test('out-of-order query responses do not overwrite newer state', () async {
      final comp1 = Completer<List<ClassifiedAdModel>>();
      final comp2 = Completer<List<ClassifiedAdModel>>();

      final now = DateTime.now();
      final ad1 = ClassifiedAdModel(
        id: 'ad-first',
        userId: 's1',
        categoryId: 'automobili',
        title: 'Prvi oglas',
        description: 'Desc',
        price: 100,
        currency: 'EUR',
        priceType: 'fixed',
        status: 'active',
        city: 'Beograd',
        createdAt: now,
        updatedAt: now,
      );

      final ad2 = ClassifiedAdModel(
        id: 'ad-second',
        userId: 's2',
        categoryId: 'automobili',
        title: 'Drugi oglas',
        description: 'Desc',
        price: 200,
        currency: 'EUR',
        priceType: 'fixed',
        status: 'active',
        city: 'Novi Sad',
        createdAt: now,
        updatedAt: now,
      );

      // Start request 1 with comp1
      fakeService.controlledCompleter = comp1;
      provider.search('jabuke');

      // Start request 2 with comp2 (superseding request 1)
      fakeService.controlledCompleter = comp2;
      provider.search('kruske');

      // Request 2 finishes first!
      comp2.complete([ad2]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.ads.length, equals(1));
      expect(provider.ads.first.id, equals('ad-second'));

      // Request 1 finishes later! Must be discarded.
      comp1.complete([ad1]);
      await Future<void>.delayed(Duration.zero);

      // Provider ads must still only contain ad2!
      expect(provider.ads.length, equals(1));
      expect(provider.ads.first.id, equals('ad-second'));
    });
  });

  group('ClassifiedsProvider Tree Ad Count Rollup', () {
    test('applyAdCountsToTree aggregates subcategory counts up to ancestors', () {
      final directCounts = {
        'audi': 5,
        'bmw': 7,
        'auto-nemacki': 2, // 2 direct + (5 + 7) from children = 14
        'automobili': 3, // 3 direct + 14 from subcategories = 17
        'stoka': 4,
      };

      final updated = ClassifiedsProvider.applyAdCountsToTree(sampleTree, directCounts);

      final auto = updated.firstWhere((c) => c.id == 'automobili');
      final autoNemacki = auto.subcategories.firstWhere((c) => c.id == 'auto-nemacki');
      final audi = autoNemacki.subcategories.firstWhere((c) => c.id == 'audi');
      final bmw = autoNemacki.subcategories.firstWhere((c) => c.id == 'bmw');
      final stoka = updated.firstWhere((c) => c.id == 'stoka');

      expect(audi.adCount, equals(5));
      expect(bmw.adCount, equals(7));
      expect(autoNemacki.adCount, equals(14));
      expect(auto.adCount, equals(17));
      expect(stoka.adCount, equals(4));
    });
  });
}
