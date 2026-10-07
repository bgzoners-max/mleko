import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/serbian_cities.dart';
import '../../core/utils/error_messages.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';

const _kSellerTags = [
  'Bio sertifikat',
  'Direktna dostava',
  'Preuzimanje na licu mesta',
  'Plaćanje gotovinom',
  'Plaćanje karticom',
  'PDV obveznik',
  'Organski uzgoj',
  'Sezonski',
];

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
    if (xFile == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await xFile.readAsBytes();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. FOTOGRAFIJA PROFILA (Avatar sa brzim izmenama)
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: _currentPhotoUrl != null &&
                                _currentPhotoUrl!.isNotEmpty
                            ? NetworkImage(_currentPhotoUrl!)
                            : null,
                        child: _uploadingPhoto
                            ? const CircularProgressIndicator()
                            : (_currentPhotoUrl == null ||
                                    _currentPhotoUrl!.isEmpty)
                                ? Icon(Icons.person,
                                    size: 52, color: theme.colorScheme.onSurfaceVariant)
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
                          onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
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
                  onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: Text(_currentPhotoUrl == null
                      ? 'Dodaj profilnu sliku'
                      : 'Promeni sliku'),
                ),
                if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                  TextButton.icon(
                    onPressed: _uploadingPhoto ? null : _removePhoto,
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Ukloni sliku',
                      style: TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. LIČNI PODACI
          Text(
            'Osnovni podaci',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _farmNameCtrl,
            decoration: InputDecoration(
              labelText: isSeller
                  ? 'Naziv gazdinstva / Prikazano ime'
                  : 'Prikazano ime (Display name)',
              hintText: isSeller
                  ? 'npr. Gazdinstvo Petrović ili Eko Farma'
                  : 'npr. Milan Jovanović ili Nadimak',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(isSeller
                  ? Icons.storefront_outlined
                  : Icons.badge_outlined),
              helperText: 'Ime koje se javno prikazuje na profilu, oglasima i porukama',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Puno ime i prezime',
              hintText: 'Vaše lično ime i prezime',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
              helperText: 'Lično ime za porudžbine i dostavu',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // 3. KONTAKT I PRIVATNOST
          Text(
            'Kontakt podaci',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Broj telefona',
              hintText: 'npr. 064 1234567',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return null;
              final digits = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
              if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                return 'Unesite ispravan broj telefona (7-15 cifara)';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _phonePublic,
            onChanged: (v) => setState(() => _phonePublic = v),
            dense: true,
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              _phonePublic ? Icons.lock_open_outlined : Icons.lock_outline,
              size: 20,
              color: _phonePublic
                  ? Colors.green.shade600
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              _phonePublic ? 'Telefon je vidljiv svima' : 'Telefon je privatan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _phonePublic ? Colors.green.shade700 : null,
              ),
            ),
            subtitle: Text(
              _phonePublic
                  ? 'Kupci i posetioci mogu videti vaš broj u oglasima i na profilu.'
                  : 'Broj je sakriven od javnosti i koristi se isključivo za realizaciju narudžbina.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 20),

          // 4. LOKACIJA I ADRESA
          Text(
            'Lokacija i adresa',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _cityCtrl.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<String>.empty();
              }
              return SerbianCities.suggestions(textEditingValue.text);
            },
            onSelected: (String selection) {
              _cityCtrl.text = selection;
            },
            fieldViewBuilder: (
              BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              if (_cityCtrl.text.isNotEmpty &&
                  fieldTextEditingController.text.isEmpty) {
                fieldTextEditingController.text = _cityCtrl.text;
              }
              fieldTextEditingController.addListener(() {
                _cityCtrl.text = fieldTextEditingController.text;
              });

              return TextFormField(
                controller: fieldTextEditingController,
                focusNode: fieldFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Grad ili mesto',
                  hintText: 'npr. Beograd, Novi Sad, Čačak...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return null;
                  if (val.length < 2) {
                    return 'Grad mora imati najmanje 2 karaktera';
                  }
                  if (RegExp(r'^\d+$').hasMatch(val)) {
                    return 'Unesite ispravan naziv grada';
                  }
                  return null;
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _postalCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Poštanski broj',
              hintText: 'npr. 11000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.markunread_mailbox_outlined),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            decoration: InputDecoration(
              labelText: 'Adresa (ulica i broj)',
              hintText: 'npr. Cara Dušana 12 / Stan 4',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.home_outlined),
              helperText: 'Vidljiva samo tebi i drugoj strani pri naručivanju',
              helperStyle: TextStyle(color: Colors.grey.shade600),
              suffixIcon: Tooltip(
                message: 'Adresa nikada nije javno vidljiva posetiocima',
                child: Icon(Icons.lock_outline,
                    size: 18, color: Colors.grey.shade500),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),

          // 5. OZNAKE PRODAVCA (ako je korisnik prodavac)
          if (isSeller) ...[
            const SizedBox(height: 24),
            Text(
              'Oznake gazdinstva / prodavca',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kSellerTags
                  .map((tag) => FilterChip(
                        label: Text(tag, style: const TextStyle(fontSize: 13)),
                        selected: _selectedTags.contains(tag),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        }),
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 24),

          // 6. INFORMACIJE O NALOGU
          Text(
            'Informacije o nalogu',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Email: ${widget.user.email ?? 'Nije unet'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Tooltip(
                      message: 'Email je primarni identifikator naloga',
                      child: Icon(Icons.lock_outline,
                          size: 16, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if (widget.user.email != null &&
                    widget.user.email!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Želite da promenite lozinku?',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _sendingPasswordReset
                            ? null
                            : _sendPasswordReset,
                        icon: _sendingPasswordReset
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.key_outlined, size: 16),
                        label: const Text('Resetuj lozinku',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 7. DUGME ZA ČUVANJE
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _saving ? 'Čuvanje izmena...' : 'Sačuvaj izmene',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
