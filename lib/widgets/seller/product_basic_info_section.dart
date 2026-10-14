import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/cupertino_category_picker.dart';
import '../../widgets/grouped_category_dropdown.dart';

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
  });

  String? _hint(String text) => quantityHintBuilder?.call(text, unitType);

  Widget _buildCategoryPicker(bool hasGroupedCategories) {
    return hasGroupedCategories
        ? GroupedCategoryDropdown(
            groups: groups!,
            value: category,
            onChanged: (v) {
              onCategoryChanged(v);
              if (v != null && isVolumeCategory(v)) {
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
              if (v != null && isVolumeCategory(v)) {
                onUnitTypeChanged(ProductModel.unitL);
              }
            },
          );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: unitType,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Jedinica'),
      items: const [
        DropdownMenuItem(
          value: ProductModel.unitKg,
          child: Text('Kilogrami / grami (kg / g)'),
        ),
        DropdownMenuItem(
          value: ProductModel.unitL,
          child: Text('Litri / mililitri (L / ml)'),
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
      decoration: const InputDecoration(labelText: 'Naziv *'),
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: priceController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: switch (unitType) {
          ProductModel.unitL => 'Cena po litru (RSD) *',
          ProductModel.unitPiece => 'Cena po komadu (RSD) *',
          ProductModel.unitVeza => 'Cena po vezi (RSD) *',
          ProductModel.unitPak => 'Cena po pakovanju (RSD) *',
          _ => 'Cena po kg (RSD) *',
        },
      ),
    );
  }

  Widget _buildMinOrderField({bool isWide = false}) {
    return TextField(
      controller: minOrderController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: isWide
            ? switch (unitType) {
                ProductModel.unitL => 'Min. porudžbina (L / ml) *',
                ProductModel.unitPiece => 'Min. porudžbina (kom) *',
                ProductModel.unitVeza => 'Min. porudžbina (veza) *',
                ProductModel.unitPak => 'Min. porudžbina (pak) *',
                _ => 'Min. porudžbina (kg / g) *',
              }
            : switch (unitType) {
                ProductModel.unitL =>
                  'Minimalna porudžbina (L ili ml, npr. 0.75 ili 750) *',
                ProductModel.unitPiece =>
                  'Minimalna porudžbina (komada, npr. 10) *',
                ProductModel.unitVeza =>
                  'Minimalna porudžbina (veza, npr. 1 ili 5) *',
                ProductModel.unitPak =>
                  'Minimalna porudžbina (pakovanja, npr. 1 ili 2) *',
                _ => 'Minimalna porudžbina (kg ili g, npr. 0.1 ili 100g) *',
              },
        hintText: isWide
            ? switch (unitType) {
                ProductModel.unitL => 'npr. 0.75 ili 750',
                ProductModel.unitPiece => 'npr. 10',
                ProductModel.unitVeza => 'npr. 1 ili 5',
                ProductModel.unitPak => 'npr. 1 ili 2',
                _ => 'npr. 0.1 ili 100g',
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
        labelText: isWide
            ? switch (unitType) {
                ProductModel.unitL => 'Korak porudžbine (L / ml)',
                ProductModel.unitPiece => 'Korak porudžbine (kom)',
                ProductModel.unitVeza => 'Korak porudžbine (veza)',
                ProductModel.unitPak => 'Korak porudžbine (pak)',
                _ => 'Korak porudžbine (kg / g)',
              }
            : switch (unitType) {
                ProductModel.unitL =>
                  'Korak porudžbine (L ili ml, npr. 0.5 ili 500) - opciono',
                ProductModel.unitPiece =>
                  'Korak porudžbine (komada, npr. 1 ili 5) - opciono',
                ProductModel.unitVeza =>
                  'Korak porudžbine (veza, npr. 1 ili 2) - opciono',
                ProductModel.unitPak =>
                  'Korak porudžbine (pakovanja, npr. 1 ili 2) - opciono',
                _ => 'Korak porudžbine (kg ili g, npr. 0.1 ili 100g) - opciono',
              },
        hintText: isWide
            ? switch (unitType) {
                ProductModel.unitL => 'npr. 0.5 ili 500',
                ProductModel.unitPiece => 'npr. 1 ili 5',
                ProductModel.unitVeza => 'npr. 1 ili 2',
                ProductModel.unitPak => 'npr. 1 ili 2',
                _ => 'npr. 0.1 ili 100g',
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
    return TextField(
      controller: availableController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: switch (unitType) {
          ProductModel.unitL => 'Dostupna količina (L / ml)',
          ProductModel.unitPiece => 'Dostupna količina (kom)',
          ProductModel.unitVeza => 'Dostupna količina (veza)',
          ProductModel.unitPak => 'Dostupna količina (pak)',
          _ => 'Dostupna količina (kg)',
        },
        hintText: isWide ? 'Zaliha (opciono)' : null,
        helperText: _hint(availableController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGroupedCategories = groups != null && groups!.isNotEmpty;
    final isWide = Breakpoints.isTabletOrLarger(context);

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
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildUnitDropdown(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildNameField(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildPriceField(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMinOrderField(isWide: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOrderStepField(isWide: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAvailableField(isWide: true),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCategoryPicker(hasGroupedCategories),
        const SizedBox(height: 16),
        _buildUnitDropdown(),
        const SizedBox(height: 16),
        _buildNameField(),
        const SizedBox(height: 16),
        _buildPriceField(),
        const SizedBox(height: 16),
        _buildMinOrderField(isWide: false),
        const SizedBox(height: 16),
        _buildOrderStepField(isWide: false),
        const SizedBox(height: 16),
        _buildAvailableField(isWide: false),
      ],
    );
  }
}
