import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/serbian_cities.dart';
import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';

import '../../models/classified_ad_model.dart';
import '../../models/classified_category_model.dart';

import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/media/image_compression_service.dart';
import '../../services/media/storage_service.dart';
import '../../utils/classified_attributes_engine.dart';
import '../../utils/number_input_utils.dart';
import '../../widgets/app_back_button.dart';

import '../../widgets/classifieds/add_edit/classified_attributes_section.dart';
import '../../widgets/classifieds/add_edit/classified_seller_type_section.dart';
import '../../widgets/classifieds/add_edit/classified_promotion_section.dart';
import '../../widgets/classifieds/add_edit/classified_image_picker_row.dart';
import '../../widgets/classifieds/add_edit/category_selection_modal.dart';
import '../../widgets/classifieds/add_edit/classified_city_autocomplete.dart';
import '../../widgets/classifieds/add_edit/classified_submit_button.dart';
import '../../widgets/classifieds/add_edit/classified_price_section.dart';
import '../../widgets/classifieds/add_edit/classified_contact_section.dart';
import '../../widgets/classifieds/add_edit/classified_category_selector.dart';
import '../../widgets/classifieds/add_edit/classified_title_field.dart';
import '../../widgets/classifieds/add_edit/classified_description_field.dart';
import '../../widgets/classifieds/add_edit/classified_guest_empty_state.dart';

