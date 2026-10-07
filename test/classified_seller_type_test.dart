import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_ad_model.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';
import 'package:mleko/services/classifieds/classifieds_service.dart';

class _MockClassifiedsService extends ClassifiedsService {
  _MockClassifiedsService() : super.test();

  String? lastSellerType;
  int getAdsCallsCount = 0;

  @override
  Future<List<ClassifiedCategoryModel>> getCachedCategories({bool allowExpired = true}) async => [];

  @override
  Future<List<ClassifiedCategoryModel>> getCategories({bool forceRefresh = false}) async => [];

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
    lastSellerType = sellerType;
    getAdsCallsCount++;
    return [];
  }
}

void main() {
  group('ClassifiedAdModel - Seller Type (Zakon o zaštiti potrošača)', () {
    test('Default sellerType is individual', () {
      final ad = ClassifiedAdModel(
        id: 'ad-1',
        userId: 'user-1',
        title: 'Traktor IMT 539',
        price: 3500,
        categoryId: 'traktori',
        city: 'Kragujevac',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(ad.sellerType, equals('individual'));
      expect(ad.isIndividualSeller, isTrue);
      expect(ad.isBusinessSeller, isFalse);
      expect(ad.sellerTypeLabel, equals('Fizičko lice'));
      expect(ad.sellerTypeBadgeText, equals('Fizičko lice'));
      expect(ad.sellerTypeLegalDisclaimer, contains('Na kupovinu od fizičkog lica'));
    });

    test('Business sellerType sets labels and disclaimers correctly', () {
      final ad = ClassifiedAdModel(
        id: 'ad-2',
        userId: 'biz-1',
        title: 'Nove gume za traktor',
        price: 15000,
        categoryId: 'delovi',
        city: 'Novi Sad',
        sellerType: 'business',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(ad.sellerType, equals('business'));
      expect(ad.isBusinessSeller, isTrue);
      expect(ad.isIndividualSeller, isFalse);
      expect(ad.sellerTypeLabel, equals('Pravno lice / Trgovac'));
      expect(ad.sellerTypeBadgeText, equals('Trgovac'));
      expect(ad.sellerTypeLegalDisclaimer, contains('Oglašivač je registrovan trgovac'));
    });

    test('fromJson parses seller_type and defaults to individual if missing', () {
      final jsonWithBusiness = {
        'id': 'ad-10',
        'user_id': 'u-1',
        'title': 'Test oglas',
        'price': 100,
        'category_id': 'cat-1',
        'city': 'Beograd',
        'seller_type': 'business',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final adBiz = ClassifiedAdModel.fromJson(jsonWithBusiness);
      expect(adBiz.sellerType, equals('business'));
      expect(adBiz.isBusinessSeller, isTrue);

      final jsonWithoutSellerType = {
        'id': 'ad-11',
        'user_id': 'u-1',
        'title': 'Test oglas 2',
        'price': 200,
        'category_id': 'cat-1',
        'city': 'Niš',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final adInd = ClassifiedAdModel.fromJson(jsonWithoutSellerType);
      expect(adInd.sellerType, equals('individual'));
      expect(adInd.isIndividualSeller, isTrue);
    });

    test('toJson includes seller_type', () {
      final ad = ClassifiedAdModel(
        id: 'ad-3',
        userId: 'biz-2',
        title: 'Motokultivator',
        price: 800,
        categoryId: 'masine',
        city: 'Kraljevo',
        sellerType: 'business',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = ad.toJson();
      expect(json['seller_type'], equals('business'));
    });

    test('copyWith updates or preserves sellerType', () {
      final ad = ClassifiedAdModel(
        id: 'ad-4',
        userId: 'u-1',
        title: 'Bicikl',
        price: 50,
        categoryId: 'sport',
        city: 'Subotica',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(ad.sellerType, equals('individual'));

      final updated = ad.copyWith(sellerType: 'business');
      expect(updated.sellerType, equals('business'));

      final preserved = updated.copyWith(title: 'Bicikl aluminijumski');
      expect(preserved.sellerType, equals('business'));
    });
  });

  group('ClassifiedsProvider - Seller Type filter', () {
    test('selectSellerType updates filter and triggers getAds with sellerType', () async {
      final service = _MockClassifiedsService();
      final provider = ClassifiedsProvider(service: service);

      expect(provider.selectedSellerType, isNull);

      provider.selectSellerType('business');
      expect(provider.selectedSellerType, equals('business'));
      await Future<void>.delayed(Duration.zero);
      expect(service.lastSellerType, equals('business'));

      provider.selectSellerType('individual');
      expect(provider.selectedSellerType, equals('individual'));
      await Future<void>.delayed(Duration.zero);
      expect(service.lastSellerType, equals('individual'));

      provider.clearFilters();
      expect(provider.selectedSellerType, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(service.lastSellerType, isNull);
    });
  });
}
