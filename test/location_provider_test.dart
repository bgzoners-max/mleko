import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/core/location_utils.dart';
import 'package:mleko/providers/location_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationUtils', () {
    test('nearestRegionFromCoordinates maps coordinates to closest Serbian region', () {
      // Novi Sad (45.26, 19.83) -> Vojvodina
      expect(nearestRegionFromCoordinates(45.26, 19.83), 'Vojvodina');

      // Beograd centar (44.81, 20.46) -> Beograd
      expect(nearestRegionFromCoordinates(44.81, 20.46), 'Beograd');

      // Kragujevac (44.01, 20.91) -> Šumadija
      expect(nearestRegionFromCoordinates(44.01, 20.91), 'Šumadija');

      // Niš (43.32, 21.89) -> Južna Srbija
      expect(nearestRegionFromCoordinates(43.32, 21.89), 'Južna Srbija');

      // Užice (43.85, 19.84) -> Zapadna Srbija
      expect(nearestRegionFromCoordinates(43.85, 19.84), 'Zapadna Srbija');

      // Zaječar (43.90, 22.27) -> Istočna Srbija
      expect(nearestRegionFromCoordinates(43.90, 22.27), 'Istočna Srbija');
    });
  });

  group('LocationProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sets, saves and clears region correctly', () async {
      final provider = LocationProvider();

      expect(provider.selectedRegion, isNull);
      expect(provider.regionNotifier.value, isNull);

      await provider.setRegion('Beograd');
      expect(provider.selectedRegion, 'Beograd');
      expect(provider.regionNotifier.value, 'Beograd');

      // Ignoriše nepoznat region
      await provider.setRegion('NepoznatRegion123');
      expect(provider.selectedRegion, 'Beograd');

      await provider.clearRegion();
      expect(provider.selectedRegion, isNull);
      expect(provider.regionNotifier.value, isNull);

      provider.dispose();
    });

    test('loads saved region from SharedPreferences on initialization', () async {
      SharedPreferences.setMockInitialValues({
        'mleko_selected_region': 'Vojvodina',
      });

      final provider = LocationProvider();
      // Sačekaj da _loadSaved završi
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(provider.selectedRegion, 'Vojvodina');
      expect(provider.regionNotifier.value, 'Vojvodina');

      provider.dispose();
    });
  });
}
