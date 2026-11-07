import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/cupertino_category_picker.dart';
import '../../widgets/grouped_category_dropdown.dart';
import 'product_variants_section.dart';

/// Osnovna sekcija forme proizvoda: kategorija, jedinica, naziv, cena i količine.
class ProductBasicInfoSection extends StatelessWidget {
  final List<CategoryGroup>? groups;
  final String? category;
  final ValueChanged<String?> onCategoryChanged;
  final String unitType;
  final ValueChanged<String> onUnitTypeChanged;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController minOrderController;
  final TextEditingController orderStepController;
  final TextEditingController availableController;
  final String? Function(String text, String unitType)? quantityHintBuilder;
  final VoidCallback onChanged;
  final List<ProductVariant> variants;
  final ValueChanged<List<ProductVariant>>? onVariantsChanged;

  const ProductBasicInfoSection({
    super.key,
    required this.groups,
    required this.category,
    required this.onCategoryChanged,
    required this.unitType,
    required this.onUnitTypeChanged,
    required this.nameController,
    required this.priceController,
    required this.minOrderController,
    required this.orderStepController,
    required this.availableController,
    required this.quantityHintBuilder,
    required this.onChanged,
    this.variants = const [],
    this.onVariantsChanged,
  });

  String? _hint(String text) => quantityHintBuilder?.call(text, unitType);

