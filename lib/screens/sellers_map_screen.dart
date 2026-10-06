import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/map_tiles.dart';
import '../core/responsive.dart';
import '../widgets/app_back_button.dart';
import '../constants/amazon_theme.dart';
import '../widgets/navigation/desktop_header.dart';

/// Mapa seoskih gazdinstava – prikazuje domaćinstva na mapi sa interaktivnim profilima i geolokacijom.
class SellersMapScreen extends StatefulWidget {
  const SellersMapScreen({super.key});

  @override
  State<SellersMapScreen> createState() => _SellersMapScreenState();
}

class _SellersMapScreenState extends State<SellersMapScreen> {
  static const LatLng _srbijaCentar = LatLng(44.0, 21.0);
  final MapController _mapController = MapController();

  late final Future<List<Map<String, dynamic>>> _sellersFuture;
  bool _locatingUser = false;

  @override
  void initState() {
    super.initState();
    _sellersFuture = Supabase.instance.client
        .from('public_profiles')
        .select('id, farm_name, location, city, lat, lng, profile_image_url')
        .eq('role', 'seller')
        .not('lat', 'is', null)
        .not('lng', 'is', null);
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  void _fitBounds(List<Map<String, dynamic>> sellers) {
    if (sellers.isEmpty) return;
    final points = sellers
        .map((e) {
          final lat = _parseDouble(e['lat']);
          final lng = _parseDouble(e['lng']);
          if (lat == null || lng == null) return null;
          return LatLng(lat, lng);
        })
        .whereType<LatLng>()
        .toList();

    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 12);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locatingUser = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _mapController.move(LatLng(pos.latitude, pos.longitude), 12);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prikazana vaša trenutna lokacija.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dozvola za geolokaciju nije odobrena.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri određivanju lokacije.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locatingUser = false);
    }
  }

  void _showSellerPreview(BuildContext context, Map<String, dynamic> seller) {
    final farmName =
        (seller['farm_name'] ?? seller['location'] ?? 'Domaće gazdinstvo')
            as String;
    final locationText = (seller['city'] ?? seller['location'] ?? '') as String;
    final imageUrl = seller['profile_image_url'] as String?;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.compactModalMaxWidth),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(imageUrl)
                              : null,
                          child: imageUrl == null || imageUrl.isEmpty
                              ? Icon(Icons.storefront,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (locationText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        locationText,
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/seller/${seller['id']}');
                        },
                        icon: const Icon(Icons.store),
                        label: const Text('Pogledaj profil i ponudu'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Breakpoints.isDesktop(context);

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              leading: const AppBackButton(fallbackRoute: '/'),
              title: const Text('Seoska gazdinstva na mapi'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  tooltip: 'Prikaži sva gazdinstva',
                  onPressed: () async {
                    final list = await _sellersFuture;
                    _fitBounds(list);
                  },
                ),
                const AppHomeButton(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _locatingUser ? null : _goToMyLocation,
        tooltip: 'Moja lokacija',
        child: _locatingUser
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.my_location),
      ),
      body: Column(
        children: [
          if (isDesktop) const DesktopHeader(isStandalone: true),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _sellersFuture,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text('Greška pri učitavanju: ${snap.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Još uvek nema ucrtanih gazdinstava na mapi',
                            style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('Gazdinstva mogu dodati koordinate u svom profilu',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  );
                }

                final validSellers = list.where((e) {
                  final lat = _parseDouble(e['lat']);
                  final lng = _parseDouble(e['lng']);
                  return lat != null && lng != null;
                }).toList();

                final markers = validSellers.map((e) {
                  final lat = _parseDouble(e['lat'])!;
                  final lng = _parseDouble(e['lng'])!;
                  final farmName =
                      (e['farm_name'] ?? e['location'] ?? '') as String;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 80,
                    height: 64,
                    child: GestureDetector(
                      onTap: () => _showSellerPreview(context, e),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              farmName,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 36,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: _srbijaCentar,
                        initialZoom: 6.5,
                      ),
                      children: [
                        AppMapTiles.buildTileLayer(),
                        MarkerLayer(markers: markers),
                        AppMapTiles.buildAttribution(),
                      ],
                    ),
                    if (isDesktop)
                      Positioned(
                        top: 16,
                        left: 20,
                        child: _buildDesktopMapControls(context, validSellers),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMapControls(
    BuildContext context,
    List<Map<String, dynamic>> sellers,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1B241D) : Colors.white)
            .withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded,
              color: isDark ? AmazonColors.lightGreen : const Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 8),
          Text(
            '${sellers.length} seoskih gazdinstava',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 14),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _fitBounds(sellers),
            icon: const Icon(Icons.center_focus_strong, size: 16),
            label: const Text('Centriraj sve',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

