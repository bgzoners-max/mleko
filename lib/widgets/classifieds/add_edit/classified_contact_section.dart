import 'package:flutter/material.dart';

class ClassifiedContactSection extends StatelessWidget {
  final TextEditingController phoneController;
  final bool phonePublic;
  final ValueChanged<bool> onPhonePublicChanged;

  const ClassifiedContactSection({
    super.key,
    required this.phoneController,
    required this.phonePublic,
    required this.onPhonePublicChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Kontakt telefon',
            hintText: 'npr. 064 123 4567',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Prikaži telefon javno u oglasu'),
          subtitle: const Text('Ako isključite, kupci vas mogu kontaktirati samo preko četa.'),
          value: phonePublic,
          onChanged: onPhonePublicChanged,
        ),
      ],
    );
  }
}
