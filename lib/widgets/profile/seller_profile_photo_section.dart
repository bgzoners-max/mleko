import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../core/profile_display_names.dart';
import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/media/storage_service.dart';
import '../../services/services.dart';
import 'edit_profile_sheet.dart';

/// Sekcija sa profilnom fotografijom i osnovnim podacima (koristi se za sve korisnike — i kupce i prodavce).
typedef UserProfilePhotoSection = SellerProfilePhotoSection;

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
    _followersFuture = widget.user.isSeller
        ? FavoriteSellersService().getFollowersCount(widget.user.id)
        : Future.value(0);
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
          onPickAndUpload: _pickAndUpload,
        );
      },
    );
  }

  Future<void> _pickAndUpload() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Izaberi iz galerije'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Snimi kamerom'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final xFile = await picker.pickImage(source: source, imageQuality: 80);
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
          const SnackBar(content: Text('Profilna slika uspešno ažurirana.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Colors.red,
          ),
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

  void _openEditProfile(BuildContext context, UserModel currentUser) {
    if (Breakpoints.useTwoPaneLayout(context)) {
      context.push('/profile/edit');
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditProfileSheet(user: currentUser),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user ?? user;
    final theme = Theme.of(context);
    final isSeller = currentUser.isSeller;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: loading ? null : onPickAndUpload,
                  behavior: HitTestBehavior.opaque,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: currentUser.profileImageUrl != null &&
                            currentUser.profileImageUrl!.isNotEmpty
                        ? NetworkImage(currentUser.profileImageUrl!)
                        : null,
                    child: loading
                        ? const CircularProgressIndicator()
                        : (currentUser.profileImageUrl == null ||
                                currentUser.profileImageUrl!.isEmpty)
                            ? Icon(Icons.person,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant)
                            : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: loading ? null : onPickAndUpload,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
                onTap: () => _openEditProfile(context, currentUser),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              resolveProfileDisplayName(
                                currentUser.farmName,
                                currentUser.displayName,
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSeller
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isSeller ? 'Prodavac' : 'Kupac',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSeller
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (isSeller && followersCount > 0) ...[
                        Text(
                          '$followersCount pratilaca',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ] else if (currentUser.createdAt != null) ...[
                        Text(
                          'Član od ${DateFormat('MMMM yyyy.', 'sr').format(currentUser.createdAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        loading
                            ? 'Otpremanje slike…'
                            : 'Dodirni za izmenu slike ili profila',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Uredi profil',
              onPressed: () => _openEditProfile(context, currentUser),
            ),
          ],
        ),
      ),
    );
  }
}
