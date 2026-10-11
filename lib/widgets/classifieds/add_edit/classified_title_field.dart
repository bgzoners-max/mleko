import 'package:flutter/material.dart';

class ClassifiedTitleField extends StatelessWidget {
  final TextEditingController controller;

  const ClassifiedTitleField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Naslov oglasa *',
            hintText: 'npr. Traktor IMT 539, bušilica Bosch, iPhone 14...',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Unesite naslov oglasa.';
            if (v.trim().length < 4) return 'Naslov mora imati najmanje 4 karaktera.';
            return null;
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
