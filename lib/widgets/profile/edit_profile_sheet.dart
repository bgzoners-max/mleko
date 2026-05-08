import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../core/utils/error_messages.dart';

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

class EditProfileSheet extends StatefulWidget {
  final UserModel user;
  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _farmNameCtrl;
  late List<String> _selectedTags;
  late bool _phonePublic;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.displayName ?? '');
    _phoneCtrl = TextEditingController(text: u.phone ?? '');
    _cityCtrl = TextEditingController(text: u.city ?? '');
    _postalCodeCtrl = TextEditingController(text: u.postalCode ?? '');
    _addressCtrl = TextEditingController(text: u.address ?? '');
    _farmNameCtrl = TextEditingController(text: u.farmName ?? '');
    _selectedTags = List.from(u.sellerTags);
    _phonePublic = u.phonePublic;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = widget.user;
    setState(() => _saving = true);
    try {
      await usersService.upsertProfile(
        user.id,
        displayName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        postalCode:
            _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
        location:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phonePublic: _phonePublic,
        farmName: user.isSeller && _farmNameCtrl.text.trim().isNotEmpty
            ? _farmNameCtrl.text.trim()
            : null,
      );
      if (user.isSeller) {
        await usersService.updateSellerTags(user.id, _selectedTags);
      }
      await appState.refreshUser();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil sačuvan.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = widget.user.isSeller;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Uredi profil',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Zatvori',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ime i prezime', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                    labelText: 'Telefon', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return null;
                  final digits = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
                  if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                    return 'Unesite ispravan broj telefona';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                value: _phonePublic,
                onChanged: (v) => setState(() => _phonePublic = v),
                dense: true,
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  _phonePublic ? Icons.lock_open_outlined : Icons.lock_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  _phonePublic ? 'Telefon vidljiv svima' : 'Telefon privatan',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                    labelText: 'Grad', border: OutlineInputBorder()),
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
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _postalCodeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Poštanski broj', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Adresa (ulica i broj)',
                  border: const OutlineInputBorder(),
                  helperText: 'Vidljiva samo tebi i prodavcu pri narudžbini',
                  helperStyle: TextStyle(color: Colors.grey.shade600),
                  suffixIcon: Tooltip(
                    message: 'Adresa nije javno vidljiva',
                    child: Icon(Icons.lock_outline,
                        size: 18, color: Colors.grey.shade500),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (isSeller) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _farmNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Naziv gazdinstva',
                      border: OutlineInputBorder()),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oznake gazdinstva',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kSellerTags
                      .map((tag) => FilterChip(
                            label:
                                Text(tag, style: const TextStyle(fontSize: 13)),
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
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sačuvaj'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
