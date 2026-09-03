import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../models/classified_ad_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/media/storage_service.dart';

class AddEditClassifiedAdScreen extends StatefulWidget {
  final String? adId;

  const AddEditClassifiedAdScreen({super.key, this.adId});

  @override
  State<AddEditClassifiedAdScreen> createState() =>
      _AddEditClassifiedAdScreenState();
}

class _AddEditClassifiedAdScreenState extends State<AddEditClassifiedAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCategoryId;
  String _currency = 'RSD';
  String _priceType = 'fixed';
  String _condition = 'used';
  bool _phonePublic = true;
  String? _selectedCategoryName;

  final List<String> _existingImages = [];
  final List<Uint8List> _newImageBytes = [];
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  late ClassifiedsService _service;

  bool _loading = false;
  bool _initializing = false;

  bool get isEdit => widget.adId != null;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    if (isEdit) {
      _loadExisting();
    } else {
      final user = context.read<AppState>().user;
      if (user != null) {
        _cityController.text = user.city ?? '';
        _phoneController.text = user.phone ?? '';
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _initializing = true);
    try {
      final ad = await _service.getAd(widget.adId!);
      if (ad != null && mounted) {
        _titleController.text = ad.title;
        _descController.text = ad.description;
        _priceController.text =
            ad.price > 0 ? ad.price.toStringAsFixed(0) : '';
        _cityController.text = ad.city;
        _phoneController.text = ad.phone ?? '';
        _selectedCategoryId = ad.categoryId;
        _selectedCategoryName = ad.categoryName;
        _currency = ad.currency;
        _priceType = ad.priceType;
        _condition = ad.condition;
        _phonePublic = ad.phonePublic;
        _existingImages.addAll(ad.images);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri učitavanju oglasa.')),
        );
      }
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _pickImages() async {
    final totalCurrent = _existingImages.length + _newImageBytes.length;
    if (totalCurrent >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimalno možete dodati 8 slika.')),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;

    final remainingSlots = 8 - totalCurrent;
    for (final file in picked.take(remainingSlots)) {
      final bytes = await file.readAsBytes();
      setState(() => _newImageBytes.add(bytes));
    }
  }

  void _openCategoryPicker(BuildContext context) {
    final categories = context.read<ClassifiedsProvider>().categories;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Izaberi kategoriju',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtl,
                    itemCount: categories.length,
                    itemBuilder: (c, i) {
                      final cat = categories[i];
                      if (cat.subcategories.isEmpty) {
                        return ListTile(
                          leading: Icon(cat.iconData),
                          title: Text(cat.name),
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _selectedCategoryName = cat.name;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      }

                      return ExpansionTile(
                        leading: Icon(cat.iconData),
                        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(left: 56, right: 16),
                            title: Text('Sve u „${cat.name}”'),
                            onTap: () {
                              setState(() {
                                _selectedCategoryId = cat.id;
                                _selectedCategoryName = cat.name;
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                          ...cat.subcategories.map(
                            (sub) => ListTile(
                              contentPadding: const EdgeInsets.only(left: 56, right: 16),
                              title: Text(sub.name),
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = sub.id;
                                  _selectedCategoryName = sub.name;
                                });
                                Navigator.pop(ctx);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Molimo izaberite kategoriju za oglas.')),
      );
      return;
    }

    final user = context.read<AppState>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Morate biti prijavljeni.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final uploadedUrls = List<String>.from(_existingImages);

      // Upload novih slika
      for (var i = 0; i < _newImageBytes.length; i++) {
        final url = await _storageService.uploadProductImage(
          user.id,
          _newImageBytes[i],
          uploadedUrls.length + i,
        );
        uploadedUrls.add(url);
      }

      final priceNum = _priceType == 'fixed' || _priceType == 'negotiable'
          ? (double.tryParse(_priceController.text.replaceAll(',', '.').trim()) ?? 0.0)
          : 0.0;

      final ad = ClassifiedAdModel(
        id: widget.adId ?? '',
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: priceNum,
        currency: _currency,
        priceType: _priceType,
        categoryId: _selectedCategoryId!,
        condition: _condition,
        images: uploadedUrls,
        city: _cityController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        phonePublic: _phonePublic,
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEdit) {
        await _service.updateAd(ad);
      } else {
        await _service.createAd(ad);
      }

      if (mounted) {
        context.read<ClassifiedsProvider>().loadInitialAds();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Oglas uspešno ažuriran.' : 'Oglas uspešno objavljen!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = Breakpoints.isTablet(context);

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Učitavanje...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Izmeni oglas' : 'Postavi novi oglas'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sekcija: Fotografije
                  Text(
                    'Fotografije oglasa (do 8 slika)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: colorScheme.primary),
                                const SizedBox(height: 4),
                                const Text('Dodaj', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        ..._existingImages.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    entry.value,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _existingImages.removeAt(entry.key)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        ..._newImageBytes.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    entry.value,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _newImageBytes.removeAt(entry.key)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Naslov
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Naslov oglasa *',
                      hintText: 'npr. Traktor IMT 539, bušilica Bosch, iPhone 14...',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Unesite naslov oglasa.';
                      if (v.trim().length < 4) return 'Naslov mora imati najmanje 4 karaktera.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Izbor kategorije
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kategorija *'),
                    subtitle: Text(
                      _selectedCategoryId != null
                          ? (_selectedCategoryName ?? _selectedCategoryId!)
                          : 'Kliknite da izaberete kategoriju',
                      style: TextStyle(
                        color: _selectedCategoryId != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: _selectedCategoryId != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openCategoryPicker(context),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Tip cene
                  DropdownButtonFormField<String>(
                    initialValue: _priceType,
                    decoration: const InputDecoration(labelText: 'Način formiranja cene'),
                    items: const [
                      DropdownMenuItem(value: 'fixed', child: Text('Fiksna cena')),
                      DropdownMenuItem(value: 'negotiable', child: Text('Cena po dogovoru')),
                      DropdownMenuItem(value: 'call', child: Text('Pozvati za cenu')),
                      DropdownMenuItem(value: 'free', child: Text('Besplatno (poklanjam)')),
                    ],
                    onChanged: (v) => setState(() => _priceType = v ?? 'fixed'),
                  ),
                  const SizedBox(height: 16),

                  // Iznos cene i valuta (ako nije besplatno ili poziv)
                  if (_priceType == 'fixed' || _priceType == 'negotiable')
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: _priceType == 'fixed' ? 'Cena *' : 'Okvirna cena',
                              hintText: 'npr. 2500',
                            ),
                            validator: (v) {
                              if (_priceType == 'fixed' && (v == null || v.trim().isEmpty)) {
                                return 'Unesite cenu.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            decoration: const InputDecoration(labelText: 'Valuta'),
                            items: const [
                              DropdownMenuItem(value: 'RSD', child: Text('RSD (din)')),
                              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                            ],
                            onChanged: (v) => setState(() => _currency = v ?? 'RSD'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Stanje predmeta
                  DropdownButtonFormField<String>(
                    initialValue: _condition,
                    decoration: const InputDecoration(labelText: 'Stanje predmeta'),
                    items: const [
                      DropdownMenuItem(value: 'used', child: Text('Polovno')),
                      DropdownMenuItem(value: 'new', child: Text('Novo / Nekorišćeno')),
                      DropdownMenuItem(value: 'not_applicable', child: Text('Nije primenjivo / Usluga')),
                    ],
                    onChanged: (v) => setState(() => _condition = v ?? 'used'),
                  ),
                  const SizedBox(height: 16),

                  // Grad / Lokacija
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Grad ili mesto *',
                      hintText: 'npr. Čačak, Kragujevac, Zlatibor...',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Unesite grad ili mesto.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kontakt telefon
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Kontakt telefon',
                      hintText: 'npr. 064 123 4567',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Prikaži telefon javno u oglasu'),
                    subtitle: const Text('Ako isključite, kupci vas mogu kontaktirati samo preko četa.'),
                    value: _phonePublic,
                    onChanged: (v) => setState(() => _phonePublic = v),
                  ),
                  const SizedBox(height: 16),

                  // Opis oglasa
                  TextFormField(
                    controller: _descController,
                    maxLines: 5,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Detaljan opis',
                      hintText: 'Opišite stanje, karakteristike, razlog prodaje, zamene itd.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dugme za objavu
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Sačuvaj izmene' : 'Objavi oglas',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
