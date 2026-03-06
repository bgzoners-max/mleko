import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mapa prodavaca – prikazuje prodavce na mapi ako imaju koordinate.
/// Srbija centar: ~44.0, 21.0
class SellersMapScreen extends StatefulWidget {
  const SellersMapScreen({super.key});

  @override
  State<SellersMapScreen> createState() => _SellersMapScreenState();
}

class _SellersMapScreenState extends State<SellersMapScreen> {
  static const LatLng _srbijaCentar = LatLng(44.0, 21.0);

  late final Future<List<Map<String, dynamic>>> _sellersFuture;

  @override
  void initState() {
    super.initState();
    _sellersFuture = Supabase.instance.client
        .from('profiles')
        .select('id, farm_name, location, lat, lng')
        .eq('role', 'seller')
        .not('lat', 'is', null)
        .not('lng', 'is', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prodavci na mapi')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sellersFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text('Greška pri učitavanju: ${snap.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Prodavci još nemaju lokacije na mapi', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Prodavci mogu dodati koordinate u profilu', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            );
          }

          final markers = list.map((e) {
            final lat = (e['lat'] as num).toDouble();
            final lng = (e['lng'] as num).toDouble();
            return Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => context.push('/seller/${e['id']}'),
                child: Column(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 36),
                    Text(
                      (e['farm_name'] ?? e['location'] ?? '') as String,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: _srbijaCentar,
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.mleko',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
