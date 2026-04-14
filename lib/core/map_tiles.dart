import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class AppMapTiles {
  AppMapTiles._();

  static const String _openStreetMapUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _cartoLightUrl =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

  static TileLayer buildTileLayer() {
    return TileLayer(
      urlTemplate: kIsWeb ? _cartoLightUrl : _openStreetMapUrl,
      subdomains: kIsWeb ? const ['a', 'b', 'c', 'd'] : const <String>[],
      userAgentPackageName: 'app.mleko',
      maxZoom: 19,
    );
  }

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
              kIsWeb ? 'Mapa: CARTO / OpenStreetMap' : 'Mapa: OpenStreetMap',
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
