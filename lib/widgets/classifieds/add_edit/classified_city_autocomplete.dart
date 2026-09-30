import 'package:flutter/material.dart';
import '../../../constants/serbian_cities.dart';

class ClassifiedCityAutocomplete extends StatelessWidget {
  final TextEditingController controller;

  const ClassifiedCityAutocomplete({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }
        return SerbianCities.suggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sinhronizacija vrednosti
        if (controller.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
          fieldTextEditingController.text = controller.text;
        }
        fieldTextEditingController.addListener(() {
          controller.text = fieldTextEditingController.text;
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
    );
  }
}
