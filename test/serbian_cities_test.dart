import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/constants/serbian_cities.dart';

void main() {
  group('SerbianCities', () {
    test('all contains major Serbian cities', () {
      expect(SerbianCities.all, contains('Beograd'));
      expect(SerbianCities.all, contains('Novi Sad'));
      expect(SerbianCities.all, contains('Čačak'));
      expect(SerbianCities.all, contains('Niš'));
      expect(SerbianCities.all, contains('Kragujevac'));
    });

    test('normalize canonicalizes known cities with various casings and accents', () {
      expect(SerbianCities.normalize('beograd'), 'Beograd');
      expect(SerbianCities.normalize('BEOGRAD'), 'Beograd');
      expect(SerbianCities.normalize('  beograd  '), 'Beograd');
      expect(SerbianCities.normalize('cacak'), 'Čačak');
      expect(SerbianCities.normalize('Čačak'), 'Čačak');
      expect(SerbianCities.normalize('nis'), 'Niš');
      expect(SerbianCities.normalize('sabac'), 'Šabac');
      expect(SerbianCities.normalize('novi sad'), 'Novi Sad');
      expect(SerbianCities.normalize('NOVI SAD'), 'Novi Sad');
      expect(SerbianCities.normalize('sremska mitrovica'), 'Sremska Mitrovica');
      expect(SerbianCities.normalize('krusevac'), 'Kruševac');
      expect(SerbianCities.normalize('uzice'), 'Užice');
    });

    test('normalize title-cases unknown custom places and villages', () {
      expect(SerbianCities.normalize('bela crkva'), 'Bela Crkva');
      expect(SerbianCities.normalize('donja trepca'), 'Donja Trepca');
      expect(SerbianCities.normalize('mrcajevci'), 'Mrcajevci');
      expect(SerbianCities.normalize(''), '');
    });

    test('suggestions filters correctly with and without diacritics', () {
      final res1 = SerbianCities.suggestions('beo');
      expect(res1, contains('Beograd'));

      final res2 = SerbianCities.suggestions('cac');
      expect(res2, contains('Čačak'));

      final res3 = SerbianCities.suggestions('čač');
      expect(res3, contains('Čačak'));
    });
  });
}
