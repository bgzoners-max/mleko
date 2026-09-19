import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';
import '../../utils/number_input_utils.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/grouped_category_dropdown.dart';
import '../../providers/categories_provider.dart';
import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../widgets/cupertino_category_picker.dart';

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
  final _orderStepController = TextEditingController();
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
  final _deliveryService = SellerDeliveryService();
  String? _error;
  bool _loading = false;
  bool _deliveryPointsLoading = true;
  List<SellerDeliveryPointModel> _sellerDeliveryPoints = const [];
  ProductDeliveryMode _deliveryMode = ProductDeliveryMode.none;
  final Set<String> _selectedDeliveryPointIds = <String>{};
  DateTime? _existingCreatedAt;

  bool get isEdit => widget.productId != null && widget.productId!.isNotEmpty;

  String? _firstSelectableCategory(List<CategoryGroup>? groups) {
    if (groups == null) return null;
    for (final group in groups) {
      if (group.selectable.isNotEmpty) {
        return group.selectable.first.name;
      }
    }
    return null;
  }

  String? _resolveEffectiveCategory() {
    final selected = _category?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }

    final provider = context.read<CategoriesProvider>();
    return _firstSelectableCategory(provider.groups) ??
        provider.categoryNames.firstOrNull;
  }

  void _exitScreen() {
    if (isEdit && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('/search?view=products');
  }

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
    _loadSellerDeliveryPoints();
    if (isEdit) _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _minOrderController.dispose();
    _orderStepController.dispose();
    _availableController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<CategoriesProvider>().load();
  }

  Future<void> _load() async {
    final p =
        await context.read<ProductsService>().getProduct(widget.productId!);
    if (p != null && mounted) {
      _nameController.text = p.name;
      _priceController.text = p.pricePerKg.toString();
      _minOrderController.text = p.isVolumeUnit
          ? (p.minOrderKg < 1
              ? '${(p.minOrderKg * 1000).round()}'
              : p.minOrderKg.toString())
          : p.minOrderKg.toString();
      if (p.orderStep != null && p.orderStep! > 0) {
        _orderStepController.text = p.isVolumeUnit
            ? (p.orderStep! < 1
                ? '${(p.orderStep! * 1000).round()}'
                : p.orderStep!.toString())
            : p.orderStep!.toString();
      } else {
        _orderStepController.text = '';
      }
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
      _deliveryMode = p.deliveryMode;
      _selectedDeliveryPointIds
        ..clear()
        ..addAll(p.selectedDeliveryPointIds);
      _imageUrls =
          List<String>.from(p.imageUrls.take(AppConstants.maxProductImages));
      _existingCreatedAt = p.createdAt;
      setState(() {});
    }
  }

  Future<void> _loadSellerDeliveryPoints() async {
    final sellerId = context.read<AppState>().user?.id;
    if (sellerId == null) {
      if (mounted) {
        setState(() {
          _sellerDeliveryPoints = const [];
          _deliveryPointsLoading = false;
        });
      }
      return;
    }

    try {
      final points = await _deliveryService.getSellerDeliveryPoints(sellerId);
      if (!mounted) return;
      final pointIds = points.map((point) => point.id).toSet();
      setState(() {
        _sellerDeliveryPoints = points;
        _selectedDeliveryPointIds.removeWhere((id) => !pointIds.contains(id));
        if (_deliveryMode != ProductDeliveryMode.none && points.isEmpty) {
          _deliveryMode = ProductDeliveryMode.none;
        }
        _deliveryPointsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sellerDeliveryPoints = const [];
        _deliveryPointsLoading = false;
      });
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
        imageQuality: kIsWeb ? null : 85,
        maxWidth: kIsWeb ? null : 1200,
        limit: remaining,
      );
      if (files.isEmpty || !mounted) return;
      final newBytes = <Uint8List>[];
      for (final f in files.take(remaining)) {
        final bytes = await f.readAsBytes();
        final sizeError = checkFileSize(bytes);
        if (sizeError != null) {
          if (mounted) _showErrorDialog(sizeError);
          return;
        }
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
    final productsService = context.read<ProductsService>();
    final effectiveCategory = _resolveEffectiveCategory();
    final effectiveLocation = (_location?.trim().isNotEmpty ?? false)
        ? _location!.trim()
        : AppConstants.regions.first;

    if (user == null || !user.isSeller) {
      _showErrorDialog(
          'Niste prijavljeni kao prodavac. Izloguj se i registruj ponovo sa ulogom Prodavac.');
      return;
    }
    final missingFields = <String>[];
    if (_nameController.text.trim().isEmpty) missingFields.add('naziv');
    if (effectiveCategory == null || effectiveCategory.isEmpty) {
      missingFields.add('kategorija');
    }
    if (effectiveLocation.isEmpty) missingFields.add('lokacija');
    if (_pickupOptions.isEmpty) missingFields.add('način preuzimanja');

    if (missingFields.isNotEmpty) {
      final msg =
          '${missingFields.join(', ')} ${missingFields.length == 1 ? 'je obavezan' : 'su obavezni'}.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    if (_deliveryMode != ProductDeliveryMode.none &&
        _sellerDeliveryPoints.isEmpty) {
      const msg =
          'Najpre dodaj aktivne lokacije lične dostave u podešavanjima prodavca.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    if (_deliveryMode == ProductDeliveryMode.selectedPoints &&
        _selectedDeliveryPointIds.isEmpty) {
      const msg =
          'Izaberite bar jednu lokaciju za ličnu dostavu ovog proizvoda.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    final price = NumberInputUtils.parseDecimal(_priceController.text);
    final minOrder = _unitType == ProductModel.unitL
        ? ProductModel.parseQuantityL(_minOrderController.text)
        : (NumberInputUtils.parseDecimal(_minOrderController.text) ?? 1.0);
    final available = _unitType == ProductModel.unitL
        ? ProductModel.parseQuantityL(_availableController.text)
        : (NumberInputUtils.parseDecimal(_availableController.text) ?? 0.0);
    final parsedOrderStep = _orderStepController.text.trim().isNotEmpty
        ? (_unitType == ProductModel.unitL
            ? ProductModel.parseQuantityL(_orderStepController.text)
            : NumberInputUtils.parseDecimal(_orderStepController.text))
        : null;

    final resolvedStep = (parsedOrderStep != null && parsedOrderStep > 0)
        ? parsedOrderStep
        : _resolveOrderStep(
            category: effectiveCategory ?? '',
            name: _nameController.text.trim(),
            unitType: _unitType,
            minOrderKg: minOrder,
          );

    if (price == null || price <= 0) {
      const msg = 'Unesite validnu cenu.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    if (minOrder <= 0) {
      const msg = 'Minimalna porudžbina mora biti veća od 0.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    if (resolvedStep > minOrder) {
      const msg = 'Korak porudžbine ne može biti veći od minimalne porudžbine.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
      return;
    }
    if (resolvedStep <= 0) {
      const msg = 'Korak porudžbine mora biti veći od 0.';
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
      for (var i = 0; i < _newImageBytes.length; i++) {
        final url = await _storageService.uploadProductImage(
            user.id, _newImageBytes[i], imageUrls.length + i);
        imageUrls.add(url);
      }
      imageUrls = imageUrls.take(AppConstants.maxProductImages).toList();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showErrorDialog(friendlyError(e));
      }
      return;
    }
    final product = ProductModel(
      id: widget.productId ?? '',
      sellerId: user.id,
      category: effectiveCategory!,
      name: _nameController.text.trim(),
      pricePerKg: price,
      minOrderKg: minOrder,
      orderStep: resolvedStep,
      availableKg: available,
      unitType: _unitType,
      description: desc,
      imageUrls: imageUrls,
      pickupOptions: _pickupOptions,
      location: effectiveLocation,
      isDomestic: _isDomestic,
      availableNow: _availableNow,
      deliveryMode: _deliveryMode,
      selectedDeliveryPointIds:
          _deliveryMode == ProductDeliveryMode.selectedPoints
              ? _selectedDeliveryPointIds.toList(growable: false)
              : const [],
      createdAt: _existingCreatedAt ?? DateTime.now(),
    );

    // 🚀 NOVI SISTEM: Automatsko logovanje, praćenje performansi i bezbedno hvatanje grešaka
    final result = await ErrorHandlerService().executeWithResult(
      isEdit ? 'Update product' : 'Add product',
      () => isEdit
          ? productsService.updateProduct(product)
          : productsService.addProduct(product),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(isEdit ? 'Proizvod ažuriran.' : 'Proizvod objavljen.')),
      );
      _exitScreen();
    } else {
      final msg =
          result.error?.getUserMessage() ?? 'Nije moguće sačuvati proizvod.';
      setState(() => _error = msg);
      _showErrorDialog(msg);
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
      ProductModel.unitPiece => 1.0,
      _ => suggestedOrderStepKg(
          category: category, name: name, minOrderKg: minOrderKg),
    };

    return math.min(defaultStepByUnit, minOrderKg);
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoriesProvider>();
    final groups = catProvider.groups;
    final hasGroupedCategories = groups != null && groups.isNotEmpty;
    final maxFormWidth = Breakpoints.formContentWidth(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isEdit ? Icons.arrow_back : Icons.close),
          onPressed: _loading ? null : _exitScreen,
        ),
        title: Text(isEdit ? 'Izmeni proizvod' : 'Dodaj proizvod'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFormWidth),
              child: Padding(
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
                        : CupertinoCategoryPicker(
                            initialCategory: _category,
                            onCategoryChanged: (v) {
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
                            child: Text('Litri / ml')),
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
                        decoration:
                            const InputDecoration(labelText: 'Naziv *')),
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
                            ? 'Minimalna porudžbina (L ili ml, npr. 0.75 ili 750) *'
                            : _unitType == ProductModel.unitPiece
                                ? 'Minimalna porudžbina (komada, npr. 10) *'
                                : 'Minimalna porudžbina (kg) *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _orderStepController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: _unitType == ProductModel.unitL
                            ? 'Korak porudžbine (L ili ml, npr. 0.5 ili 500) - opciono'
                            : _unitType == ProductModel.unitPiece
                                ? 'Korak porudžbine (komada, npr. 1 ili 5) - opciono'
                                : 'Korak porudžbine (kg, npr. 0.1 ili 0.5) - opciono',
                        helperText:
                            'Količina za koju se porudžbina menja (mora biti ≤ minimalnoj količini)',
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
                    Text(
                        'Slike proizvoda (max ${AppConstants.maxProductImages})',
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
                                        onPressed: () =>
                                            _removeExistingImage(e.key),
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
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover),
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
                                  border:
                                      Border.all(color: Colors.grey.shade400),
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
                      decoration:
                          const InputDecoration(labelText: 'Lokacija *'),
                      items: AppConstants.regions
                          .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)))
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
                    const SizedBox(height: 8),
                    Text(
                      'Lična dostava domaćina za ovaj proizvod',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_deliveryPointsLoading)
                      const LinearProgressIndicator()
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Text(
                          'Izaberite kako ovaj proizvod koristi vašu ličnu dostavu. Ako prodajete isti proizvod samo u određenom gradu ili na određenoj adresi, koristite opciju "Samo na izabranim lokacijama".',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ignore: deprecated_member_use
                      RadioListTile<ProductDeliveryMode>(
                        value: ProductDeliveryMode.none,
                        // ignore: deprecated_member_use
                        groupValue: _deliveryMode,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bez lične dostave domaćina'),
                        subtitle: const Text(
                          'Koristite ovo ako proizvod nije za vašu organizovanu dostavu. Kupac se može dogovoriti sa vama direktno, ali ne bira vaše definisane punktove i termine.',
                        ),
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _deliveryMode = value);
                        },
                      ),
                      // ignore: deprecated_member_use
                      RadioListTile<ProductDeliveryMode>(
                        value: ProductDeliveryMode.allSellerPoints,
                        // ignore: deprecated_member_use
                        groupValue: _deliveryMode,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Na svim mojim lokacijama'),
                        subtitle: const Text(
                          'Koristite ovo ako ovaj proizvod može da ide na svaki vaš aktivan punkt dostave. Kupac bira bilo koji grad, adresu i termin koje ste već definisali.',
                        ),
                        // ignore: deprecated_member_use
                        onChanged: _sellerDeliveryPoints.isEmpty
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _deliveryMode = value);
                              },
                      ),
                      // ignore: deprecated_member_use
                      RadioListTile<ProductDeliveryMode>(
                        value: ProductDeliveryMode.selectedPoints,
                        // ignore: deprecated_member_use
                        groupValue: _deliveryMode,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Samo na izabranim lokacijama'),
                        subtitle: const Text(
                          'Koristite ovo kada proizvod nosite samo na određene gradove ili adrese. Ispod zatim čekirate tačne punktove na kojima je proizvod dostupan.',
                        ),
                        // ignore: deprecated_member_use
                        onChanged: _sellerDeliveryPoints.isEmpty
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _deliveryMode = value);
                              },
                      ),
                      if (_sellerDeliveryPoints.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Još nemate definisane lokacije lične dostave. Prvo ih dodajte u Seller Settings, pa se vratite ovde da uključite dostavu po proizvodu.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      if (_deliveryMode == ProductDeliveryMode.selectedPoints &&
                          _sellerDeliveryPoints.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Čekirajte samo one lokacije na kojima kupac stvarno može da poruči ovaj proizvod.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                      if (_deliveryMode == ProductDeliveryMode.selectedPoints &&
                          _sellerDeliveryPoints.isNotEmpty)
                        ..._sellerDeliveryPoints.map(
                          (point) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(point.summaryLabel),
                            subtitle: Text(
                              point.isActive
                                  ? '${point.city} • ${point.activeSlots.length} aktivnih termina'
                                  : '${point.city} • neaktivna lokacija',
                            ),
                            value: _selectedDeliveryPointIds.contains(point.id),
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedDeliveryPointIds.add(point.id);
                                } else {
                                  _selectedDeliveryPointIds.remove(point.id);
                                }
                              });
                            },
                          ),
                        ),
                    ],
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
          ),
        ),
      ),
    );
  }
}
