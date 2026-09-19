import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/location_utils.dart';

void main() {
  group('nearestRegionFromCoordinates', () {
    test('vraća Beograd za centar Beograda', () {
      expect(nearestRegionFromCoordinates(44.8178, 20.4569), 'Beograd');
    });

    test('vraća Vojvodinu za Novi Sad', () {
      expect(nearestRegionFromCoordinates(45.2671, 19.8335), 'Vojvodina');
    });

    test('vraća Južnu Srbiju za Niš', () {
      expect(nearestRegionFromCoordinates(43.3209, 21.8958), 'Južna Srbija');
    });

    test('vraća Zapadnu Srbiju za Užice', () {
      expect(nearestRegionFromCoordinates(43.8558, 19.8411), 'Zapadna Srbija');
    });

    test('vraća Šumadiju za Kragujevac', () {
      expect(nearestRegionFromCoordinates(44.0128, 20.9114), 'Šumadija');
    });
  });
}
