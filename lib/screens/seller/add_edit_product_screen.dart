import 'dart:async';
import 'dart:math' as math;

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
import '../../providers/categories_provider.dart';
import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../providers/app_state.dart';
import '../../services/media/image_compression_service.dart';
import '../../services/services.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/seller/product_basic_info_section.dart';
import '../../widgets/seller/product_delivery_section.dart';
import '../../widgets/seller/product_images_section.dart';

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
    if (Navigator.of(context).canPop()) {
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
      final filesToProcess = files.take(remaining).toList();
      final readFutures = filesToProcess.map((f) async {
        try {
          return await f.readAsBytes();
        } catch (err) {
          debugPrint('Greška pri čitanju fajla ${f.name}: $err');
          return null;
        }
      }).toList();
      final allBytes = await Future.wait(readFutures);

      final compressionService = ImageCompressionService();
      final newBytes = <Uint8List>[];
      for (final bytes in allBytes) {
        if (bytes == null) continue;
        final sizeError = checkFileSize(bytes);
        if (sizeError != null) {
          if (mounted) _showErrorDialog(sizeError);
          return;
        }
        final normalized = await compressionService.compressImage(Uint8List.fromList(bytes));
        newBytes.add(normalized);
      }
      if (mounted && newBytes.isNotEmpty) setState(() => _newImageBytes.addAll(newBytes));
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
        : (_unitType == ProductModel.unitKg
            ? ProductModel.parseQuantityKg(_minOrderController.text)
            : (NumberInputUtils.parseDecimal(_minOrderController.text) ?? 1.0));
    final available = _unitType == ProductModel.unitL
        ? ProductModel.parseQuantityL(_availableController.text)
        : (_unitType == ProductModel.unitKg
            ? ProductModel.parseQuantityKg(_availableController.text)
            : (NumberInputUtils.parseDecimal(_availableController.text) ?? 0.0));
    final parsedOrderStep = _orderStepController.text.trim().isNotEmpty
        ? (_unitType == ProductModel.unitL
            ? ProductModel.parseQuantityL(_orderStepController.text)
            : (_unitType == ProductModel.unitKg
                ? ProductModel.parseQuantityKg(_orderStepController.text)
                : NumberInputUtils.parseDecimal(_orderStepController.text)))
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
      if (_newImageBytes.isNotEmpty) {
        final uploadFutures = _newImageBytes.asMap().entries.map((entry) async {
          final index = entry.key;
          final bytes = entry.value;
          final url = await _storageService.uploadProductImage(
            user.id,
            bytes,
            imageUrls.length + index,
          );
          return MapEntry(index, url);
        }).toList();

        final uploadedEntries = await Future.wait(uploadFutures);
        uploadedEntries.sort((a, b) => a.key.compareTo(b.key));
        imageUrls.addAll(uploadedEntries.map((e) => e.value));
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
      ProductModel.unitVeza => 1.0,
      ProductModel.unitPak => 1.0,
      _ => suggestedOrderStepKg(
          category: category, name: name, minOrderKg: minOrderKg),
    };

    return math.min(defaultStepByUnit, minOrderKg);
  }

  String? _formatQuantityHint(String text, String unitType) {
    final raw = text.trim();
    if (raw.isEmpty) return null;
    if (unitType == ProductModel.unitKg) {
      final qty = ProductModel.parseQuantityKg(raw);
      if (qty > 0) {
        return 'Prikaz kupcima: ${ProductModel.formatQuantityWithUnit(qty, ProductModel.unitKg)}';
      }
    } else if (unitType == ProductModel.unitL) {
      final qty = ProductModel.parseQuantityL(raw);
      if (qty > 0) {
        return 'Prikaz kupcima: ${ProductModel.formatQuantityWithUnit(qty, ProductModel.unitL)}';
      }
    }
    return null;
  }

  Future<void> _confirmDelete() async {
    if (!isEdit || widget.productId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Trajno brisanje proizvoda'),
              content: Text(
                'Da li ste sigurni da želite trajno da obrišete proizvod „${_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'ovaj proizvod'}”? Ova akcija se ne može poništiti.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          try {
                            await context
                                .read<ProductsService>()
                                .deleteProduct(widget.productId!);
                            if (ctx.mounted) {
                              Navigator.pop(ctx, true);
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Greška pri brisanju: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Trajno obriši'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proizvod je uspešno obrisan.')),
      );
      _exitScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoriesProvider>();
    final groups = catProvider.groups;
    final maxFormWidth = Breakpoints.formContentWidth(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(isEdit ? Icons.arrow_back : Icons.close),
          onPressed: _loading ? null : _exitScreen,
        ),
        title: Text(isEdit ? 'Izmeni proizvod' : 'Dodaj proizvod'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Trajno obriši proizvod',
              onPressed: _loading ? null : _confirmDelete,
            ),
          const AppHomeButton(),
        ],
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
                    ProductBasicInfoSection(
                      groups: groups,
                      category: _category,
                      onCategoryChanged: (v) =>
                          setState(() => _category = v),
                      unitType: _unitType,
                      onUnitTypeChanged: (v) =>
                          setState(() => _unitType = v),
                      nameController: _nameController,
                      priceController: _priceController,
                      minOrderController: _minOrderController,
                      orderStepController: _orderStepController,
                      availableController: _availableController,
                      quantityHintBuilder: _formatQuantityHint,
                      onChanged: () => setState(() {}),
                    ),
// BASIC-SECTION-END
                    const SizedBox(height: 16),
                    ProductImagesSection(
                      imageUrls: _imageUrls,
                      newImageBytes: _newImageBytes,
                      onRemoveExisting: _removeExistingImage,
                      onRemoveNew: _removeNewImage,
                      onPickImage: _pickImage,
                    ),
                    const SizedBox(height: 16),
                    ProductDeliverySection(
                      location: _location,
                      onLocationChanged: (v) => setState(() => _location = v),
                      pickupOptions: _pickupOptions,
                      onPickupOptionToggled: (opt) => setState(() {
                        if (_pickupOptions.contains(opt)) {
                          _pickupOptions.remove(opt);
                        } else {
                          _pickupOptions.add(opt);
                        }
                      }),
                      deliveryPointsLoading: _deliveryPointsLoading,
                      sellerDeliveryPoints: _sellerDeliveryPoints,
                      deliveryMode: _deliveryMode,
                      onDeliveryModeChanged: (v) => setState(() => _deliveryMode = v),
                      selectedDeliveryPointIds: _selectedDeliveryPointIds,
                      onDeliveryPointToggled: (id) => setState(() {
                        if (_selectedDeliveryPointIds.contains(id)) {
                          _selectedDeliveryPointIds.remove(id);
                        } else {
                          _selectedDeliveryPointIds.add(id);
                        }
                      }),
                      descriptionController: _descriptionController,
                      isDomestic: _isDomestic,
                      onDomesticChanged: (v) => setState(() => _isDomestic = v),
                      availableNow: _availableNow,
                      onAvailableNowChanged: (v) => setState(() => _availableNow = v),
                    ),
                    const SizedBox(height: 16),
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
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: _loading ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Trajno obriši proizvod'),
                      ),
                    ],
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
