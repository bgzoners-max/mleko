import 'package:flutter/material.dart';

/// Sekcija sa fotografijom profila (avatar + dugmad „Promeni/Ukloni sliku").
///
/// Izdvojena iz EditProfileForm radi održavanja fajla ispod limita od
/// 700 linija (tool/check_file_size.dart). Logika izbora i uploada slike
/// ostaje u EditProfileForm-i i prosleđuje se kroz callback-ove.
class EditProfilePhotoSection extends StatelessWidget {
  final String? currentPhotoUrl;
  final bool uploading;
  final VoidCallback? onPickPhoto;
  final VoidCallback? onRemovePhoto;

  const EditProfilePhotoSection({
    super.key,
    required this.currentPhotoUrl,
    required this.uploading,
    required this.onPickPhoto,
    this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: uploading ? null : onPickPhoto,
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: currentPhotoUrl != null &&
                          currentPhotoUrl!.isNotEmpty
                      ? NetworkImage(currentPhotoUrl!)
                      : null,
                  child: uploading
                      ? const CircularProgressIndicator()
                      : (currentPhotoUrl == null || currentPhotoUrl!.isEmpty)
                          ? Icon(Icons.person,
                              size: 52,
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
                    onTap: uploading ? null : onPickPhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: uploading ? null : onPickPhoto,
            icon: const Icon(Icons.photo_camera_outlined, size: 16),
            label: Text(currentPhotoUrl == null
                ? 'Dodaj profilnu sliku'
                : 'Promeni sliku'),
          ),
          if (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty)
            TextButton.icon(
              onPressed: uploading ? null : onRemovePhoto,
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.redAccent),
              label: const Text(
                'Ukloni sliku',
                style: TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
