import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mleko/core/map_tiles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppMapTiles.resetContourCacheForTesting();
  });

  test('serbia_contour.geojson se ucitava i obuhvata celu Srbiju ukljucujuci KiM',
      () async {
    final points = await AppMapTiles.loadSerbiaContourPoints();

    expect(points.length, greaterThan(1000));

    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    // Najjuznija tacka sa KiM (Dragas/Restelica ~41.85N) je niza od 42.23N
    expect(minLat, lessThan(42.0));
    expect(maxLat, greaterThan(46.1));
    expect(minLng, lessThan(19.0));
    expect(maxLng, greaterThan(22.9));
  });

  testWidgets('buildSerbiaBorderLayer renderuje PolygonLayer bez gresaka u FlutterMap',
      (tester) async {
    await tester.runAsync(() => AppMapTiles.loadSerbiaContourPoints());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(44.0, 21.0),
              initialZoom: 6.5,
            ),
            children: [
              AppMapTiles.buildSerbiaBorderLayer(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate((w) => w is PolygonLayer);
    expect(finder, findsOneWidget);
    final polygonLayer = tester.widget<PolygonLayer>(finder);
    expect(polygonLayer.polygons, hasLength(1));
    expect(polygonLayer.polygons.first.points.length, greaterThan(1000));
    expect(tester.takeException(), isNull);
  });
}
