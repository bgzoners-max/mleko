import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';
import '../../models/product_model.dart';
import '../../utils/number_input_utils.dart';

/// Opciona sekcija u formi prodavca za unos varijacija istog proizvoda
/// (npr. ukusi džemova i sokova, vrste sira i meda, nadevi pita, ili veličine pakovanja).
class ProductVariantsSection extends StatefulWidget {
  final List<ProductVariant> variants;
  final ValueChanged<List<ProductVariant>> onVariantsChanged;
  final TextEditingController basePriceController;

  const ProductVariantsSection({
    super.key,
    required this.variants,
    required this.onVariantsChanged,
    required this.basePriceController,
  });

  @override
  State<ProductVariantsSection> createState() => _ProductVariantsSectionState();
}

class _VariantRowControllers {
  final TextEditingController labelController;
  final TextEditingController priceController;

  _VariantRowControllers({String label = '', String price = ''})
      : labelController = TextEditingController(text: label),
        priceController = TextEditingController(text: price);

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}

class _ProductVariantsSectionState extends State<ProductVariantsSection> {
  final List<_VariantRowControllers> _rows = [];
  bool _expanded = false;

  /// Tip varijacije: 'Ukus', 'Vrsta', 'Nadev', 'Pakovanje', 'Miris', 'Prilagođeno'.
  String _selectedGroupType = 'Ukus';
  final TextEditingController _customGroupController = TextEditingController();
  bool _allSamePrice = false;

