import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/models/category_attribute_model.dart';
import 'package:mleko/utils/classified_attributes_engine.dart';

void main() {
  group('CategoryAttribute & ClassifiedAttributesEngine Decimal Config Tests', () {
    test('carAttributes have isDecimal == false for integer-only specs', () {
      final carAttrs = ClassifiedAttributesEngine.carAttributes;

      final year = carAttrs.firstWhere((a) => a.key == 'year');
      expect(year.type, equals(AttributeType.number));
      expect(year.isDecimal, isFalse);

      final mileage = carAttrs.firstWhere((a) => a.key == 'mileage');
      expect(mileage.type, equals(AttributeType.number));
      expect(mileage.isDecimal, isFalse);

      final cubicCapacity = carAttrs.firstWhere((a) => a.key == 'cubic_capacity');
      expect(cubicCapacity.type, equals(AttributeType.number));
      expect(cubicCapacity.isDecimal, isFalse);

      final powerHp = carAttrs.firstWhere((a) => a.key == 'power_hp');
      expect(powerHp.type, equals(AttributeType.number));
      expect(powerHp.isDecimal, isFalse);
    });

    test('tractorAttributes have isDecimal == false for integer-only specs', () {
      final tractorAttrs = ClassifiedAttributesEngine.tractorAttributes;

      final year = tractorAttrs.firstWhere((a) => a.key == 'year');
      expect(year.type, equals(AttributeType.number));
      expect(year.isDecimal, isFalse);

      final operatingHours = tractorAttrs.firstWhere((a) => a.key == 'operating_hours');
      expect(operatingHours.type, equals(AttributeType.number));
      expect(operatingHours.isDecimal, isFalse);

      final enginePower = tractorAttrs.firstWhere((a) => a.key == 'engine_power_hp');
      expect(enginePower.type, equals(AttributeType.number));
      expect(enginePower.isDecimal, isFalse);
    });

    test('realEstateApartmentAttributes have isDecimal == true for area_m2', () {
      final apartmentAttrs = ClassifiedAttributesEngine.realEstateApartmentAttributes;

      final area = apartmentAttrs.firstWhere((a) => a.key == 'area_m2');
      expect(area.type, equals(AttributeType.number));
      expect(area.isDecimal, isTrue);
    });

    test('realEstateHouseAttributes have isDecimal == true for area_m2 and land_area_ari', () {
      final houseAttrs = ClassifiedAttributesEngine.realEstateHouseAttributes;

      final area = houseAttrs.firstWhere((a) => a.key == 'area_m2');
      expect(area.type, equals(AttributeType.number));
      expect(area.isDecimal, isTrue);

      final landArea = houseAttrs.firstWhere((a) => a.key == 'land_area_ari');
      expect(landArea.type, equals(AttributeType.number));
      expect(landArea.isDecimal, isTrue);
    });

    test('realEstateLandAttributes have isDecimal == true for land_area_ari', () {
      final landAttrs = ClassifiedAttributesEngine.realEstateLandAttributes;

      final landArea = landAttrs.firstWhere((a) => a.key == 'land_area_ari');
      expect(landArea.type, equals(AttributeType.number));
      expect(landArea.isDecimal, isTrue);
    });

    test('CategoryAttribute default isDecimal is false', () {
      const customAttr = CategoryAttribute(
        key: 'custom_count',
        label: 'Broj komada',
        type: AttributeType.number,
      );
      expect(customAttr.isDecimal, isFalse);
    });
  });
}