import '../../widgets/guest_auth_prompt.dart';

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
  String _sellerType = 'individual';
  bool _phonePublic = true;
  String? _selectedCategoryName;
  bool? _selectedCategoryConditionApplicable;
  List<ClassifiedCategoryModel> _selectedCategoryBreadcrumbs = [];
  Map<String, dynamic> _attributes = {};
  bool _isFeatured = false;
  DateTime? _featuredUntil;
  bool _isUrgent = false;

  final List<String> _existingImages = [];
  final List<Uint8List> _newImageBytes = [];
  final _imagePicker = ImagePicker();
  final _storageService = StorageService();
  late ClassifiedsService _service;

  bool _isPickingImages = false;
  int _incomingCount = 0;
  double? _imageProcessingProgress;
  String? _imageProcessingStatus;
  String? _uploadStatusText;

  bool _loading = false;
  bool _initializing = false;
  DateTime? _existingCreatedAt;

  bool get isEdit => widget.adId != null;

  @override
  void initState() {
    super.initState();
    _service = context.read<ClassifiedsService>();
    _titleController.addListener(_onTitleChanged);
    if (isEdit) {
      _loadExisting();
    } else {
      final user = context.read<AppState>().user;
      if (user != null) {
        _cityController.text = user.city ?? '';
        _phoneController.text = user.phone ?? '';
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ClassifiedsProvider>().loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isConditionApplicable =>
      ClassifiedAdModel.isConditionApplicableForCategory(
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        title: _titleController.text,
        categoryConditionApplicable: _selectedCategoryConditionApplicable,
      );

  void _onTitleChanged() {
    if (!mounted) return;
    final isApplicable = _isConditionApplicable;
    if (!isApplicable && _condition != 'not_applicable') {
      setState(() => _condition = 'not_applicable');
    } else if (isApplicable && _condition == 'not_applicable') {
      setState(() => _condition = 'used');
    }
  }

  void _selectCategory(
    String id,
    String name, {
    bool? isConditionApplicable,
    List<ClassifiedCategoryModel> breadcrumbs = const [],
  }) {
    setState(() {
      _selectedCategoryBreadcrumbs = breadcrumbs;
      if (_selectedCategoryId != id) {
        final newAttrs = ClassifiedAttributesEngine.getAttributesForCategory(
          id,
          breadcrumbs: breadcrumbs,
        ).map((a) => a.key).toSet();
        _attributes.removeWhere((k, _) => !newAttrs.contains(k));
      }
      _selectedCategoryId = id;
      _selectedCategoryName = name;
      _selectedCategoryConditionApplicable = isConditionApplicable;
      final isApplicable = _isConditionApplicable;
      if (!isApplicable) {
        _condition = 'not_applicable';
      } else if (_condition == 'not_applicable') {
        _condition = 'used';
      }
    });
  }

  Future<void> _loadExisting() async {
    setState(() => _initializing = true);
    try {
      final provider = context.read<ClassifiedsProvider>();
      if (!provider.categoriesLoaded || provider.categories.every((c) => c.subcategories.isEmpty)) {
        await provider.loadCategories();
      }
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
        final allCategories =
            context.read<ClassifiedsProvider>().categories;
        _selectedCategoryBreadcrumbs =
            ClassifiedCategoryModel.findPath(ad.categoryId, allCategories);
        _currency = ad.currency;
        _priceType = ad.priceType;
        final catModel =
            context.read<ClassifiedsProvider>().findCategory(ad.categoryId);
        _selectedCategoryConditionApplicable =
            catModel?.isConditionApplicable ?? ad.categoryConditionApplicable;
        final isApplicable = _isConditionApplicable;
        _condition = isApplicable ? ad.condition : 'not_applicable';
        _phonePublic = ad.phonePublic;
        _sellerType = ad.sellerType;
        _existingImages.addAll(ad.images);
        _existingCreatedAt = ad.createdAt;
        _attributes = Map<String, dynamic>.from(ad.attributes);
        _isFeatured = ad.isFeatured;
        _featuredUntil = ad.featuredUntil;
        _isUrgent = ad.isUrgent;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimalno možete dodati 8 slika.')),
        );
      }
      return;
    }

    final remainingSlots = 8 - totalCurrent;
    setState(() {
      _isPickingImages = true;
      _incomingCount = 1;
      _imageProcessingProgress = null;
      _imageProcessingStatus = 'Izaberite sliku...';
    });

    try {
      List<XFile> picked = [];
      try {
        // Na Web-u se zaobilazi ImageResizer (canvas) koji izaziva blokadu kod nekih MIME tipova
        picked = await _imagePicker.pickMultiImage(
          maxWidth: kIsWeb ? null : 1200,
          imageQuality: kIsWeb ? null : 85,
        );
      } catch (e) {
        debugPrint('pickMultiImage greška, pokušavam fallback na pickImage: $e');
        try {
          final single = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: kIsWeb ? null : 1200,
            imageQuality: kIsWeb ? null : 85,
          );
          if (single != null) {
            picked = [single];
          }
        } catch (e2) {
          debugPrint('Fallback na pojedinačnu sliku takođe nije uspeo: $e2');
          rethrow;
        }
      }

      if (picked.isEmpty) return;

      if (picked.length > remainingSlots && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Izabrano je ${picked.length} slika. Dodato je prvih $remainingSlots (maksimalno 8 slika).',
            ),
          ),
        );
      }

      final filesToProcess = picked.take(remainingSlots).toList();
      final totalFiles = filesToProcess.length;

      if (mounted) {
        setState(() {
          _incomingCount = totalFiles;
          _imageProcessingProgress = 0.3;
          _imageProcessingStatus = totalFiles > 1
              ? 'Učitavanje $totalFiles slika paralelno...'
              : 'Učitavanje slike...';
        });
      }

      // Paralelno učitavanje svih izabranih fajlova u memoriju sa pojedinačnim try-catch
      final readFutures = filesToProcess.map((f) async {
        try {
          final bytes = await f.readAsBytes();
          return bytes;
        } catch (err) {
          debugPrint('Greška pri čitanju fajla ${f.name}: $err');
          return null;
        }
      }).toList();
      final allBytes = await Future.wait(readFutures);

      final compressionService = ImageCompressionService();
      final validBytes = <Uint8List>[];
      var oversizedCount = 0;
      var failedReadCount = 0;

      for (var i = 0; i < allBytes.length; i++) {
        final rawBytes = allBytes[i];
        if (rawBytes == null) {
          failedReadCount++;
          continue;
        }
        final sizeErr = checkFileSize(rawBytes);
        if (sizeErr != null) {
          oversizedCount++;
          continue;
        }

        if (mounted) {
          setState(() {
            _imageProcessingStatus = totalFiles > 1
                ? 'Optimizacija slike ${i + 1}/$totalFiles...'
                : 'Optimizacija slike...';
            _imageProcessingProgress = 0.5 + (0.45 * ((i + 1) / totalFiles));
          });
        }

        // Normalizujemo i kompresujemo u čisti JPEG format
        final normalizedBytes = await compressionService.compressImage(
          Uint8List.fromList(rawBytes),
        );
        validBytes.add(normalizedBytes);
      }

      if (failedReadCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedReadCount == 1
                  ? 'Jedna slika nije mogla biti učitana sa diska.'
                  : '$failedReadCount slike nisu mogle biti učitane sa diska.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }

      if (oversizedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              oversizedCount == 1
                  ? 'Jedna slika je preskočena jer prelazi limit od 10 MB.'
                  : '$oversizedCount slike su preskočene jer prelaze limit od 10 MB.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }

      if (mounted && validBytes.isNotEmpty) {
        setState(() {
          _newImageBytes.addAll(validBytes);
          _imageProcessingProgress = 1.0;
        });
      }
    } catch (e) {
      debugPrint('Greška pri izboru slika: $e');
      if (mounted) {
        final errorMsg = e.toString().contains('Blob') || e.toString().contains('load')
            ? 'Pretraživač nije uspeo da učita fajl. Pokušajte sa JPG ili PNG formatom.'
            : friendlyError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška pri izboru slike: $errorMsg'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImages = false;
          _incomingCount = 0;
          _imageProcessingProgress = null;
          _imageProcessingStatus = null;
        });
      }
    }
  }

  void _openCategoryPicker(BuildContext context) async {
    final provider = context.read<ClassifiedsProvider>();
    if (!provider.categoriesLoaded || provider.categories.every((c) => c.subcategories.isEmpty)) {
      await provider.loadCategories();
    }
    if (!context.mounted) return;
    final categories = provider.categories;
    final result = await CategorySelectionModal.show(context, categories);
    
    if (result != null) {
      _selectCategory(
        result.id,
        result.name,
        isConditionApplicable: result.isConditionApplicable,
        breadcrumbs: result.breadcrumbs,
      );
    }
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
    if (user == null || user.isGuest) {
      unawaited(showGuestAuthPrompt(
        context,
        title: 'Potrebna prijava',
        message: 'Morate biti prijavljeni na nalog kako biste objavili oglas.',
      ));
      return;
    }

    setState(() {
      _loading = true;
      _uploadStatusText = _newImageBytes.isNotEmpty
          ? 'Otpremanje ${_newImageBytes.length} slika paralelno...'
          : 'Čuvanje oglasa...';
    });

    final newlyUploadedUrls = <String>[];

    try {
      final uploadedUrls = List<String>.from(_existingImages);

      // Paralelni upload novih slika u Supabase Storage
      if (_newImageBytes.isNotEmpty) {
        final totalUploads = _newImageBytes.length;
        var completedCount = 0;

        final uploadFutures = _newImageBytes.asMap().entries.map((entry) async {
          final index = entry.key;
          final bytes = entry.value;
          final url = await _storageService.uploadProductImage(
            user.id,
            bytes,
            uploadedUrls.length + index,
          );
          completedCount++;
          if (mounted) {
            setState(() {
              _uploadStatusText = 'Otpremanje slika: $completedCount/$totalUploads...';
            });
          }
          return MapEntry(index, url);
        }).toList();

        final uploadedEntries = await Future.wait(uploadFutures);
        // Održavamo tačan redosled slika
        uploadedEntries.sort((a, b) => a.key.compareTo(b.key));
        final sortedUrls = uploadedEntries.map((e) => e.value).toList();

        newlyUploadedUrls.addAll(sortedUrls);
        uploadedUrls.addAll(sortedUrls);
      }

      if (mounted) {
        setState(() => _uploadStatusText = 'Čuvanje oglasa...');
      }

      final priceNum = _priceType == 'fixed' || _priceType == 'negotiable'
          ? (NumberInputUtils.parseDecimal(_priceController.text) ?? 0.0)
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
        condition: _isConditionApplicable ? _condition : 'not_applicable',
        sellerType: _sellerType,
        images: uploadedUrls,
        city: SerbianCities.normalize(_cityController.text),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        phonePublic: _phonePublic,
        status: 'active',
        attributes: _attributes,
        isFeatured: _isFeatured,
        featuredUntil: _featuredUntil,
        isUrgent: _isUrgent,
        createdAt: _existingCreatedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEdit) {
        await _service.updateAd(ad);
      } else {
        await _service.createAd(ad);
      }

      if (mounted) {
        unawaited(context.read<ClassifiedsProvider>().loadInitialAds());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Oglas uspešno ažuriran.' : 'Oglas uspešno objavljen!'),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/classifieds');
        }
      }
    } catch (e) {
      // Ako oglas nije sačuvan, obriši sve tek upload-ovane slike
      // da ne ostaju „orphan“ fajlovi u bucketu (best-effort).
      for (final url in newlyUploadedUrls) {
        try {
          await _storageService.deleteFileByPublicUrl(url);
        } catch (_) {/* cleanup je best-effort */}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _uploadStatusText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = Breakpoints.isTablet(context);
    final user = context.watch<AppState>().user;

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/classifieds'),
          title: const Text('Učitavanje...'),
          actions: const [AppHomeButton()],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/classifieds'),
          title: Text(isEdit ? 'Izmeni oglas' : 'Postavi novi oglas'),
          actions: const [AppHomeButton()],
        ),
        body: const ClassifiedGuestEmptyState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/classifieds'),
        title: Text(isEdit ? 'Izmeni oglas' : 'Postavi novi oglas'),
        actions: const [AppHomeButton()],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 14,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: (isTablet || Breakpoints.isDesktop(context)) ? 780 : 640,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClassifiedImagePickerRow(
                    theme: theme,
                    colorScheme: colorScheme,
                    isPickingImages: _isPickingImages,
                    onPickImages: _pickImages,
                    existingImages: _existingImages,
                    newImageBytes: _newImageBytes,
                    onRemoveExisting: (index) => setState(() => _existingImages.removeAt(index)),
                    onRemoveNew: (index) => setState(() => _newImageBytes.removeAt(index)),
                    incomingCount: _incomingCount,
                    imageProcessingStatus: _imageProcessingStatus,
                    imageProcessingProgress: _imageProcessingProgress,
                  ),
                  const SizedBox(height: 14),

                  ClassifiedTitleField(controller: _titleController),

                  // Kategorija (puna širina za čist i čitljiv prikaz stabla kategorije)
                  ClassifiedCategorySelector(
                    selectedCategoryId: _selectedCategoryId,
                    selectedCategoryName: _selectedCategoryName,
                    colorScheme: colorScheme,
                    onTap: () => _openCategoryPicker(context),
                  ),
                  const SizedBox(height: 12),

                  // Stanje predmeta i Način formiranja cene (u istom redu na desktopu)
                  ClassifiedPriceSection(
                    isConditionApplicable: _isConditionApplicable,
                    condition: _condition,
                    onConditionChanged: (v) => setState(() => _condition = v ?? 'used'),
                    priceType: _priceType,
                    currency: _currency,
                    priceController: _priceController,
                    onPriceTypeChanged: (v) => setState(() => _priceType = v ?? 'fixed'),
                    onCurrencyChanged: (v) => setState(() => _currency = v ?? 'RSD'),
                  ),
                  const SizedBox(height: 12),

                  ClassifiedAttributesWrapper(
                    theme: theme,
                    colorScheme: colorScheme,
                    categoryId: _selectedCategoryId,
                    breadcrumbs: _selectedCategoryBreadcrumbs,
                    currentAttributes: _attributes,
                    onChanged: (key, val) {
                      setState(() {
                        if (val == null) {
                          _attributes.remove(key);
                        } else {
                          _attributes[key] = val;
                        }
                      });
                    },
                  ),

                  // Grad / Lokacija i Kontakt telefon
                  if (isTablet || Breakpoints.isDesktop(context)) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClassifiedCityAutocomplete(controller: _cityController),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Kontakt telefon',
                              hintText: 'npr. 064 123 4567',
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Prikaži telefon javno u oglasu',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Ako isključite, kupci vas mogu kontaktirati samo preko poruka na sajtu.',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _phonePublic,
                      onChanged: (v) => setState(() => _phonePublic = v),
                    ),
                  ] else ...[
                    ClassifiedCityAutocomplete(controller: _cityController),
                    const SizedBox(height: 10),
                    ClassifiedContactSection(
                      phoneController: _phoneController,
                      phonePublic: _phonePublic,
                      onPhonePublicChanged: (v) => setState(() => _phonePublic = v),
                    ),
                  ],
                  const SizedBox(height: 12),

                  ClassifiedDescriptionField(controller: _descController),

                  // Sekcija: Tip oglašivača (Zakon o zaštiti potrošača)
                  ClassifiedSellerTypeSection(
                    theme: theme,
                    colorScheme: colorScheme,
                    sellerType: _sellerType,
                    onChanged: (val) {
                      setState(() {
                        _sellerType = val;
                      });
                    },
                  ),

                  // Sekcija za hitnu prodaju
                  ClassifiedPromotionSection(
                    theme: theme,
                    colorScheme: colorScheme,
                    isUrgent: _isUrgent,
                    onUrgentChanged: (val) => setState(() => _isUrgent = val),
                  ),
                  const SizedBox(height: 6),

                  // Dugme za objavu
                  ClassifiedSubmitButton(
                    loading: _loading,
                    isEdit: isEdit,
                    uploadStatusText: _uploadStatusText,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



}


