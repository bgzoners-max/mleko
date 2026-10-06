import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../core/location_utils.dart';
import '../services/core/logger_service.dart';

const String _keyRegion = 'mleko_selected_region';
const String _keyLatitude = 'mleko_selected_lat';
const String _keyLongitude = 'mleko_selected_lng';
const String _keyCity = 'mleko_selected_city';

/// Čuva izabranu lokaciju (region, grad, koordinate) – GPS detekcija sa fallbackom na ručni izbor.
class LocationProvider extends ChangeNotifier {
  late final Future<void> _loadFuture;
  Future<void> get loadFuture => _loadFuture;

  LocationProvider() {
    _regionNotifier = ValueNotifier<String?>(_selectedRegion);
    _loadFuture = _loadSaved();
  }

  String? _selectedRegion;
  double? _latitude;
  double? _longitude;
  String? _city;
  late final ValueNotifier<String?> _regionNotifier;

  String? get selectedRegion => _selectedRegion;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get city => _city;
  ValueNotifier<String?> get regionNotifier => _regionNotifier;

  bool _gpsTried = false;
  bool get gpsTried => _gpsTried;

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_keyRegion);
      _latitude = prefs.getDouble(_keyLatitude);
      _longitude = prefs.getDouble(_keyLongitude);
      _city = prefs.getString(_keyCity);
      if (saved != null && AppConstants.regions.contains(saved)) {
        _selectedRegion = saved;
        _regionNotifier.value = saved;
        notifyListeners();
      }
    } catch (e) {
      LoggerService.error('LocationProvider: failed to load saved region', e);
    }
  }

  Future<bool> tryDetectFromGps({bool force = false}) async {
    await _loadFuture;
    if (force) {
      _gpsTried = false;
    } else if (_gpsTried) {
      return _selectedRegion != null;
    }
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
      _latitude = position.latitude;
      _longitude = position.longitude;

      final region = nearestRegionFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (region != null) {
        await setLocation(
          region: region,
          latitude: position.latitude,
          longitude: position.longitude,
          city: _city,
        );
        return true;
      }
    } catch (e) {
      LoggerService.debug('GPS location failed, fallback to manual',
          extra: {'error': e.toString()});
    }
    notifyListeners();
    return false;
  }

  Future<void> setLocation({
    required String region,
    double? latitude,
    double? longitude,
    String? city,
  }) async {
    await _loadFuture;
    if (!AppConstants.regions.contains(region)) return;
    _selectedRegion = region;
    _latitude = latitude;
    _longitude = longitude;
    _city = city;
    _regionNotifier.value = region;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyRegion, region);
      if (latitude != null) {
        await prefs.setDouble(_keyLatitude, latitude);
      } else {
        await prefs.remove(_keyLatitude);
      }
      if (longitude != null) {
        await prefs.setDouble(_keyLongitude, longitude);
      } else {
        await prefs.remove(_keyLongitude);
      }
      if (city != null && city.isNotEmpty) {
        await prefs.setString(_keyCity, city);
      } else {
        await prefs.remove(_keyCity);
      }
    } catch (e) {
      LoggerService.error('LocationProvider: failed to save location', e);
    }
  }

  Future<void> setRegion(String region) => setLocation(
        region: region,
        latitude: _latitude,
        longitude: _longitude,
        city: _city,
      );

  Future<void> clearRegion() async {
    await _loadFuture;
    _selectedRegion = null;
    _latitude = null;
    _longitude = null;
    _city = null;
    _regionNotifier.value = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRegion);
      await prefs.remove(_keyLatitude);
      await prefs.remove(_keyLongitude);
      await prefs.remove(_keyCity);
    } catch (e) {
      LoggerService.error('LocationProvider: failed to clear region', e);
    }
  }

  @override
  void dispose() {
    _regionNotifier.dispose();
    super.dispose();
  }
}
