import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/grouped_category_dropdown.dart';
import '../../providers/app_state.dart';
import '../../providers/categories_provider.dart';
import '../../services/products_service.dart';
import '../../services/storage_service.dart';

/// Ekran za dodavanje novog proizvoda. Samostalan, koristi go() za navigaciju.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _minOrderController = TextEditingController(text: '1');
  final _availableController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();

  String _category = '';
  String _unitType = ProductModel.unitKg;
  String _location = AppConstants.regions.first;
  final List<String> _pickupOptions = [AppConstants.pickupOptions.first];
  bool _isDomestic = true;
  bool _availableNow = true;
  bool _saving = false;
  final List<Uint8List> _imageBytes = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CategoriesProvider>().load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _minOrderController.dispose();
    _availableController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageBytes.length >= AppConstants.maxProductImages) {
      _showError('Maksimalno ${AppConstants.maxProductImages} slika.');
      return;
    }
    try {
      final remaining = AppConstants.maxProductImages - _imageBytes.length;
      final files = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1200,
        limit: remaining,
      );
      if (files.isEmpty || !mounted) return;
      final newBytes = <Uint8List>[];
      for (final f in files.take(remaining)) {
        final bytes = await f.readAsBytes();
        newBytes.add(Uint8List.fromList(bytes));
      }
      if (mounted) setState(() => _imageBytes.addAll(newBytes));
    } catch (e) {
      if (mounted) _showError('Greška pri izboru slika.');
    }
  }

  void _removeImage(int index) {
    setState(() => _imageBytes.removeAt(index));
  }

  Future<void> _save() async {
    if (_saving) return;

    if (_pickupOptions.isEmpty) {
      _showError('Izaberite bar jedan način preuzimanja.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = context.read<AppState>().user;
    if (user == null || !user.isSeller) {
      _showError('Niste prijavljeni kao prodavac.');
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      _showError('Unesite validnu cenu.');
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.length > AppConstants.maxProductDescriptionLength) {
      _showError('Opis može imati najviše ${AppConstants.maxProductDescriptionLength} karaktera.');
      return;
    }

    setState(() => _saving = true);

    try {
      List<String> imageUrls = [];
      for (var i = 0; i < _imageBytes.length; i++) {
        final url = await _storageService.uploadProductImage(user.id, _imageBytes[i], i);
        imageUrls.add(url);
      }

      final minOrder = _unitType == ProductModel.unitL
          ? ProductModel.parseQuantityL(_minOrderController.text)
          : _unitType == ProductModel.unitG
              ? ProductModel.parseQuantityG(_minOrderController.text)
              : (double.tryParse(_minOrderController.text.replaceAll(',', '.')) ?? 1);
      final available = _unitType == ProductModel.unitL
          ? ProductModel.parseQuantityL(_availableController.text)
          : _unitType == ProductModel.unitG
              ? ProductModel.parseQuantityG(_availableController.text)
              : (double.tryParse(_availableController.text.replaceAll(',', '.')) ?? 0);
      final product = ProductModel(
        id: '',
        sellerId: user.id,
        category: _category,
        name: _nameController.text.trim(),
        pricePerKg: price,
        minOrderKg: minOrder,
        availableKg: available,
        unitType: _unitType,
        description: desc,
        imageUrls: imageUrls,
        pickupOptions: List.from(_pickupOptions),
        location: _location,
        isDomestic: _isDomestic,
        availableNow: _availableNow,
        createdAt: DateTime.now(),
      );

      await ProductsService().addProduct(product).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Prekoračeno vreme. Proveri internet.'),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proizvod je uspešno dodat.')),
      );
      context.go('/search');
    } on TimeoutException {
      if (mounted) _showError('Čuvanje traje predugo. Proveri internet.');
    } catch (e) {
      if (mounted) _showError('Greška: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Greška'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoriesProvider>();
    final groups = catProvider.groups;
    final categoryList = catProvider.categoryNames;
    final hasGroupedCategories = groups != null && groups.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj proizvod'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => context.go('/search'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
            ),
            children: [
            // Slike proizvoda
            Text('Slike (opciono, max ${AppConstants.maxProductImages})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._imageBytes.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(e.value, width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                onPressed: () => _removeImage(e.key),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (_imageBytes.length < AppConstants.maxProductImages)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            hasGroupedCategories
                ? GroupedCategoryDropdown(
                    groups: groups,
                    value: _category,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _category = v;
                          if (isVolumeCategory(v)) _unitType = ProductModel.unitL;
                        });
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Izaberite kategoriju' : null,
                  )
                : DropdownButtonFormField<String>(
                    key: ValueKey(_category),
                    initialValue: categoryList.contains(_category) ? _category : (categoryList.isNotEmpty ? categoryList.first : null),
                    decoration: const InputDecoration(labelText: 'Kategorija *'),
                    items: categoryList
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _category = v;
                          if (isVolumeCategory(v)) _unitType = ProductModel.unitL;
                        });
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Izaberite kategoriju' : null,
                  ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _unitType,
              decoration: const InputDecoration(labelText: 'Jedinica'),
              items: const [
                DropdownMenuItem(value: ProductModel.unitKg, child: Text('Kilogrami (kg)')),
                DropdownMenuItem(value: ProductModel.unitL, child: Text('Litri / ml (tečnosti, zimnica, tegle)')),
                DropdownMenuItem(value: ProductModel.unitG, child: Text('Grami (g)')),
                DropdownMenuItem(value: ProductModel.unitPiece, child: Text('Komadi (kom)')),
              ],
              onChanged: (v) => setState(() => _unitType = v ?? ProductModel.unitKg),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Naziv *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Naziv je obavezan' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _unitType == ProductModel.unitL
                    ? 'Cena po litru (RSD) *'
                    : _unitType == ProductModel.unitPiece
                        ? 'Cena po komadu (RSD) *'
                        : 'Cena po kg (RSD) *',
                hintText: 'npr. 500',
              ),
              validator: (v) {
                final p = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (p == null || p <= 0) ? 'Unesite validnu cenu (broj > 0)' : null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minOrderController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _unitType == ProductModel.unitL
                    ? 'Minimalna porudžbina (L ili ml, npr. 0.75 ili 750)'
                    : _unitType == ProductModel.unitG
                        ? 'Minimalna porudžbina (g, npr. 100)'
                        : _unitType == ProductModel.unitPiece
                            ? 'Minimalna porudžbina (komada, npr. 10)'
                            : 'Minimalna porudžbina (kg)',
                hintText: _unitType == ProductModel.unitL
                    ? '0.75 ili 750'
                    : _unitType == ProductModel.unitG
                        ? '100'
                        : _unitType == ProductModel.unitPiece
                            ? '10'
                            : '1',
              ),
              validator: (v) {
                final p = _unitType == ProductModel.unitL
                    ? ProductModel.parseQuantityL(v ?? '')
                    : _unitType == ProductModel.unitG
                        ? ProductModel.parseQuantityG(v ?? '')
                        : double.tryParse((v ?? '').replaceAll(',', '.'));
                return (p != null && p < 0) ? 'Minimalna vrednost je 0' : null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _availableController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _unitType == ProductModel.unitL
                    ? 'Dostupna količina (L ili ml)'
                    : _unitType == ProductModel.unitG
                        ? 'Dostupna količina (g)'
                        : _unitType == ProductModel.unitPiece
                            ? 'Dostupna količina (komada)'
                            : 'Dostupna količina (kg)',
                hintText: '0',
              ),
              validator: (v) {
                final p = _unitType == ProductModel.unitL
                    ? ProductModel.parseQuantityL(v ?? '')
                    : _unitType == ProductModel.unitG
                        ? ProductModel.parseQuantityG(v ?? '')
                        : double.tryParse((v ?? '').replaceAll(',', '.'));
                return (p != null && p < 0) ? 'Minimalna vrednost je 0' : null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: AppConstants.maxProductDescriptionLength,
              decoration: const InputDecoration(
                labelText: 'Opis (max ${AppConstants.maxProductDescriptionLength} karaktera)',
                counterText: '',
              ),
              validator: (v) => (v != null && v.length > AppConstants.maxProductDescriptionLength)
                  ? 'Maksimalno ${AppConstants.maxProductDescriptionLength} karaktera'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_location),
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Lokacija *'),
              items: AppConstants.regions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => v != null ? setState(() => _location = v) : null,
              validator: (v) => v == null || v.isEmpty ? 'Izaberite lokaciju' : null,
            ),
            const SizedBox(height: 16),
            Text('Način preuzimanja *', style: Theme.of(context).textTheme.titleSmall),
            ...AppConstants.pickupOptions.map((opt) => CheckboxListTile(
                  title: Text(opt),
                  value: _pickupOptions.contains(opt),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _pickupOptions.add(opt);
                      } else {
                        _pickupOptions.remove(opt);
                      }
                    });
                  },
                )),
            SwitchListTile(
              title: const Text('Domaće gazdinstvo'),
              value: _isDomestic,
              onChanged: (v) => setState(() => _isDomestic = v),
            ),
            SwitchListTile(
              title: const Text('Dostupno sada'),
              value: _availableNow,
              onChanged: (v) => setState(() => _availableNow = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Objavi proizvod'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
