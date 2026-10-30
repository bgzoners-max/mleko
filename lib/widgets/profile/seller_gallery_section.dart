import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../core/utils/error_messages.dart';

class SellerGallerySection extends StatefulWidget {
  final UserModel? user;

  const SellerGallerySection({super.key, this.user});

  @override
  State<SellerGallerySection> createState() => _SellerGallerySectionState();
}

class _SellerGallerySectionState extends State<SellerGallerySection> {
  bool _loading = false;
  late List<String> _galleryUrls;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.user ?? context.read<AppState>().user;
    _galleryUrls = List.from(initialUser?.farmGalleryUrls ?? const []);
  }

  Future<void> _addPhoto() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final xFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    final user = appState.user;
    if (!mounted || user == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final sizeErr = checkFileSize(bytes);
      if (sizeErr != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(sizeErr), backgroundColor: Colors.red),
        );
        return;
      }
      final url = await StorageService()
          .uploadFarmGalleryImage(user.id, bytes, _galleryUrls.length);
      final newUrls = [..._galleryUrls, url];
      if (mounted) setState(() => _galleryUrls = newUrls);
      await usersService.updateFarmGallery(user.id, newUrls);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('Slika dodata.')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removePhoto(int index) async {
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
    try {
      await usersService.updateFarmGallery(user.id, updated);
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
    final currentUser = context.watch<AppState>().user ?? widget.user;
    final urls = currentUser?.farmGalleryUrls ?? const <String>[];
    final displayUrls = _galleryUrls.isNotEmpty ? _galleryUrls : urls;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Galerija',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '(opciono)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Fotografije gazdinstva, radionice, lokacije ili delatnosti.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayUrls.asMap().entries.map((e) => Stack(
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
                            tooltip: 'Ukloni fotografiju',
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.black54),
                            onPressed:
                                _loading ? null : () => _removePhoto(e.key),
                          ),
                        ),
                      ],
                    )),
                if (displayUrls.length < 10)
                  GestureDetector(
                    onTap: _loading ? null : _addPhoto,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
