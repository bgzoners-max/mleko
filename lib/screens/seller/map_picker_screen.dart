import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Ekran za odabir lokacije na mapi – prodavac tapne tačku da postavi marker.
/// Koristi InteractionOptions bez doubleTapZoom da tapovi odmah reaguju,
/// plus onMapEvent kao rezerva za MapEventTap.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  final double? initialLat;
  final double? initialLng;

  static const LatLng _srbijaCentar = LatLng(44.0, 21.0);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedPoint;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _selectPoint(point);
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventTap) {
      _selectPoint(event.tapPosition);
    }
  }

  void _selectPoint(LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
    // Brza povratna informacija da je lokacija odabrana
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lokacija: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirm() {
    if (_selectedPoint != null) {
      context.pop({'lat': _selectedPoint!.latitude, 'lng': _selectedPoint!.longitude});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tapnite na mapu da odaberete lokaciju farme.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedPoint ?? MapPickerScreen._srbijaCentar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odaberi lokaciju'),
        actions: [
          if (_selectedPoint != null)
            TextButton(
              onPressed: _confirm,
              child: const Text('Sačuvaj'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: _selectedPoint != null ? 12 : 6,
                onTap: _onMapTap,
                onMapEvent: _onMapEvent,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom & ~InteractiveFlag.doubleTapDragZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'app.mleko',
                ),
                if (_selectedPoint != null)
                  TranslucentPointer(
                    child: MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint!,
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedPoint != null) ...[
                    FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Sačuvaj lokaciju'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedPoint != null
                              ? 'Lokacija: ${_selectedPoint!.latitude.toStringAsFixed(5)}, ${_selectedPoint!.longitude.toStringAsFixed(5)}'
                              : 'Tapnite na mapu da označite lokaciju farme',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
