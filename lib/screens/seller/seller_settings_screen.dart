import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

/// Podešavanja prodavca: lokacija, priča, galerija
class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  State<SellerSettingsScreen> createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storyController = TextEditingController();
  bool _loading = false;
  bool _quickRepliesSaving = false;
  String _quickRepliesError = '';
  String? _error;
  List<String> _galleryUrls = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    final user = context.read<AppState>().user;
    _storyController.text = user?.sellerStory ?? '';
    _galleryUrls = List.from(user?.farmGalleryUrls ?? []);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _clearLocation() async {
    final appState = context.read<AppState>();
    final user = appState.user;
    if (user == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await UsersService().clearSellerLocation(user.id);
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lokacija uklonjena.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMapPicker() async {
    final user = context.read<AppState>().user;
    final result = await context.push<Map<String, dynamic>>(
      '/map-picker',
      extra: {
        if (user?.lat != null) 'lat': user!.lat,
        if (user?.lng != null) 'lng': user!.lng,
      },
    );
    if (result == null || !mounted) return;
    final lat = result['lat'] as num?;
    final lng = result['lng'] as num?;
    if (lat == null || lng == null) return;
    final appState = context.read<AppState>();
    final u = appState.user;
    if (u == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await UsersService()
          .updateSellerLocation(u.id, lat.toDouble(), lng.toDouble());
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lokacija sačuvana.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveStory() async {
    final appState = context.read<AppState>();
    final user = appState.user;
    if (user == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await UsersService()
          .updateSellerStory(user.id, _storyController.text.trim());
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Priča sačuvana.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addGalleryPhoto() async {
    final appState = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final xFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final user = appState.user;
    if (!mounted || user == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final url = await StorageService()
          .uploadFarmGalleryImage(user.id, bytes, _galleryUrls.length);
      final newUrls = [..._galleryUrls, url];
      if (mounted) setState(() => _galleryUrls = newUrls);
      await UsersService().updateFarmGallery(user.id, newUrls);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Slika dodata.')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeGalleryPhoto(int index) async {
    final appState = context.read<AppState>();
    final user = appState.user;
    if (user == null) return;
    final removed = _galleryUrls[index];
    final updated = List<String>.from(_galleryUrls)..removeAt(index);
    setState(() {
      _galleryUrls = updated;
      _loading = true;
    });
    try {
      await UsersService().updateFarmGallery(user.id, updated);
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slika uklonjena.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _galleryUrls = List.from(_galleryUrls)..insert(index, removed));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podešavanja prodavca'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: 'Lokacija'),
            Tab(text: 'Priča'),
            Tab(text: 'Galerija'),
            Tab(text: 'Brzi odgovori')
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(
          milliseconds: context.watch<AppSettingsProvider>().animationsEnabled ? 250 : 0,
        ),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey<int>(_tabController.index),
          child: _buildTabContent(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildLocationTab();
      case 1:
        return _buildStoryTab();
      case 2:
        return _buildGalleryTab();
      case 3:
        return _buildQuickRepliesTab();
      default:
        return _buildLocationTab();
    }
  }

  Widget _buildLocationTab() {
    final user = context.watch<AppState>().user;
    final hasLocation = user?.lat != null && user?.lng != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasLocation
                ? 'Tvoja lokacija je postavljena. Kupci te vide na mapi prodavaca.'
                : 'Odaberi lokaciju farme na mapi da bi te kupci mogli pronaći.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${user!.lat!.toStringAsFixed(5)}, ${user.lng!.toStringAsFixed(5)}',
                  style: TextStyle(
                      fontFamily: 'monospace', color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _loading ? null : _openMapPicker,
            icon: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.map),
            label: Text(hasLocation ? 'Promeni lokaciju' : 'Odaberi na mapi'),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Obriši lokaciju?'),
                          content:
                              const Text('Lokacija na mapi će biti uklonjena.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Odustani'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Obriši'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) await _clearLocation();
                    },
              icon: const Icon(Icons.location_off),
              label: const Text('Obriši lokaciju'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Napišite kratak tekst o gazdinstvu, tradiciji i načinu rada.',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          TextField(
            controller: _storyController,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Priča prodavca'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red))
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _saveStory,
            child: _loading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sačuvaj priču'),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Dodajte fotografije farme, stoke ili proizvodnje.',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._galleryUrls.asMap().entries.map((e) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: e.value,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                          onPressed: () => _removeGalleryPhoto(e.key),
                        ),
                      ),
                    ],
                  )),
              if (_galleryUrls.length < 10)
                GestureDetector(
                  onTap: _loading ? null : _addGalleryPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8)),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : const Icon(Icons.add_photo_alternate, size: 40),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesTab() {
    final user = context.watch<AppState>().user;
    final existing = user?.sellerQuickReplies ?? const [];
    final controllers = List<TextEditingController>.generate(
      5,
      (i) =>
          TextEditingController(text: i < existing.length ? existing[i] : ''),
    );
    return StatefulBuilder(
      builder: (ctx, setState) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dodaj 3–5 poruka koje najčešće šalješ kupcima u chatu (npr. vreme preuzimanja, način dostave, zahvalnica). Ove poruke će se pojaviti kao brzi odgovori ispod polja za unos poruke.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < controllers.length; i++) ...[
                TextField(
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Šablon ${i + 1}',
                    hintText: i == 0 ? 'npr. Dostupno sutra u 10 h' : null,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_quickRepliesError.isNotEmpty) ...[
                Text(_quickRepliesError,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _quickRepliesSaving
                    ? null
                    : () async {
                        this.setState(() {
                          _quickRepliesError = '';
                          _quickRepliesSaving = true;
                        });
                        try {
                          final appState = context.read<AppState>();
                          final u = appState.user;
                          if (u == null) return;
                          final replies =
                              controllers.map((c) => c.text).toList();
                          await UsersService()
                              .updateSellerQuickReplies(u.id, replies);
                          await appState.refreshUser();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Brzi odgovori sačuvani.')),
                          );
                        } catch (e) {
                          this.setState(() {
                            _quickRepliesError = e.toString();
                          });
                        } finally {
                          this.setState(() {
                            _quickRepliesSaving = false;
                          });
                        }
                      },
                child: _quickRepliesSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sačuvaj brze odgovore'),
              ),
            ],
          ),
        );
      },
    );
  }
}

