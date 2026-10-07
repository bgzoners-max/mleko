import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/product_model.dart';
import '../../utils/product_helpers.dart';
import '../../widgets/cupertino_category_picker.dart';
import '../../widgets/grouped_category_dropdown.dart';

/// Osnovna sekcija forme proizvoda: kategorija, jedinica, naziv i cena.
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

  @override
  Widget build(BuildContext context) {
    final hasGroupedCategories = groups != null && groups!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        hasGroupedCategories
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
              ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: unitType,
          decoration: const InputDecoration(labelText: 'Jedinica'),
          items: const [
            DropdownMenuItem(
                value: ProductModel.unitKg,
                child: Text('Kilogrami / grami (kg / g)')),
            DropdownMenuItem(
                value: ProductModel.unitL,
                child: Text('Litri / mililitri (L / ml)')),
            DropdownMenuItem(
                value: ProductModel.unitPiece, child: Text('Komadi (kom)')),
            DropdownMenuItem(
                value: ProductModel.unitVeza,
                child: Text('Veza / vezica (veza)')),
            DropdownMenuItem(
                value: ProductModel.unitPak,
                child: Text('Pakovanje (pak)')),
          ],
          onChanged: (v) => onUnitTypeChanged(v ?? ProductModel.unitKg),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Naziv *')),
        const SizedBox(height: 16),
        TextField(
          controller: priceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: switch (unitType) {
              ProductModel.unitL => 'Cena po litru (RSD) *',
              ProductModel.unitPiece => 'Cena po komadu (RSD) *',
              ProductModel.unitVeza => 'Cena po vezi (RSD) *',
              ProductModel.unitPak => 'Cena po pakovanju (RSD) *',
              _ => 'Cena po kg (RSD) *',
            },
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: minOrderController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: switch (unitType) {
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
            helperText: _hint(minOrderController.text),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: orderStepController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: switch (unitType) {
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
            helperText: _hint(orderStepController.text) ??
                'Količina za koju se porudžbina menja (mora biti ≤ minimalnoj količini)',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: availableController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: switch (unitType) {
              ProductModel.unitL => 'Dostupna količina (L ili ml)',
              ProductModel.unitPiece => 'Dostupna količina (komada)',
              ProductModel.unitVeza => 'Dostupna količina (veza)',
              ProductModel.unitPak => 'Dostupna količina (pakovanja)',
              _ => 'Dostupna količina (kg)',
            },
            helperText: _hint(availableController.text),
          ),
        ),
      ],
    );
  }
}

