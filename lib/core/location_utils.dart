import 'dart:math' show asin, cos, sqrt;

import 'constants.dart';

/// Približne koordinate centara regiona (Srbija) za mapiranje GPS → region.
final Map<String, ({double lat, double lng})> _regionCenters = {
  'Vojvodina': (lat: 45.2, lng: 19.8),
  'Šumadija': (lat: 44.0, lng: 20.9),
  'Beograd': (lat: 44.8, lng: 20.5),
  'Južna Srbija': (lat: 43.0, lng: 21.9),
  'Istočna Srbija': (lat: 44.2, lng: 22.0),
  'Zapadna Srbija': (lat: 43.8, lng: 20.0),
};

/// Vraća najbliži region na osnovu lat/lng (Haversine približno).
String? nearestRegionFromCoordinates(double lat, double lng) {
  if (!AppConstants.regions.contains('Vojvodina')) return null;
  String? nearest;
  double minDist = double.infinity;
  for (final entry in _regionCenters.entries) {
    final d = _haversineKm(
      lat,
      lng,
      entry.value.lat,
      entry.value.lng,
    );
    if (d < minDist) {
      minDist = d;
      nearest = entry.key;
    }
  }
  return nearest;
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const p = 0.017453292519943295; // pi/180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2*R*asin (R=6371 km)
}
