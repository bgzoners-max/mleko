import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../core/utils/error_messages.dart';
import '../../core/profile_display_names.dart';

class SellerProfilePhotoSection extends StatefulWidget {
  final UserModel user;

  const SellerProfilePhotoSection({super.key, required this.user});

  @override
  State<SellerProfilePhotoSection> createState() =>
      _SellerProfilePhotoSectionState();
}

class _SellerProfilePhotoSectionState extends State<SellerProfilePhotoSection> {
  bool _loading = false;
  late final Future<int> _followersFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture =
        FavoriteSellersService().getFollowersCount(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _followersFuture,
      builder: (context, snap) {
        final followersCount = snap.data ?? 0;
        return SellerProfilePhotoContent(
            user: widget.user,
            followersCount: followersCount,
            loading: _loading,
            onPickAndUpload: _pickAndUpload);
      },
    );
  }

  Future<void> _pickAndUpload() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null) return;
    setState(() => _loading = true);
    try {
      final bytes = await xFile.readAsBytes();
      final url =
          await StorageService().uploadProfileImage(widget.user.id, bytes);
      await usersService.updateProfileImage(widget.user.id, url);
      await appState.refreshUser();
      if (mounted) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Profilna slika ažurirana.')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class SellerProfilePhotoContent extends StatelessWidget {
  final UserModel user;
  final int followersCount;
  final bool loading;
  final Future<void> Function() onPickAndUpload;

  const SellerProfilePhotoContent({
    super.key,
    required this.user,
    required this.followersCount,
    required this.loading,
    required this.onPickAndUpload,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user ?? user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: loading ? null : onPickAndUpload,
                  behavior: HitTestBehavior.opaque,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: currentUser.profileImageUrl != null
                        ? NetworkImage(currentUser.profileImageUrl!)
                        : null,
                    child: loading
                        ? const CircularProgressIndicator()
                        : currentUser.profileImageUrl == null
                            ? Icon(Icons.add_a_photo,
                                size: 32, color: Colors.grey.shade600)
                            : null,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: loading ? null : onPickAndUpload,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolveProfileDisplayName(
                      currentUser.farmName,
                      currentUser.displayName,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (followersCount > 0) ...[
                    const SizedBox(height: 2),
                    Text('$followersCount pratilaca',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    loading
                        ? 'Učitavanje…'
                        : 'Dodirni da promeniš profilnu sliku',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