  static const List<Map<String, String>> _presetTypes = [
    {'type': 'Ukus', 'label': '🍓 Ukus / aroma', 'hint': 'npr. Jagoda, Kajsija, Šljiva sa cimetom...'},
    {'type': 'Vrsta', 'label': '🧀 Vrsta / sorta', 'hint': 'npr. Bagremov, Lipov, Mladi sir, Dimljeni...'},
    {'type': 'Nadev', 'label': '🥧 Nadev / sastav', 'hint': 'npr. Sa sirom, Sa mesom, Krompir, Zelje...'},
    {'type': 'Pakovanje', 'label': '📦 Veličina / pakovanje', 'hint': 'npr. Teglica 330 ml, Velika tegla 720 ml...'},
    {'type': 'Miris', 'label': '🌿 Miris / tip', 'hint': 'npr. Lavanda, Neven, Smilje, Kamilica...'},
    {'type': 'Prilagođeno', 'label': '✏️ Drugo', 'hint': 'npr. Opcija 1, Opcija 2...'},
  ];

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant ProductVariantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variants != widget.variants && _rows.isEmpty && widget.variants.isNotEmpty) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();

    if (widget.variants.isNotEmpty) {
      _expanded = true;

      // 1. Otkrij tip grupe iz postojećih varijanti
      final existingGroup = widget.variants.first.group?.trim();
      if (existingGroup != null && existingGroup.isNotEmpty) {
        final matchesPreset = _presetTypes.any((p) => p['type'] == existingGroup);
        if (matchesPreset) {
          _selectedGroupType = existingGroup;
        } else {
          _selectedGroupType = 'Prilagođeno';
          _customGroupController.text = existingGroup;
        }
      } else {
        // Auto-detekcija za stare podatke
        final labels = widget.variants.map((v) => v.label.toLowerCase()).join(' ');
        final hasPackageHints = labels.contains('ml') ||
            labels.contains(' g') ||
            labels.contains('kg') ||
            labels.contains(' l') ||
            labels.contains('pak') ||
            labels.contains('teg') ||
            labels.contains('fla');
        _selectedGroupType = hasPackageHints ? 'Pakovanje' : 'Ukus';
      }

      // 2. Proveri da li sve imaju istu cenu
      final firstPrice = widget.variants.first.price;
      _allSamePrice = widget.variants.length > 1 &&
          widget.variants.every((v) => (v.price - firstPrice).abs() < 0.001);

      for (final v in widget.variants) {
        _rows.add(
          _VariantRowControllers(
            label: v.label,
            price: ProductFormattingUtils.formatDecimal(v.price),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _customGroupController.dispose();
    super.dispose();
  }

  String get _effectiveGroupTitle {
    if (_selectedGroupType == 'Prilagođeno') {
      final custom = _customGroupController.text.trim();
      return custom.isNotEmpty ? custom : 'Opcija';
    }
    return _selectedGroupType;
  }

  String get _currentHintText {
    final found = _presetTypes.firstWhere(
      (p) => p['type'] == _selectedGroupType,
      orElse: () => _presetTypes.last,
    );
    return found['hint'] ?? 'npr. Naziv opcije';
  }

  String get _addButtonLabel {
    return switch (_selectedGroupType) {
      'Ukus' => 'Dodaj još jedan ukus',
      'Vrsta' => 'Dodaj još jednu vrstu',
      'Nadev' => 'Dodaj još jedan nadev',
      'Pakovanje' => 'Dodaj još jedno pakovanje',
      'Miris' => 'Dodaj još jedan miris',
      _ => 'Dodaj još jednu opciju',
    };
  }

  void _emitChanges() {
    final result = <ProductVariant>[];
    final usedIds = <String>{};
    final group = _effectiveGroupTitle;
    final basePriceNum =
        NumberInputUtils.parseDecimal(widget.basePriceController.text) ?? 0;

    for (var i = 0; i < _rows.length; i++) {
      final label = _rows[i].labelController.text.trim();
      final double price = _allSamePrice
          ? basePriceNum
          : (NumberInputUtils.parseDecimal(_rows[i].priceController.text) ?? 0);

      if (label.isEmpty && price <= 0) continue;
      var id = ProductVariant.normalizeId(label);
      if (usedIds.contains(id)) {
        id = '${id}_${i + 1}';
      }
      usedIds.add(id);

      result.add(
        ProductVariant(
          id: id,
          label: label,
          price: price > 0 ? price : 0,
          group: group,
        ),
      );
    }

    // Ako ne koristimo "Ista cena" i imamo validne varijante, uskladi osnovnu cenu sa najnižom cenom
    if (!_allSamePrice) {
      final validPrices =
          result.where((v) => v.price > 0).map((v) => v.price).toList();
      if (validPrices.isNotEmpty) {
        validPrices.sort();
        final minPrice = validPrices.first;
        widget.basePriceController.text =
            minPrice == minPrice.roundToDouble()
                ? minPrice.toInt().toString()
                : minPrice.toString();
      }
    }

    widget.onVariantsChanged(result);
  }

  void _enableVariants() {
    final basePrice = widget.basePriceController.text.trim();
    setState(() {
      _expanded = true;
      if (_rows.isEmpty) {
        _rows
          ..add(_VariantRowControllers(label: '', price: basePrice))
          ..add(_VariantRowControllers(label: '', price: basePrice));
      }
    });
    _emitChanges();
  }

  void _addRow() {
    final basePrice = widget.basePriceController.text.trim();
    setState(() {
      _rows.add(_VariantRowControllers(
        label: '',
        price: _allSamePrice ? basePrice : '',
      ));
    });
    _emitChanges();
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index).dispose();
      if (_rows.isEmpty) {
        _expanded = false;
      }
    });
    _emitChanges();
  }

  void _clearAll() {
    setState(() {
      for (final row in _rows) {
        row.dispose();
      }
      _rows.clear();
      _expanded = false;
    });
    widget.onVariantsChanged(const []);
  }

  void _toggleAllSamePrice(bool? val) {
    setState(() {
      _allSamePrice = val ?? false;
      if (_allSamePrice) {
        final basePrice = widget.basePriceController.text.trim();
        for (final row in _rows) {
          row.priceController.text = basePrice;
        }
      }
    });
    _emitChanges();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _enableVariants,
          icon: const Icon(Icons.tune_outlined, size: 18),
          label: const Text(
            'Dodaj varijacije (različiti ukusi, vrste, nadevi ili pakovanja)',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AmazonColors.lightGreen : AmazonColors.green,
            side: BorderSide(
              color: isDark
                  ? AmazonColors.lightGreen.withValues(alpha: 0.5)
                  : AmazonColors.green.withValues(alpha: 0.45),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      );
    }

    final basePriceText = widget.basePriceController.text.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AmazonColors.darkCard
            : AmazonColors.green.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AmazonColors.darkBorder
              : AmazonColors.green.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_outlined,
                size: 18,
                color: isDark ? AmazonColors.lightGreen : AmazonColors.green,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Varijacije proizvoda',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: _clearAll,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.red.shade600,
                ),
                child: const Text('Ukloni varijacije'),
              ),
            ],
          ),
          Text(
            'Omogućite kupcima da u jednom oglasu izaberu željeni ukus, vrstu, nadev ili veličinu pakovanja.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AmazonColors.darkTextSecondary
                  : AmazonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Čime se varijante razlikuju?',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AmazonColors.darkTextPrimary
                  : AmazonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetTypes.map((preset) {
              final isSelected = _selectedGroupType == preset['type'];
              return ChoiceChip(
                label: Text(preset['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedGroupType = preset['type']!);
                    _emitChanges();
                  }
                },
                selectedColor: isDark
                    ? AmazonColors.green.withValues(alpha: 0.35)
                    : AmazonColors.green.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                      : (isDark
                          ? AmazonColors.darkTextPrimary
                          : AmazonColors.textPrimary),
                ),
              );
            }).toList(),
          ),
          if (_selectedGroupType == 'Prilagođeno') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customGroupController,
              onChanged: (_) => _emitChanges(),
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Naziv grupe varijacija',
                hintText: 'npr. Oblik, Vrsta testa, Boja...',
              ),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _toggleAllSamePrice(!_allSamePrice),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: _allSamePrice,
                    onChanged: _toggleAllSamePrice,
                    activeColor: AmazonColors.green,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          basePriceText.isNotEmpty
                              ? 'Sve varijante imaju istu cenu ($basePriceText RSD)'
                              : 'Sve varijante imaju istu osnovnu cenu',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Cena se automatski primenjuje na sve opcije bez ponovnog unosa',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? AmazonColors.darkTextSecondary
                                : AmazonColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: _allSamePrice ? 5 : 3,
                  child: TextField(
                    controller: _rows[i].labelController,
                    onChanged: (_) => _emitChanges(),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: '$_effectiveGroupTitle ${i + 1}',
                      hintText: _currentHintText,
                    ),
                  ),
                ),
                if (!_allSamePrice) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _rows[i].priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _emitChanges(),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Cena (RSD)',
                      ),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: 'Ukloni opciju',
                  onPressed: () => _removeRow(i),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: Text(_addButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> showPublishWithoutImageDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Objava bez fotografije?'),
      content: const Text(
        'Oglasi bez fotografije prikazuju se na dnu početne strane i imaju znatno manje porudžbina. Preporučujemo da dodate bar jednu fotografiju proizvoda.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop('publish'),
          child: const Text('Objavi bez slike'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(ctx).pop('pick'),
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: const Text('Dodaj fotografiju'),
        ),
      ],
    ),
  );
}

Future<bool?> showConfirmDeleteProductDialog({
  required BuildContext context,
  required String productName,
  required Future<void> Function() onDelete,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      bool isDeleting = false;
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Text('Trajno brisanje proizvoda'),
            content: Text(
              'Da li ste sigurni da želite trajno da obrišete proizvod „${productName.isNotEmpty ? productName : 'ovaj proizvod'}”? Ova akcija se ne može poništiti.',
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Odustani'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await onDelete();
                          if (ctx.mounted) Navigator.pop(ctx, true);
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
}
