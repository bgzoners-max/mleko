import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../constants/amazon_theme.dart';

class AppMapTiles {
  AppMapTiles._();

  static const String _openStreetMapUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String serbiaContourAssetPath =
      'assets/geojson/serbia_contour.geojson';

  static Future<List<LatLng>>? _serbiaContourFuture;
  static List<LatLng>? _cachedSerbiaContour;

  static List<LatLng>? get cachedContourPoints => _cachedSerbiaContour;

  static Future<List<LatLng>> loadSerbiaContourPoints() {
    return _serbiaContourFuture ??= _readSerbiaContourFromAsset();
  }

  /// Omogućava testovima da učitaju ili resetuju keširanu konturu bez oslanjanja na prethodno stanje.
  @visibleForTesting
  static void resetContourCacheForTesting() {
    _serbiaContourFuture = null;
    _cachedSerbiaContour = null;
  }

  static List<LatLng> parseSerbiaContourGeoJson(String rawJson) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final features = decoded['features'] as List<dynamic>;
    if (features.isEmpty) return const [];
    final geometry =
        (features.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>;
    final type = geometry['type'] as String?;
    final coords = geometry['coordinates'] as List<dynamic>;

    final List<dynamic> outerRing;
    if (type == 'Polygon' && coords.isNotEmpty) {
      outerRing = coords.first as List<dynamic>;
    } else if (type == 'MultiPolygon' && coords.isNotEmpty) {
      final firstPolygon = coords.first as List<dynamic>;
      outerRing = firstPolygon.isNotEmpty
          ? firstPolygon.first as List<dynamic>
          : const [];
    } else {
      return const [];
    }

    return outerRing
        .map((pair) {
          final tuple = pair as List<dynamic>;
          final lng = (tuple[0] as num).toDouble();
          final lat = (tuple[1] as num).toDouble();
          return LatLng(lat, lng);
        })
        .toList(growable: false);
  }

  static Future<List<LatLng>> _readSerbiaContourFromAsset() async {
    try {
      final raw = await rootBundle.loadString(serbiaContourAssetPath);
      final parsed = parseSerbiaContourGeoJson(raw);
      _cachedSerbiaContour = parsed;
      return parsed;
    } catch (_) {
      return const [];
    }
  }

  static TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: _openStreetMapUrl,
      userAgentPackageName: 'app.mleko',
      maxZoom: 19,
    );
  }

  static Widget buildSerbiaBorderLayer() => const _SerbiaContourLayer();

  static Widget buildAttribution() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Mapa: OpenStreetMap',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SerbiaContourLayer extends StatelessWidget {
  const _SerbiaContourLayer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AmazonColors.lightGreen : const Color(0xFF1B5E20);
    final fillColor =
        AmazonColors.green.withValues(alpha: isDark ? 0.08 : 0.05);

    return FutureBuilder<List<LatLng>>(
      initialData: AppMapTiles.cachedContourPoints,
      future: AppMapTiles.loadSerbiaContourPoints(),
      builder: (context, snapshot) {
        final points = snapshot.data;
        if (points == null || points.isEmpty) {
          return const SizedBox.shrink();
        }
        return PolygonLayer(
          polygons: [
            Polygon(
              points: points,
              color: fillColor,
              borderColor: borderColor,
              borderStrokeWidth: 2.2,
            ),
          ],
        );
      },
    );
  }
}
