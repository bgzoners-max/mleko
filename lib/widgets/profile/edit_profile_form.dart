import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_messages.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import 'edit_profile_account_info_section.dart';
import 'edit_profile_form_fields.dart';
import 'edit_profile_photo_section.dart';
import 'edit_profile_seller_tags_section.dart';

/// Reusable forma za izmenu podataka profila (koristi se i u BottomSheet-u i na posebnom ekranu).
class EditProfileForm extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onSaved;
  final bool isFullScreen;

  const EditProfileForm({
    super.key,
    required this.user,
    this.onSaved,
    this.isFullScreen = false,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _farmNameCtrl;
  late List<String> _selectedTags;
  late bool _phonePublic;
  String? _currentPhotoUrl;
  bool _uploadingPhoto = false;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _sendingPasswordReset = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.displayName ?? '');
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _cityCtrl = TextEditingController(text: u.city ?? '');
    _postalCodeCtrl = TextEditingController(text: u.postalCode ?? '');
    _addressCtrl = TextEditingController(text: u.address ?? u.location ?? '');
    _farmNameCtrl = TextEditingController(text: u.farmName ?? '');
    _selectedTags = List.from(u.sellerTags);
    _phonePublic = u.phonePublic;
    _currentPhotoUrl = u.profileImageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _postalCodeCtrl.dispose();
    _addressCtrl.dispose();
    _farmNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
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
    if (xFile == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await xFile.readAsBytes();
      final sizeErr = checkFileSize(bytes);
      if (sizeErr != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(sizeErr), backgroundColor: Colors.red),
        );
        return;
      }
      final url =
          await StorageService().uploadProfileImage(widget.user.id, bytes);
      await usersService.updateProfileImage(widget.user.id, url);
      await appState.refreshUser();
      if (mounted) {
        setState(() {
          _currentPhotoUrl = url;
        });
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
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukloni profilnu sliku?'),
        content: const Text(
            'Da li ste sigurni da želite da uklonite profilnu sliku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();

    setState(() => _uploadingPhoto = true);
    try {
      await usersService.updateProfileImage(widget.user.id, null);
      await appState.refreshUser();
      if (mounted) {
        setState(() {
          _currentPhotoUrl = null;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Profilna slika je uklonjena.')),
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
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = widget.user.email;
    if (email == null || email.trim().isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingPasswordReset = true);
    try {
      await context.read<AppState>().authService.sendPasswordReset(email.trim());
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Link za promenu lozinke poslat je na adresu: $email'),
            backgroundColor: Colors.green.shade700,
          ),
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
      if (mounted) setState(() => _sendingPasswordReset = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = widget.user;
    setState(() => _saving = true);
    try {
      final farmNameTrimmed = _farmNameCtrl.text.trim();
      final displayNameTrimmed = _nameCtrl.text.trim();
      final phoneTrimmed = _phoneCtrl.text.trim();
      final cityTrimmed = _cityCtrl.text.trim();
      final postalCodeTrimmed = _postalCodeCtrl.text.trim();
      final addressTrimmed = _addressCtrl.text.trim();

      final updatedUser = user.copyWith(
        farmName: farmNameTrimmed.isNotEmpty ? farmNameTrimmed : null,
        displayName: displayNameTrimmed.isNotEmpty ? displayNameTrimmed : null,
        phone: phoneTrimmed.isNotEmpty ? phoneTrimmed : null,
        city: cityTrimmed.isNotEmpty ? cityTrimmed : null,
        postalCode: postalCodeTrimmed.isNotEmpty ? postalCodeTrimmed : null,
        address: addressTrimmed.isNotEmpty ? addressTrimmed : null,
        location: user.isSeller
            ? (addressTrimmed.isNotEmpty ? addressTrimmed : null)
            : null,
        phonePublic: _phonePublic,
        sellerTags: user.isSeller ? _selectedTags : user.sellerTags,
      );

      await usersService.updateProfile(updatedUser, previous: user);

      await appState.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil je uspešno sačuvan.'),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onSaved != null) {
          widget.onSaved!();
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSeller = widget.user.isSeller;

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;
          final isWide = constraints.maxWidth >= 520;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. FOTOGRAFIJA PROFILA (Avatar sa brzim izmenama)
              EditProfilePhotoSection(
                currentPhotoUrl: _currentPhotoUrl,
                uploading: _uploadingPhoto,
                onPickPhoto: _pickAndUploadPhoto,
                onRemovePhoto: _removePhoto,
              ),
              const SizedBox(height: 14),

              // 2. LIČNI PODACI
              Text(
                'Osnovni podaci',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: EditProfileDisplayNameField(
                        controller: _farmNameCtrl,
                        isSeller: isSeller,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EditProfileFullNameField(controller: _nameCtrl),
                    ),
                  ],
                )
              else ...[
                EditProfileDisplayNameField(
                  controller: _farmNameCtrl,
                  isSeller: isSeller,
                ),
                const SizedBox(height: 8),
                EditProfileFullNameField(controller: _nameCtrl),
              ],
              const SizedBox(height: 14),

              // 3. KONTAKT I PRIVATNOST
              Text(
                'Kontakt podaci',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: EditProfilePhoneField(controller: _phoneCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EditProfilePhonePrivacySwitch(
                        value: _phonePublic,
                        onChanged: (v) => setState(() => _phonePublic = v),
                      ),
                    ),
                  ],
                )
              else ...[
                EditProfilePhoneField(controller: _phoneCtrl),
                const SizedBox(height: 8),
                EditProfilePhonePrivacySwitch(
                  value: _phonePublic,
                  onChanged: (v) => setState(() => _phonePublic = v),
                ),
              ],
              const SizedBox(height: 14),

              // 4. LOKACIJA I ADRESA
              Text(
                'Lokacija i adresa',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: EditProfileAddressField(controller: _addressCtrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: EditProfileCityField(
                        controller: _cityCtrl,
                        postalCodeController: _postalCodeCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 145,
                      child: EditProfilePostalCodeField(
                        controller: _postalCodeCtrl,
                        cityController: _cityCtrl,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                EditProfileAddressField(controller: _addressCtrl),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: EditProfileCityField(
                        controller: _cityCtrl,
                        postalCodeController: _postalCodeCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 125,
                      child: EditProfilePostalCodeField(
                        controller: _postalCodeCtrl,
                        cityController: _cityCtrl,
                        labelText: 'Pošt. broj',
                      ),
                    ),
                  ],
                ),
              ],

              // 5. OZNAKE PRODAVCA (ako je korisnik prodavac)
              if (isSeller) ...[
                const SizedBox(height: 14),
                EditProfileSellerTagsSection(
                  selectedTags: _selectedTags,
                  onSelectionChanged: (tags) =>
                      setState(() => _selectedTags = tags),
                ),
              ],

              const SizedBox(height: 14),

              // 6. INFORMACIJE O NALOGU
              Text(
                'Informacije o nalogu',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              EditProfileAccountInfoSection(
                email: widget.user.email,
                sendingPasswordReset: _sendingPasswordReset,
                onSendPasswordReset: _sendPasswordReset,
              ),

              const SizedBox(height: 20),

              // 7. DUGME ZA ČUVANJE
              if (isWide)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 220,
                    child: _buildSaveButton(),
                  ),
                )
              else
                _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _saving ? null : _save,
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline, size: 18),
      label: Text(
        _saving ? 'Čuvanje izmena...' : 'Sačuvaj izmene',
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
