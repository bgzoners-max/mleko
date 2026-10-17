import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/seller_delivery_settings_tab.dart';

/// Podešavanja prodavca: lokacija, priča, galerija
class SellerSettingsScreen extends StatefulWidget {
  final int initialTabIndex;
  const SellerSettingsScreen({super.key, this.initialTabIndex = 0});

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
    final safeIndex = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 5)
        ? widget.initialTabIndex
        : 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: safeIndex);
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
    final usersService = context.read<UsersService>();
    final user = appState.user;
    if (user == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    final result = await ErrorHandlerService().executeWithResult(
      'Clear seller location',
      () => usersService.clearSellerLocation(user.id),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lokacija uklonjena.')));
      }
    } else {
      setState(() => _error = result.error?.getUserMessage());
    }
  }

  Future<void> _confirmAndClearLocation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši lokaciju?'),
        content: const Text('Lokacija na mapi će biti uklonjena.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await _clearLocation();
  }

  Future<void> _openMapPicker() async {
    final user = context.read<AppState>().user;
    final usersService = context.read<UsersService>();
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

    final resultAction = await ErrorHandlerService().executeWithResult(
      'Update seller location',
      () => usersService.updateSellerLocation(
          u.id, lat.toDouble(), lng.toDouble()),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (resultAction.isSuccess) {
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Lokacija sačuvana.')));
      }
    } else {
      setState(() => _error = resultAction.error?.getUserMessage());
    }
  }

  Future<void> _saveStory() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = appState.user;
    if (user == null) return;
    setState(() {
      _error = null;
      _loading = true;
    });

    final resultAction = await ErrorHandlerService().executeWithResult(
      'Update seller story',
      () =>
          usersService.updateSellerStory(user.id, _storyController.text.trim()),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (resultAction.isSuccess) {
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Priča sačuvana.')));
      }
    } else {
      setState(() => _error = resultAction.error?.getUserMessage());
    }
  }

  Future<void> _addGalleryPhoto() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final xFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final user = appState.user;
    if (!mounted || user == null) return;
    setState(() => _loading = true);

    final resultAction = await ErrorHandlerService()
        .executeWithResult('Add gallery photo', () async {
      final bytes = await xFile.readAsBytes();
      final url = await StorageService()
          .uploadFarmGalleryImage(user.id, bytes, _galleryUrls.length);
      final newUrls = [..._galleryUrls, url];
      await usersService.updateFarmGallery(user.id, newUrls);
      return newUrls;
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (resultAction.isSuccess) {
      setState(() => _galleryUrls = resultAction.data!);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Slika dodata.')));
      }
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(resultAction.error?.getUserMessage() ?? 'Greška'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _removeGalleryPhoto(int index) async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = appState.user;
    if (user == null) return;
    final removed = _galleryUrls[index];
    final updated = List<String>.from(_galleryUrls)..removeAt(index);
    setState(() {
      _galleryUrls = updated;
      _loading = true;
    });

    final resultAction = await ErrorHandlerService().executeWithResult(
      'Remove gallery photo',
      () => usersService.updateFarmGallery(user.id, updated),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (resultAction.isSuccess) {
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Slika uklonjena.')));
      }
    } else {
      setState(
          () => _galleryUrls = List.from(_galleryUrls)..insert(index, removed));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resultAction.error?.getUserMessage() ?? 'Greška')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Podešavanja prodavca'),
        actions: const [AppHomeButton()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (_) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: 'Lokacija'),
            Tab(text: 'Lična dostava'),
            Tab(text: 'Priča'),
            Tab(text: 'Galerija'),
            Tab(text: 'Brzi odgovori'),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: AnimatedSwitcher(
            duration: Duration(
              milliseconds:
                  context.watch<AppSettingsProvider>().animationsEnabled
                      ? 250
                      : 0,
            ),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey<int>(_tabController.index),
              child: _buildTabContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildLocationTab();
      case 1:
        return const SellerDeliverySettingsTab();
      case 2:
        return _buildStoryTab();
      case 3:
        return _buildGalleryTab();
      case 4:
        return _buildQuickRepliesTab();
      default:
        return _buildLocationTab();
    }
  }

  Widget _buildLocationTab() {
    final isDesktop = !Breakpoints.isPhone(context);
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
          Align(
            alignment: isDesktop ? Alignment.centerRight : Alignment.center,
            child: isDesktop
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (hasLocation)
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _confirmAndClearLocation,
                          icon: const Icon(Icons.location_off, size: 18),
                          label: const Text('Obriši lokaciju'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _loading ? null : _openMapPicker,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.map, size: 18),
                        label: Text(
                          hasLocation ? 'Promeni lokaciju' : 'Odaberi na mapi',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _loading ? null : _openMapPicker,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.map, size: 18),
                        label: Text(
                          hasLocation ? 'Promeni lokaciju' : 'Odaberi na mapi',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (hasLocation) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _confirmAndClearLocation,
                          icon: const Icon(Icons.location_off, size: 18),
                          label: const Text('Obriši lokaciju'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTab() {
    final isDesktop = !Breakpoints.isPhone(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              'Napišite kratak tekst o svojoj ponudi, tradiciji i načinu rada.',
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
          Align(
            alignment: isDesktop ? Alignment.centerRight : Alignment.center,
            child: SizedBox(
              width: isDesktop ? null : double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _saveStory,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 18),
                label: const Text(
                  'Sačuvaj priču',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
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
          Text(
            'Dodajte fotografije gazdinstva, radionice, lokacije ili delatnosti (opciono).',
            style: TextStyle(color: Colors.grey.shade700),
          ),
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
              const SizedBox(height: 12),
              Align(
                alignment: !Breakpoints.isPhone(context)
                    ? Alignment.centerRight
                    : Alignment.center,
                child: SizedBox(
                  width: !Breakpoints.isPhone(context) ? null : double.infinity,
                  child: FilledButton.icon(
                    onPressed: _quickRepliesSaving
                        ? null
                        : () async {
                            this.setState(() {
                              _quickRepliesError = '';
                              _quickRepliesSaving = true;
                            });

                            final appState = context.read<AppState>();
                            final usersService = context.read<UsersService>();
                            final u = appState.user;
                            if (u == null) return;

                            final resultAction = await ErrorHandlerService()
                                .executeWithResult('Update quick replies', () {
                              final replies =
                                  controllers.map((c) => c.text).toList();
                              return usersService.updateSellerQuickReplies(
                                  u.id, replies);
                            });

                            if (!mounted) return;
                            this.setState(() => _quickRepliesSaving = false);

                            if (resultAction.isSuccess) {
                              await appState.refreshUser();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Brzi odgovori sačuvani.')));
                              }
                            } else {
                              this.setState(() => _quickRepliesError =
                                  resultAction.error?.getUserMessage() ?? 'Greška');
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: !Breakpoints.isPhone(context) ? 24 : 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _quickRepliesSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Sačuvaj brze odgovore',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
