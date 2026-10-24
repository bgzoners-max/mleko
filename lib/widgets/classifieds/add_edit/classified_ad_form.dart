import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/classified_category_model.dart';
import 'classified_attributes_section.dart';
import 'classified_category_selector.dart';
import 'classified_city_autocomplete.dart';
import 'classified_contact_section.dart';
import 'classified_description_field.dart';
import 'classified_image_picker_row.dart';
import 'classified_price_section.dart';
import 'classified_promotion_section.dart';
import 'classified_seller_type_section.dart';
import 'classified_submit_button.dart';
import 'classified_title_field.dart';

/// Formular za unos i izmenu oglasa.
///
/// Izdvojen iz ekrana kako bi se održala modularnost i ograničenje veličine fajla.
class ClassifiedAdForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isTablet;
  final ThemeData theme;
  final ColorScheme colorScheme;

  // Slike
  final bool isPickingImages;
  final VoidCallback onPickImages;
  final List<String> existingImages;
  final List<Uint8List> newImageBytes;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;
  final int incomingCount;
  final String? imageProcessingStatus;
  final double? imageProcessingProgress;

  // Naslov
  final TextEditingController titleController;

  // Kategorija
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final VoidCallback onOpenCategoryPicker;

  // Cena i stanje
  final bool isConditionApplicable;
  final String condition;
  final ValueChanged<String?> onConditionChanged;
  final String priceType;
  final String currency;
  final TextEditingController priceController;
  final ValueChanged<String?> onPriceTypeChanged;
  final ValueChanged<String?> onCurrencyChanged;

  // Dinamički atributi po kategoriji
  final List<ClassifiedCategoryModel> selectedCategoryBreadcrumbs;
  final Map<String, dynamic> attributes;
  final void Function(String key, dynamic value) onAttributeChanged;

  // Grad i telefon
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final bool phonePublic;
  final ValueChanged<bool> onPhonePublicChanged;

  // Opis
  final TextEditingController descController;

  // Tip oglašivača
  final String sellerType;
  final ValueChanged<String> onSellerTypeChanged;

  // Promocija
  final bool isUrgent;
  final ValueChanged<bool> onUrgentChanged;

  // Objava
  final bool loading;
  final bool isEdit;
  final String? uploadStatusText;
  final VoidCallback onSubmit;

  const ClassifiedAdForm({
    super.key,
    required this.formKey,
    required this.isTablet,
    required this.theme,
    required this.colorScheme,
    required this.isPickingImages,
    required this.onPickImages,
    required this.existingImages,
    required this.newImageBytes,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.incomingCount,
    this.imageProcessingStatus,
    this.imageProcessingProgress,
    required this.titleController,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
    required this.onOpenCategoryPicker,
    required this.isConditionApplicable,
    required this.condition,
    required this.onConditionChanged,
    required this.priceType,
    required this.currency,
    required this.priceController,
    required this.onPriceTypeChanged,
    required this.onCurrencyChanged,
    required this.selectedCategoryBreadcrumbs,
    required this.attributes,
    required this.onAttributeChanged,
    required this.cityController,
    required this.phoneController,
    required this.phonePublic,
    required this.onPhonePublicChanged,
    required this.descController,
    required this.sellerType,
    required this.onSellerTypeChanged,
    required this.isUrgent,
    required this.onUrgentChanged,
    required this.loading,
    required this.isEdit,
    this.uploadStatusText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 960;

    if (isDesktop) {
      return Form(
        key: formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEVA KOLONA: Slike, Lokacija, Kontakt, Zakonska deklaracija, Promocija
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClassifiedImagePickerRow(
                    theme: theme,
                    colorScheme: colorScheme,
                    isPickingImages: isPickingImages,
                    onPickImages: onPickImages,
                    existingImages: existingImages,
                    newImageBytes: newImageBytes,
                    onRemoveExisting: onRemoveExisting,
                    onRemoveNew: onRemoveNew,
                    incomingCount: incomingCount,
                    imageProcessingStatus: imageProcessingStatus,
                    imageProcessingProgress: imageProcessingProgress,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClassifiedCityAutocomplete(controller: cityController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Kontakt telefon',
                            hintText: 'npr. 064 123 4567',
                            prefixIcon: Icon(Icons.phone_outlined, size: 18),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    value: phonePublic,
                    onChanged: onPhonePublicChanged,
                  ),
                  const SizedBox(height: 6),
                  ClassifiedSellerTypeSection(
                    theme: theme,
                    colorScheme: colorScheme,
                    sellerType: sellerType,
                    onChanged: onSellerTypeChanged,
                  ),
                  ClassifiedPromotionSection(
                    theme: theme,
                    colorScheme: colorScheme,
                    isUrgent: isUrgent,
                    onUrgentChanged: onUrgentChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // DESNA KOLONA: Naslov, Kategorija, Cena, Atributi, Opis, Submit dugme
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClassifiedTitleField(controller: titleController),
                  ClassifiedCategorySelector(
                    selectedCategoryId: selectedCategoryId,
                    selectedCategoryName: selectedCategoryName,
                    colorScheme: colorScheme,
                    onTap: onOpenCategoryPicker,
                  ),
                  const SizedBox(height: 10),
                  ClassifiedPriceSection(
                    isConditionApplicable: isConditionApplicable,
                    condition: condition,
                    onConditionChanged: onConditionChanged,
                    priceType: priceType,
                    currency: currency,
                    priceController: priceController,
                    onPriceTypeChanged: onPriceTypeChanged,
                    onCurrencyChanged: onCurrencyChanged,
                  ),
                  const SizedBox(height: 10),
                  ClassifiedAttributesWrapper(
                    theme: theme,
                    colorScheme: colorScheme,
                    categoryId: selectedCategoryId,
                    breadcrumbs: selectedCategoryBreadcrumbs,
                    currentAttributes: attributes,
                    onChanged: onAttributeChanged,
                  ),
                  ClassifiedDescriptionField(controller: descController),
                  const SizedBox(height: 8),
                  ClassifiedSubmitButton(
                    loading: loading,
                    isEdit: isEdit,
                    uploadStatusText: uploadStatusText,
                    onSubmit: onSubmit,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobilni i uži prikaz (< 960px)
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassifiedImagePickerRow(
            theme: theme,
            colorScheme: colorScheme,
            isPickingImages: isPickingImages,
            onPickImages: onPickImages,
            existingImages: existingImages,
            newImageBytes: newImageBytes,
            onRemoveExisting: onRemoveExisting,
            onRemoveNew: onRemoveNew,
            incomingCount: incomingCount,
            imageProcessingStatus: imageProcessingStatus,
            imageProcessingProgress: imageProcessingProgress,
          ),
          const SizedBox(height: 10),

          ClassifiedTitleField(controller: titleController),

          ClassifiedCategorySelector(
            selectedCategoryId: selectedCategoryId,
            selectedCategoryName: selectedCategoryName,
            colorScheme: colorScheme,
            onTap: onOpenCategoryPicker,
          ),
          const SizedBox(height: 10),

          ClassifiedPriceSection(
            isConditionApplicable: isConditionApplicable,
            condition: condition,
            onConditionChanged: onConditionChanged,
            priceType: priceType,
            currency: currency,
            priceController: priceController,
            onPriceTypeChanged: onPriceTypeChanged,
            onCurrencyChanged: onCurrencyChanged,
          ),
          const SizedBox(height: 10),

          ClassifiedAttributesWrapper(
            theme: theme,
            colorScheme: colorScheme,
            categoryId: selectedCategoryId,
            breadcrumbs: selectedCategoryBreadcrumbs,
            currentAttributes: attributes,
            onChanged: onAttributeChanged,
          ),

          if (isTablet) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClassifiedCityAutocomplete(controller: cityController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Kontakt telefon',
                      hintText: 'npr. 064 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              value: phonePublic,
              onChanged: onPhonePublicChanged,
            ),
          ] else ...[
            ClassifiedCityAutocomplete(controller: cityController),
            const SizedBox(height: 8),
            ClassifiedContactSection(
              phoneController: phoneController,
              phonePublic: phonePublic,
              onPhonePublicChanged: onPhonePublicChanged,
            ),
          ],
          const SizedBox(height: 10),

          ClassifiedDescriptionField(controller: descController),

          ClassifiedSellerTypeSection(
            theme: theme,
            colorScheme: colorScheme,
            sellerType: sellerType,
            onChanged: onSellerTypeChanged,
          ),

          ClassifiedPromotionSection(
            theme: theme,
            colorScheme: colorScheme,
            isUrgent: isUrgent,
            onUrgentChanged: onUrgentChanged,
          ),
          const SizedBox(height: 6),

          ClassifiedSubmitButton(
            loading: loading,
            isEdit: isEdit,
            uploadStatusText: uploadStatusText,
            onSubmit: onSubmit,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
