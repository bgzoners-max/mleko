import 'package:flutter/material.dart';

/// Sekcija sa fotografijom profila (avatar + akcije „Promeni/Ukloni sliku") u kompaktnom horizontalnom rasporedu.
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
    final hasPhoto = currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: uploading ? null : onPickPhoto,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      hasPhoto ? NetworkImage(currentPhotoUrl!) : null,
                  child: uploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (!hasPhoto
                          ? Icon(Icons.person,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant)
                          : null),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                  elevation: 1,
                  child: InkWell(
                    onTap: uploading ? null : onPickPhoto,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.camera_alt,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profilna slika',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Javno vidljiva fotografija na profilu',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    OutlinedButton.icon(
                      onPressed: uploading ? null : onPickPhoto,
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.photo_camera_outlined, size: 14),
                      label: Text(
                        hasPhoto ? 'Promeni sliku' : 'Dodaj profilnu sliku',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    if (hasPhoto)
                      TextButton.icon(
                        onPressed: uploading ? null : onRemovePhoto,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        icon: const Icon(Icons.delete_outline,
                            size: 14, color: Colors.redAccent),
                        label: const Text(
                          'Ukloni sliku',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 11.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
