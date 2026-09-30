import 'package:flutter/material.dart';

class ClassifiedDescriptionField extends StatelessWidget {
  final TextEditingController controller;

  const ClassifiedDescriptionField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
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
      ],
    );
  }
}
