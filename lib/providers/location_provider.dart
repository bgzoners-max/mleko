import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/location_utils.dart';
import '../services/core/logger_service.dart';

const String _keyRegion = 'mleko_selected_region';

/// Čuva izabranu lokaciju (region) – GPS automatska detekcija sa fallback na ručni izbor.
class LocationProvider extends ChangeNotifier {
  LocationProvider() {
    _regionNotifier = ValueNotifier<String?>(_selectedRegion);
    _loadSaved();
  }

  String? _selectedRegion;
  late final ValueNotifier<String?> _regionNotifier;

  String? get selectedRegion => _selectedRegion;
  ValueNotifier<String?> get regionNotifier => _regionNotifier;

  bool _gpsTried = false;
  bool get gpsTried => _gpsTried;

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyRegion);
      if (saved != null && AppConstants.regions.contains(saved)) {
        _selectedRegion = saved;
        _regionNotifier.value = saved;
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('LocationProvider: failed to load saved region', e);
    }
  }

  Future<bool> tryDetectFromGps() async {
    if (_gpsTried) return _selectedRegion != null;
    _gpsTried = true;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          notifyListeners();
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final region = nearestRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (region != null) {
        await setRegion(region);
        return true;
      }
    } catch (e) {
      LoggerService.debug('GPS location failed, fallback to manual',
          extra: {'error': e.toString()});
    }
    notifyListeners();
    return false;
  }

  Future<void> setRegion(String region) async {
    if (region == _selectedRegion) return;
    if (!AppConstants.regions.contains(region)) return;
    _selectedRegion = region;
    _regionNotifier.value = region;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRegion, region);
    } catch (e) {
      LoggerService.error('LocationProvider: failed to save region', e);
    }
  }

  void clearRegion() {
    _selectedRegion = null;
    _regionNotifier.value = null;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_keyRegion));
  }
}