  Widget _buildCategoryPicker(bool hasGroupedCategories) {
    return hasGroupedCategories
        ? GroupedCategoryDropdown(
            groups: groups!,
            value: category,
            onChanged: (v) {
              onCategoryChanged(v);
              if (v != null &&
                  isVolumeCategory(v) &&
                  unitType != ProductModel.unitMl) {
                onUnitTypeChanged(ProductModel.unitL);
              }
            },
            validator: (v) =>
                v == null || v.isEmpty ? 'Izaberite kategoriju' : null,
          )
        : CupertinoCategoryPicker(
            initialCategory: category,
            onCategoryChanged: (v) {
              onCategoryChanged(v);
              if (v != null &&
                  isVolumeCategory(v) &&
                  unitType != ProductModel.unitMl) {
                onUnitTypeChanged(ProductModel.unitL);
              }
            },
          );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: unitType,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Jedinica', isDense: true),
      items: const [
        DropdownMenuItem(
          value: ProductModel.unitKg,
          child: Text('Kilogrami (kg)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitG,
          child: Text('Grami (g)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitL,
          child: Text('Litri (L)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitMl,
          child: Text('Mililitri (ml)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitPiece,
          child: Text('Komadi (kom)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitVeza,
          child: Text('Veza / vezica (veza)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitPak,
          child: Text('Pakovanje (pak)'),
        ),
      ],
      onChanged: (v) => onUnitTypeChanged(v ?? ProductModel.unitKg),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      decoration: const InputDecoration(labelText: 'Naziv *', isDense: true),
    );
  }

  String? _formattedSubUnitMin() {
    final raw = minOrderController.text.trim();
    if (raw.isEmpty) return null;
    if (unitType == ProductModel.unitG) {
      final qty = ProductModel.parseQuantityG(raw);
      if (qty > 0) {
        return ProductModel.formatQuantityWithUnit(qty, ProductModel.unitKg);
      }
    } else if (unitType == ProductModel.unitMl) {
      final qty = ProductModel.parseQuantityMl(raw);
      if (qty > 0) {
        return ProductModel.formatQuantityWithUnit(qty, ProductModel.unitL);
      }
    }
    return null;
  }

  Widget _buildPriceField() {
    final subUnitMin = _formattedSubUnitMin();
    final priceText = priceController.text.trim();
    final String label = switch (unitType) {
      ProductModel.unitG => subUnitMin != null
          ? 'Cena za $subUnitMin (RSD) *'
          : 'Cena za unetu gramažu (RSD) *',
      ProductModel.unitMl => subUnitMin != null
          ? 'Cena za $subUnitMin (RSD) *'
          : 'Cena za unete mililitre (RSD) *',
      ProductModel.unitL => 'Cena po litru — 1 L (RSD) *',
      ProductModel.unitPiece => 'Cena po komadu (RSD) *',
      ProductModel.unitVeza => 'Cena po vezi (RSD) *',
      ProductModel.unitPak => 'Cena po pakovanju (RSD) *',
      _ => 'Cena po kilogramu — 1 kg (RSD) *',
    };

    final String? helperText =
        (subUnitMin != null && priceText.isNotEmpty)
            ? 'Kupac plaća $priceText RSD za $subUnitMin'
            : null;

    return TextField(
      controller: priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        helperText: helperText,
      ),
    );
  }

  Widget? _buildSubUnitQuickChips(BuildContext context) {
    final bool isGrams = unitType == ProductModel.unitG;
    final bool isMl = unitType == ProductModel.unitMl;
    if (!isGrams && !isMl) return null;

    final presets = isGrams
        ? const [30, 50, 100, 200, 250, 350, 500, 750]
        : const [50, 100, 200, 250, 330, 500, 750];
    final suffix = isGrams ? 'g' : 'ml';
    final currentText = minOrderController.text.trim();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isGrams ? 'Brzi izbor gramaže:' : 'Brzi izbor mililitraže:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          ...presets.map((val) {
            final isSelected = currentText == '$val';
            return ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                '$val $suffix',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              onPressed: () {
                minOrderController.text = '$val';
                orderStepController.text = '$val';
                onChanged();
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMinOrderField({bool isWide = false}) {
    return TextField(
      controller: minOrderController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        isDense: true,
        labelText: isWide
            ? switch (unitType) {
                ProductModel.unitG => 'Količina pakovanja / min. (g) *',
                ProductModel.unitMl => 'Količina pakovanja / min. (ml) *',
                ProductModel.unitL => 'Min. porudžbina (L) *',
                ProductModel.unitPiece => 'Min. porudžbina (kom) *',
                ProductModel.unitVeza => 'Min. porudžbina (veza) *',
                ProductModel.unitPak => 'Min. porudžbina (pak) *',
                _ => 'Min. porudžbina (kg) *',
              }
            : switch (unitType) {
                ProductModel.unitG =>
                  'Količina u gramima (npr. 100, 250, 500) *',
                ProductModel.unitMl =>
                  'Količina u mililitrima (npr. 250, 330, 500) *',
                ProductModel.unitL =>
                  'Minimalna porudžbina u litrima (npr. 1 ili 0.5) *',
                ProductModel.unitPiece =>
                  'Minimalna porudžbina (komada, npr. 1 ili 10) *',
                ProductModel.unitVeza =>
                  'Minimalna porudžbina (veza, npr. 1 ili 5) *',
                ProductModel.unitPak =>
                  'Minimalna porudžbina (pakovanja, npr. 1 ili 2) *',
                _ => 'Minimalna porudžbina u kg (npr. 1 ili 0.5) *',
              },
        hintText: isWide
            ? switch (unitType) {
                ProductModel.unitG => 'npr. 250',
                ProductModel.unitMl => 'npr. 330',
                ProductModel.unitL => 'npr. 1',
                ProductModel.unitPiece => 'npr. 1',
                ProductModel.unitVeza => 'npr. 1',
                ProductModel.unitPak => 'npr. 1',
                _ => 'npr. 1',
              }
            : null,
        helperText: _hint(minOrderController.text),
      ),
    );
  }

  Widget _buildOrderStepField({bool isWide = false}) {
    return TextField(
      controller: orderStepController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        isDense: true,
        labelText: isWide
            ? switch (unitType) {
                ProductModel.unitG => 'Korak porudžbine (g)',
                ProductModel.unitMl => 'Korak porudžbine (ml)',
                ProductModel.unitL => 'Korak porudžbine (L)',
                ProductModel.unitPiece => 'Korak porudžbine (kom)',
                ProductModel.unitVeza => 'Korak porudžbine (veza)',
                ProductModel.unitPak => 'Korak porudžbine (pak)',
                _ => 'Korak porudžbine (kg)',
              }
            : switch (unitType) {
                ProductModel.unitG =>
                  'Korak porudžbine u gramima (npr. 100 ili 250) - opciono',
                ProductModel.unitMl =>
                  'Korak porudžbine u mililitrima (npr. 250 ili 330) - opciono',
                ProductModel.unitL =>
                  'Korak porudžbine u litrima (npr. 0.5 ili 1) - opciono',
                ProductModel.unitPiece =>
                  'Korak porudžbine (komada, npr. 1 ili 5) - opciono',
                ProductModel.unitVeza =>
                  'Korak porudžbine (veza, npr. 1 ili 2) - opciono',
                ProductModel.unitPak =>
                  'Korak porudžbine (pakovanja, npr. 1 ili 2) - opciono',
                _ => 'Korak porudžbine u kg (npr. 0.5 ili 1) - opciono',
              },
        hintText: isWide
            ? switch (unitType) {
                ProductModel.unitG => 'npr. 250',
                ProductModel.unitMl => 'npr. 330',
                ProductModel.unitL => 'npr. 1',
                ProductModel.unitPiece => 'npr. 1',
                ProductModel.unitVeza => 'npr. 1',
                ProductModel.unitPak => 'npr. 1',
                _ => 'npr. 1',
              }
            : null,
        helperText: _hint(orderStepController.text) ??
            (isWide
                ? 'Mora biti ≤ minimalnoj količini'
                : 'Količina za koju se porudžbina menja (mora biti ≤ minimalnoj količini)'),
      ),
    );
  }

  Widget _buildAvailableField({bool isWide = false}) {
    final isSubUnit =
        unitType == ProductModel.unitG || unitType == ProductModel.unitMl;
    return TextField(
      controller: availableController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        isDense: true,
        labelText: switch (unitType) {
          ProductModel.unitG => 'Na stanju (broj komada / pakovanja)',
          ProductModel.unitMl => 'Na stanju (broj tegli / flaša)',
          ProductModel.unitL => 'Dostupna količina (L)',
          ProductModel.unitPiece => 'Dostupna količina (kom)',
          ProductModel.unitVeza => 'Dostupna količina (veza)',
          ProductModel.unitPak => 'Dostupna količina (pak)',
          _ => 'Dostupna količina (kg)',
        },
        hintText: isWide ? 'Zaliha (opciono)' : null,
        helperText: isSubUnit ? null : _hint(availableController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGroupedCategories = groups != null && groups!.isNotEmpty;
    final isWide = Breakpoints.isTabletOrLarger(context);
    final quickChips = _buildSubUnitQuickChips(context);

    if (isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildCategoryPicker(hasGroupedCategories),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildUnitDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildNameField(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildPriceField(),
              ),
            ],
          ),
          if (onVariantsChanged != null) ...[
            const SizedBox(height: 10),
            ProductVariantsSection(
              variants: variants,
              onVariantsChanged: onVariantsChanged!,
              basePriceController: priceController,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMinOrderField(isWide: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOrderStepField(isWide: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAvailableField(isWide: true),
              ),
            ],
          ),
          if (quickChips != null) quickChips,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryPicker(hasGroupedCategories),
        const SizedBox(height: 10),
        _buildUnitDropdown(),
        const SizedBox(height: 10),
        _buildNameField(),
        const SizedBox(height: 10),
        _buildPriceField(),
        if (onVariantsChanged != null) ...[
          const SizedBox(height: 10),
          ProductVariantsSection(
            variants: variants,
            onVariantsChanged: onVariantsChanged!,
            basePriceController: priceController,
          ),
        ],
        const SizedBox(height: 10),
        _buildMinOrderField(isWide: false),
        if (quickChips != null) quickChips,
        const SizedBox(height: 10),
        _buildOrderStepField(isWide: false),
        const SizedBox(height: 10),
        _buildAvailableField(isWide: false),
      ],
    );
  }
}
