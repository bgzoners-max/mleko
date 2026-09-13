import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/classified_category_model.dart';
import 'package:mleko/providers/classifieds_provider.dart';

void main() {
  group('ClassifiedCategoryModel adCount and new brand assets', () {
    test('serializes and deserializes adCount correctly', () {
      final json = {
        'id': 'automobili',
        'name': 'Automobili',
        'icon_name': 'directions_car',
        'ad_count': 42,
      };

      final cat = ClassifiedCategoryModel.fromJson(json);
      expect(cat.adCount, 42);

      final serialized = cat.toJson();
      expect(serialized['ad_count'], 42);

      final copied = cat.copyWith(adCount: 99);
      expect(copied.adCount, 99);
    });

    test('brandLogoAsset returns correct paths for phone brands', () {
      const apple = ClassifiedCategoryModel(
        id: 'apple',
        name: 'Apple',
        iconName: 'smartphone',
      );
      expect(apple.brandLogoAsset, 'assets/images/phone_brands/apple.png');

      const samsung = ClassifiedCategoryModel(
        id: 'samsung',
        name: 'Samsung',
        iconName: 'smartphone',
      );
      expect(samsung.brandLogoAsset, 'assets/images/phone_brands/samsung.png');

      const xiaomi = ClassifiedCategoryModel(
        id: 'xiaomi',
        name: 'Xiaomi',
        iconName: 'smartphone',
      );
      expect(xiaomi.brandLogoAsset, 'assets/images/phone_brands/xiaomi.png');
    });

    test('brandLogoAsset returns correct paths for tractor brands', () {
      const imt = ClassifiedCategoryModel(
        id: 'traktori_imt_imr',
        name: 'Traktori IMT',
        iconName: 'agriculture',
      );
      expect(imt.brandLogoAsset, 'assets/images/tractor_brands/traktori_imt_imr.png');

      const jd = ClassifiedCategoryModel(
        id: 'traktori_zapadni',
        name: 'John Deere',
        iconName: 'agriculture',
      );
      expect(jd.brandLogoAsset, 'assets/images/tractor_brands/traktori_zapadni.png');
    });
  });

  group('ClassifiedsProvider.applyAdCountsToTree', () {
    test('recursively calculates roll-up ad counts from leaves to root', () {
      final tree = [
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
                  id: 'auto_volkswagen',
                  name: 'Volkswagen',
                  iconName: 'directions_car',
                  parentId: 'automobili',
                ),
                ClassifiedCategoryModel(
                  id: 'auto_bmw',
                  name: 'BMW',
                  iconName: 'directions_car',
                  parentId: 'automobili',
                ),
              ],
            ),
            ClassifiedCategoryModel(
              id: 'motocikli',
              name: 'Motocikli',
              iconName: 'two_wheeler',
              parentId: 'vozila',
            ),
          ],
        ),
      ];

      final directCounts = {
        'auto_volkswagen': 5,
        'auto_bmw': 3,
        'automobili': 2,
        'motocikli': 4,
      };

      final updatedTree = ClassifiedsProvider.applyAdCountsToTree(tree, directCounts);

      final vozila = updatedTree.first;
      final automobili = vozila.subcategories.firstWhere((c) => c.id == 'automobili');
      final vw = automobili.subcategories.firstWhere((c) => c.id == 'auto_volkswagen');
      final bmw = automobili.subcategories.firstWhere((c) => c.id == 'auto_bmw');
      final motocikli = vozila.subcategories.firstWhere((c) => c.id == 'motocikli');

      expect(vw.adCount, 5);
      expect(bmw.adCount, 3);
      // automobili: 2 direct + 5 (vw) + 3 (bmw) = 10
      expect(automobili.adCount, 10);
      // motocikli: 4 direct
      expect(motocikli.adCount, 4);
      // vozila: 0 direct + 10 (automobili) + 4 (motocikli) = 14
      expect(vozila.adCount, 14);
    });
  });
}
