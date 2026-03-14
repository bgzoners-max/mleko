import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/grouped_category_dropdown.dart';
import '../../providers/categories_provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_state.dart';
import '../../services/products_service.dart';
import '../../services/storage_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _minOrderController = TextEditingController(text: '1');
  final _availableController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _category;
  String _unitType = ProductModel.unitKg;
  String? _location = AppConstants.regions.first;
  List<String> _pickupOptions = [
    AppConstants.pickupOptions.first
  ]; // bar jedan način preuzimanja
  bool _isDomestic = true;
  bool _availableNow = true;
  List<String> _imageUrls = [];
  final List<Uint8List> _newImageBytes = [];
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  String? _error;
  bool _loading = false;

  bool get isEdit => widget.productId != null && widget.productId!.isNotEmpty;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Greška'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (isEdit) _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CategoriesProvider>().load();
  }

  Future<void> _load() async {
    final p = await ProductsService().getProduct(widget.productId!);
    if (p != null && mounted) {
      _nameController.text = p.name;
      _priceController.text = p.pricePerKg.toString();
      _minOrderController.text = p.isVolumeUnit
          ? (p.minOrderKg < 1
              ? '${(p.minOrderKg * 1000).round()}'
              : p.minOrderKg.toString())
          : p.minOrderKg.toString();
      _availableController.text = p.isVolumeUnit
          ? (p.availableKg < 1
              ? '${(p.availableKg * 1000).round()}'
              : p.availableKg.toString())
          : p.availableKg.toString();
      _descriptionController.text = p.description;
      _category = p.category;
      _unitType = p.unitType;
      _location = p.location;
      _pickupOptions = List.from(p.pickupOptions);
      _isDomestic = p.isDomestic;
      _availableNow = p.availableNow;
      _imageUrls =
          List<String>.from(p.imageUrls.take(AppConstants.maxProductImages));
      setState(() {});
    }
  }

  int get _totalImages => _imageUrls.length + _newImageBytes.length;

  Future<void> _pickImage() async {
    if (_totalImages >= AppConstants.maxProductImages) {
      _showErrorDialog('Maksimalno ${AppConstants.maxProductImages} slike.');
      return;
    }
    try {
      final remaining = AppConstants.maxProductImages - _totalImages;
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
      if (mounted) setState(() => _newImageBytes.addAll(newBytes));
    } catch (e) {
      if (mounted) _showErrorDialog('Greška pri izboru slika.');
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImageBytes.removeAt(index));
  }

  Future<void> _submit() async {
    final user = context.read<AppState>().user;
    if (user == null || !user.isSeller) {
      _showErrorDialog(
          'Niste prijavljeni kao prodavac. Izloguj se i registruj ponovo sa ulogom Prodavac.');
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _category == null ||
        _location == null ||
        _pickupOptions.isEmpty) {
      const msg =
          'Naziv, kategorija, lokacija i način preuzimanja su obavezni.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final minOrder = _unitType == ProductModel.unitL
        ? ProductModel.parseQuantityL(_minOrderController.text)
        : _unitType == ProductModel.unitG
            ? ProductModel.parseQuantityG(_minOrderController.text)
            : (double.tryParse(_minOrderController.text.replaceAll(',', '.')) ??
                1);
    final available = _unitType == ProductModel.unitL
        ? ProductModel.parseQuantityL(_availableController.text)
        : _unitType == ProductModel.unitG
            ? ProductModel.parseQuantityG(_availableController.text)
            : (double.tryParse(
                    _availableController.text.replaceAll(',', '.')) ??
                0);
    if (price == null || price <= 0) {
      const msg = 'Unesite validnu cenu.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    final desc = _descriptionController.text.trim();
    if (desc.length > AppConstants.maxProductDescriptionLength) {
      const msg =
          'Opis max ${AppConstants.maxProductDescriptionLength} karaktera.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    List<String> imageUrls = List.from(_imageUrls);
    try {
      final user = context.read<AppState>().user!;
      for (var i = 0; i < _newImageBytes.length; i++) {
        final url = await _storageService.uploadProductImage(
            user.id, _newImageBytes[i], imageUrls.length + i);
        imageUrls.add(url);
      }
      imageUrls = imageUrls.take(AppConstants.maxProductImages).toList();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showErrorDialog('Greška pri upload-u slika: $e');
      }
      return;
    }
    final product = ProductModel(
      id: widget.productId ?? '',
      sellerId: user.id,
      category: _category!,
      name: _nameController.text.trim(),
      pricePerKg: price,
      minOrderKg: minOrder,
      orderStep: _resolveOrderStep(
        category: _category!,
        name: _nameController.text.trim(),
        unitType: _unitType,
        minOrderKg: minOrder,
      ),
      availableKg: available,
      unitType: _unitType,
      description: desc,
      imageUrls: imageUrls,
      pickupOptions: _pickupOptions,
      location: _location!,
      isDomestic: _isDomestic,
      availableNow: _availableNow,
      createdAt: DateTime.now(),
    );
    try {
      if (isEdit) {
        await ProductsService().updateProduct(product).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                  'Čuvanje traje predugo. Proveri internet i Supabase.'),
            );
      } else {
        await ProductsService().addProduct(product).timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                  'Čuvanje traje predugo. Proveri internet i Supabase.'),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'Proizvod ažuriran.' : 'Proizvod objavljen.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        const msg = 'Čuvanje traje predugo. Proveri internet i Supabase.';
        setState(() => _error = msg);
        _showErrorDialog(msg);
      }
    } catch (e) {
      if (mounted) {
        final msg =
            e.toString().replaceFirst('Exception: ', '').split('\n').first;
        setState(() => _error = 'Greška pri čuvanju proizvoda: $msg');
        _showErrorDialog('Nije moguće sačuvati proizvod.\n\n$msg');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _resolveOrderStep({
    required String category,
    required String name,
    required String unitType,
    required double minOrderKg,
  }) {
    if (minOrderKg <= 0) {
      return 0.1;
    }

    final defaultStepByUnit = switch (unitType) {
      ProductModel.unitL => 1.0,
      ProductModel.unitG => 0.05,
      ProductModel.unitPiece => 10.0,
      _ => suggestedOrderStepKg(
          category: category, name: name, minOrderKg: minOrderKg),
    };

    return math.min(defaultStepByUnit, minOrderKg);
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoriesProvider>();
    final groups = catProvider.groups;
    final categoryList = catProvider.categoryNames;
    final hasGroupedCategories = groups != null && groups.isNotEmpty;
    return Scaffold(
      appBar:
          AppBar(title: Text(isEdit ? 'Izmeni proizvod' : 'Dodaj proizvod')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hasGroupedCategories
                  ? GroupedCategoryDropdown(
                      groups: groups,
                      value: _category,
                      onChanged: (v) {
                        setState(() {
                          _category = v;
                          if (v != null && isVolumeCategory(v)) {
                            _unitType = ProductModel.unitL;
                          }
                        });
                      },
                      validator: (v) => v == null || v.isEmpty
                          ? 'Izaberite kategoriju'
                          : null,
                    )
                  : DropdownButtonFormField<String>(
                      key: ValueKey(_category),
                      initialValue:
                          _category != null && categoryList.contains(_category)
                              ? _category
                              : (categoryList.isNotEmpty
                                  ? categoryList.first
                                  : null),
                      decoration:
                          const InputDecoration(labelText: 'Kategorija *'),
                      items: categoryList
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _category = v;
                          if (v != null && isVolumeCategory(v)) {
                            _unitType = ProductModel.unitL;
                          }
                        });
                      },
                    ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _unitType,
                decoration: const InputDecoration(labelText: 'Jedinica'),
                items: const [
                  DropdownMenuItem(
                      value: ProductModel.unitKg,
                      child: Text('Kilogrami (kg)')),
                  DropdownMenuItem(
                      value: ProductModel.unitL,
                      child: Text('Litri / ml (tečnosti, zimnica, tegle)')),
                  DropdownMenuItem(
                      value: ProductModel.unitG, child: Text('Grami (g)')),
                  DropdownMenuItem(
                      value: ProductModel.unitPiece,
                      child: Text('Komadi (kom)')),
                ],
                onChanged: (v) =>
                    setState(() => _unitType = v ?? ProductModel.unitKg),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Naziv *')),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _unitType == ProductModel.unitL
                      ? 'Cena po litru (RSD) *'
                      : _unitType == ProductModel.unitPiece
                          ? 'Cena po komadu (RSD) *'
                          : 'Cena po kg (RSD) *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minOrderController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _unitType == ProductModel.unitL
                      ? 'Minimalna porudžbina (L ili ml, npr. 0.75 ili 750)'
                      : _unitType == ProductModel.unitG
                          ? 'Minimalna porudžbina (g, npr. 100)'
                          : _unitType == ProductModel.unitPiece
                              ? 'Minimalna porudžbina (komada, npr. 10)'
                              : 'Minimalna porudžbina (kg)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _availableController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _unitType == ProductModel.unitL
                      ? 'Dostupna količina (L ili ml)'
                      : _unitType == ProductModel.unitG
                          ? 'Dostupna količina (g)'
                          : _unitType == ProductModel.unitPiece
                              ? 'Dostupna količina (komada)'
                              : 'Dostupna količina (kg)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: AppConstants.maxProductDescriptionLength,
                decoration: const InputDecoration(
                    labelText: 'Opis (max 300 karaktera)'),
              ),
              const SizedBox(height: 16),
              Text('Slike proizvoda (max ${AppConstants.maxProductImages})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imageUrls.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: e.value,
                                  width: 100,
                                  memCacheWidth: 200,
                                  memCacheHeight: 200,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54),
                                  onPressed: () => _removeExistingImage(e.key),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ..._newImageBytes.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(e.value,
                                    width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54),
                                  onPressed: () => _removeNewImage(e.key),
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (_totalImages < AppConstants.maxProductImages)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add_photo_alternate,
                              size: 40, color: Colors.grey.shade400),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_location),
                initialValue: _location,
                decoration: const InputDecoration(labelText: 'Lokacija *'),
                items: AppConstants.regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _location = v),
              ),
              const SizedBox(height: 16),
              Text('Način preuzimanja *',
                  style: Theme.of(context).textTheme.labelLarge),
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
                title: const Text('Domaće / Porodično gazdinstvo'),
                value: _isDomestic,
                onChanged: (v) => setState(() => _isDomestic = v),
              ),
              SwitchListTile(
                title: const Text('Dostupno sada'),
                value: _availableNow,
                onChanged: (v) => setState(() => _availableNow = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Sačuvaj' : 'Objavi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
