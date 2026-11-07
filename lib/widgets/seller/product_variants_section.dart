import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';
import '../../models/product_model.dart';
import '../../utils/number_input_utils.dart';

/// Opciona sekcija u formi prodavca za unos vise velicina / pakovanja istog proizvoda
/// (npr. "Flasica 250 ml - 250 RSD" i "Flasa 750 ml - 600 RSD").
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
    super.dispose();
  }

  void _emitChanges() {
    final result = <ProductVariant>[];
    final usedIds = <String>{};
    for (var i = 0; i < _rows.length; i++) {
      final label = _rows[i].labelController.text.trim();
      final price =
          NumberInputUtils.parseDecimal(_rows[i].priceController.text) ?? 0;
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
        ),
      );
    }

    // Ako postoje validne varijante sa cenom > 0, uskladi osnovnu cenu sa najnizom cenom pakovanja
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

    widget.onVariantsChanged(result);
  }

  void _enableVariants() {
    final basePrice = widget.basePriceController.text.trim();
    setState(() {
      _expanded = true;
      if (_rows.isEmpty) {
        _rows
          ..add(_VariantRowControllers(label: '', price: basePrice))
          ..add(_VariantRowControllers(label: '', price: ''));
      }
    });
    _emitChanges();
  }

  void _addRow() {
    setState(() {
      _rows.add(_VariantRowControllers());
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_expanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _enableVariants,
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text(
            'Dodaj više veličina / pakovanja (npr. manja i veća flaša/tegla)',
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
                Icons.inventory_2_outlined,
                size: 18,
                color: isDark ? AmazonColors.lightGreen : AmazonColors.green,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Veličine / pakovanja proizvoda',
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
                child: const Text('Ukloni pakovanja'),
              ),
            ],
          ),
          Text(
            'Unesite naziv svakog pakovanja i njegovu cenu. Kupac će pre naručivanja klikom izabrati željeno pakovanje.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AmazonColors.darkTextSecondary
                  : AmazonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _rows[i].labelController,
                    onChanged: (_) => _emitChanges(),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Pakovanje ${i + 1} (npr. Flašica 250 ml)',
                    ),
                  ),
                ),
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
                IconButton(
                  tooltip: 'Ukloni pakovanje',
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
              label: const Text('Dodaj još jedno pakovanje'),
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
