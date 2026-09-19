import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/serbian_cities.dart';
import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';
import '../../models/category_attribute_model.dart';
import '../../models/classified_ad_model.dart';
import '../../models/classified_category_model.dart';
import '../../providers/app_state.dart';
import '../../providers/classifieds_provider.dart';
import '../../services/classifieds/classifieds_service.dart';
import '../../services/media/storage_service.dart';
import '../../utils/classified_attributes_engine.dart';
import '../../utils/number_input_utils.dart';
import '../../widgets/app_empty_state.dart';
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
  bool _phonePublic = true;
  String? _selectedCategoryName;
  bool? _selectedCategoryConditionApplicable;
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
  }) {
    setState(() {
      if (_selectedCategoryId != id) {
        final newAttrs = ClassifiedAttributesEngine.getAttributesForCategory(id)
            .map((a) => a.key)
            .toSet();
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
        final catModel =
            context.read<ClassifiedsProvider>().findCategory(ad.categoryId);
        _selectedCategoryConditionApplicable =
            catModel?.isConditionApplicable ?? ad.categoryConditionApplicable;
        final isApplicable = _isConditionApplicable;
        _condition = isApplicable ? ad.condition : 'not_applicable';
        _phonePublic = ad.phonePublic;
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

      final validBytes = <Uint8List>[];
      var oversizedCount = 0;
      var failedReadCount = 0;

      for (final rawBytes in allBytes) {
        if (rawBytes == null) {
          failedReadCount++;
          continue;
        }
        final sizeErr = checkFileSize(rawBytes);
        if (sizeErr != null) {
          oversizedCount++;
        } else {
          validBytes.add(Uint8List.fromList(rawBytes));
        }
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

  void _openCategoryPicker(BuildContext context) {
    final categories = context.read<ClassifiedsProvider>().categories;
    final modalPath = <ClassifiedCategoryModel>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollCtl) {
                Widget headerWidget;
                Widget contentWidget;

                if (modalPath.isNotEmpty) {
                  final current = modalPath.last;
                  final currentBreadcrumb =
                      modalPath.map((e) => e.name).join(' > ');

                  headerWidget = Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () =>
                              setModalState(() => modalPath.removeLast()),
                        ),
                        Expanded(
                          child: Text(
                            current.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  );

                  contentWidget = ListView(
                    controller: scrollCtl,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(current.iconData, size: 18),
                        label: Text(
                          modalPath.length == 1
                              ? 'Izaberi celu kategoriju: ${current.name}'
                              : 'Izaberi celu podkategoriju: ${current.name}',
                        ),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _selectCategory(
                            current.id,
                            currentBreadcrumb,
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                      if (current.subcategories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        if (!current.isRoot && current.subcategories.where((s) => s.subcategories.isNotEmpty).length >= 2) ...[
                          // Grupisan prikaz po sekcijama (npr. Automobili -> • NEMAČKA -> marke, • ITALIJA -> marke)
                          for (final group in current.subcategories.where((s) => s.subcategories.isNotEmpty)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    group.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    onPressed: () {
                                      _selectCategory(
                                        group.id,
                                        [...modalPath.map((e) => e.name), group.name].join(' > '),
                                      );
                                      Navigator.pop(ctx);
                                    },
                                    child: Text(
                                      'Izaberi: ${group.name}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 46,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: group.subcategories.length,
                              itemBuilder: (c, i) {
                                final brand = group.subcategories[i];
                                return _CategoryCardPicker(
                                  category: brand,
                                  hasChildren: false,
                                  onTap: () {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      group.name,
                                      brand.name,
                                    ].join(' > ');
                                    _selectCategory(brand.id, fullPath);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                          ],
                          // Samostalne podkategorije (Džipovi, Havarisana, Ostalo)
                          if (current.subcategories.any((s) => s.subcategories.isEmpty)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'OSTALO / DODATNE KATEGORIJE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 54,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: current.subcategories.where((s) => s.subcategories.isEmpty).length,
                              itemBuilder: (c, i) {
                                final sub = current.subcategories.where((s) => s.subcategories.isEmpty).toList()[i];
                                return _CategoryCardPicker(
                                  category: sub,
                                  hasChildren: false,
                                  onTap: () {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      sub.name,
                                    ].join(' > ');
                                    _selectCategory(sub.id, fullPath);
                                    Navigator.pop(ctx);
                                  },
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          Text(
                            modalPath.length == 1
                                ? 'Izaberite podkategoriju:'
                                : 'Ili izaberite užu podkategoriju:',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 46,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: current.subcategories.length,
                            itemBuilder: (c, i) {
                              final sub = current.subcategories[i];
                              return _CategoryCardPicker(
                                category: sub,
                                hasChildren: sub.subcategories.isNotEmpty,
                                onTap: () {
                                  if (sub.subcategories.isNotEmpty) {
                                    setModalState(() => modalPath.add(sub));
                                  } else {
                                    final fullPath = [
                                      ...modalPath.map((e) => e.name),
                                      sub.name
                                    ].join(' > ');
                                    _selectCategory(
                                      sub.id,
                                      fullPath,
                                      isConditionApplicable:
                                          sub.isConditionApplicable,
                                    );
                                    Navigator.pop(ctx);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  );
                } else {
                  // Nivo 1: Glavne kategorije
                  headerWidget = Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Izaberi kategoriju',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  );

                  contentWidget = ListView.builder(
                    controller: scrollCtl,
                    itemCount: categories.length,
                    itemBuilder: (c, i) {
                      final cat = categories[i];
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.iconData, size: 20),
                        ),
                        title: Text(cat.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: cat.subcategories.isNotEmpty
                            ? const Icon(Icons.chevron_right, size: 20)
                            : null,
                        onTap: () {
                          if (cat.subcategories.isNotEmpty) {
                            setModalState(() => modalPath.add(cat));
                          } else {
                            _selectCategory(
                              cat.id,
                              cat.name,
                              isConditionApplicable:
                                  cat.isConditionApplicable,
                            );
                            Navigator.pop(ctx);
                          }
                        },
                      );
                    },
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.modalMaxWidth),
                    child: Column(
                      children: [
                        headerWidget,
                        Expanded(child: contentWidget),
                      ],
                    ),
                  ),
                );
              },
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
    if (user == null || user.isGuest) {
      showGuestAuthPrompt(
        context,
        title: 'Potrebna prijava',
        message: 'Morate biti prijavljeni na nalog kako biste objavili oglas.',
      );
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
        context.read<ClassifiedsProvider>().loadInitialAds();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Oglas uspešno ažuriran.' : 'Oglas uspešno objavljen!'),
          ),
        );
        Navigator.pop(context);
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
        appBar: AppBar(title: const Text('Učitavanje...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: Text(isEdit ? 'Izmeni oglas' : 'Postavi novi oglas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AppEmptyState(
              icon: Icons.account_circle_outlined,
              title: 'Potrebna prijava za postavljanje oglasa',
              subtitle:
                  'Kao gost možete slobodno pregledati oglase i kontaktirati prodavce. Za objavu sopstvenog oglasa potrebno je da se prijavite ili besplatno registrujete.',
              ctaLabel: 'Prijavi se',
              ctaIcon: Icons.login,
              onCtaPressed: () => context.push('/login'),
            ),
          ),
        ),
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
                  Row(
                    children: [
                      Text(
                        'Fotografije oglasa (do 8 slika)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '– možete izabrati više odjednom',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kliknite "Dodaj" i držite Ctrl ili Shift za izbor više slika istovremeno.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        InkWell(
                          onTap: _isPickingImages ? null : _pickImages,
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
                                  child: CachedNetworkImage(
                                    imageUrl: entry.value,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    memCacheHeight: 200,
                                    placeholder: (context, url) => Container(
                                      width: 100,
                                      height: 100,
                                      color: colorScheme.surfaceContainerHighest,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 100,
                                      height: 100,
                                      color: colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 28,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
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
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 100,
                                      height: 100,
                                      color: colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 28,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
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
                        if (_isPickingImages)
                          for (var k = 0; k < (_incomingCount > 0 ? _incomingCount : 1); k++)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Spacer(),
                                    Icon(
                                      Icons.photo_library_outlined,
                                      color: colorScheme.primary,
                                      size: 26,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        _incomingCount > 1
                                            ? 'Slika ${k + 1}/$_incomingCount'
                                            : (_imageProcessingStatus ?? 'Učitavanje...'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: _imageProcessingProgress,
                                          minHeight: 4,
                                          backgroundColor: colorScheme.surfaceContainerHighest,
                                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
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
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _currency,
                            decoration: const InputDecoration(
                              labelText: 'Valuta',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'RSD',
                                child: Text('RSD (din)', overflow: TextOverflow.ellipsis),
                              ),
                              DropdownMenuItem(
                                value: 'EUR',
                                child: Text('EUR (€)', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (v) => setState(() => _currency = v ?? 'RSD'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Stanje predmeta (samo za tehniku, vozila, alate, nameštaj itd.; sakriveno za životinje, voće, povrće, usluge...)
                  if (_isConditionApplicable) ...[
                    DropdownButtonFormField<String>(
                      initialValue: (_condition == 'new' || _condition == 'used')
                          ? _condition
                          : 'used',
                      decoration:
                          const InputDecoration(labelText: 'Stanje predmeta'),
                      items: const [
                        DropdownMenuItem(value: 'used', child: Text('Polovno')),
                        DropdownMenuItem(
                            value: 'new', child: Text('Novo / Nekorišćeno')),
                      ],
                      onChanged: (v) =>
                          setState(() => _condition = v ?? 'used'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Karakteristike / specifikacije predmeta (za automobile, mašine, nekretnine, telefone...)
                  () {
                    final categoryAttributes =
                        ClassifiedAttributesEngine.getAttributesForCategory(
                      _selectedCategoryId,
                    );
                    if (categoryAttributes.isNotEmpty) {
                      return _buildAttributesSection(
                        theme,
                        colorScheme,
                        categoryAttributes,
                      );
                    }
                    return const SizedBox.shrink();
                  }(),

                  // Grad / Lokacija sa automatskim predlozima
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _cityController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return SerbianCities.suggestions(textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _cityController.text = selection;
                    },
                    fieldViewBuilder: (
                      BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted,
                    ) {
                      // Sinhronizacija vrednosti
                      if (_cityController.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
                        fieldTextEditingController.text = _cityController.text;
                      }
                      fieldTextEditingController.addListener(() {
                        _cityController.text = fieldTextEditingController.text;
                      });

                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        decoration: const InputDecoration(
                          labelText: 'Grad ili mesto *',
                          hintText: 'npr. Beograd, Čačak, Zlatibor...',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Unesite grad ili mesto.';
                          return null;
                        },
                      );
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
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Detaljan opis',
                      hintText: 'Opišite stanje, karakteristike, razlog prodaje, zamene itd.',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sekcija za promociju oglasa
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: (_isFeatured || _isUrgent)
                            ? (_isFeatured ? const Color(0xFFD97706) : const Color(0xFFDC2626))
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: (_isFeatured || _isUrgent) ? 1.5 : 1.0,
                      ),
                    ),
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Promocija oglasa',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFD97706),
                            ),
                            title: const Text(
                              'Istakni oglas (Featured)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Oglas će se prikazivati na vrhu pretrage i sa zlatnim okvirom.',
                            ),
                            value: _isFeatured,
                            onChanged: (val) {
                              setState(() {
                                _isFeatured = val;
                                if (val && _featuredUntil == null) {
                                  _featuredUntil = DateTime.now().add(const Duration(days: 30));
                                } else if (!val) {
                                  _featuredUntil = null;
                                }
                              });
                            },
                          ),
                          const Divider(height: 16),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            secondary: const Icon(
                              Icons.bolt_rounded,
                              color: Color(0xFFDC2626),
                            ),
                            title: const Text(
                              'Hitna prodaja (Urgent)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Privucite kupce bedžom HITNO u uočljivoj crvenoj boji.',
                            ),
                            value: _isUrgent,
                            onChanged: (val) => setState(() => _isUrgent = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dugme za objavu
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              if (_uploadStatusText != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  _uploadStatusText!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ],
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

  Widget _buildAttributesSection(
    ThemeData theme,
    ColorScheme colorScheme,
    List<CategoryAttribute> attributes,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Karakteristike predmeta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final attr in attributes) ...[
              if (attr.type == AttributeType.number) ...[
                TextFormField(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: _attributes[attr.key]?.toString() ?? '',
                  keyboardType: attr.isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    if (!attr.isDecimal)
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: attr.label,
                    hintText: attr.hint,
                    suffixText: attr.unit,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  onChanged: (val) {
                    final n = attr.isDecimal
                        ? NumberInputUtils.parseDecimal(val)
                        : NumberInputUtils.parseInteger(val);
                    if (n != null) {
                      _attributes[attr.key] = n;
                    } else {
                      _attributes.remove(attr.key);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ] else if (attr.type == AttributeType.select) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: _attributes[attr.key]?.toString(),
                  decoration: InputDecoration(
                    labelText: attr.label,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Nije izabrano',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    ...(attr.options ?? const []).map(
                      (opt) => DropdownMenuItem(
                        value: opt.value,
                        child: Text(opt.label),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      if (val == null || val.isEmpty) {
                        _attributes.remove(attr.key);
                      } else {
                        _attributes[attr.key] = val;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ] else if (attr.type == AttributeType.boolean) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  title: Text(attr.label),
                  subtitle: attr.hint != null ? Text(attr.hint!) : null,
                  value: _attributes[attr.key] == true,
                  onChanged: (val) {
                    setState(() {
                      _attributes[attr.key] = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
              ] else ...[
                TextFormField(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: _attributes[attr.key]?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: attr.label,
                    hintText: attr.hint,
                    suffixText: attr.unit,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  onChanged: (val) {
                    final t = val.trim();
                    if (t.isNotEmpty) {
                      _attributes[attr.key] = t;
                    } else {
                      _attributes.remove(attr.key);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// 2-kolonska kartica za izbor podkategorije u formi za oglas
class _CategoryCardPicker extends StatelessWidget {
  final ClassifiedCategoryModel category;
  final bool hasChildren;
  final VoidCallback onTap;

  const _CategoryCardPicker({
    required this.category,
    this.hasChildren = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: category.brandLogoAsset != null
                    ? Colors.white
                    : (isDark ? const Color(0xFF0F172A) : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: category.brandLogoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        category.brandLogoAsset!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => Icon(category.iconData,
                            size: 18, color: colorScheme.primary),
                      ),
                    )
                  : Icon(category.iconData,
                      size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.15),
                    ),
                  ),
                  if (category.adCount > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${category.adCount}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasChildren)
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
