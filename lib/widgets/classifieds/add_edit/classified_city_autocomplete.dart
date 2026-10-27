import 'package:flutter/material.dart';
import '../../../constants/serbian_cities.dart';
import '../../../constants/serbian_postal_codes.dart';

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
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          return const Iterable<String>.empty();
        }
        final cityMatches = SerbianCities.suggestions(query);
        final postalMatches = SerbianPostalCodes.suggestions(query, limit: 10)
            .map((e) => e.city)
            .where((city) => !cityMatches.contains(city));
        return [...cityMatches, ...postalMatches];
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
            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
