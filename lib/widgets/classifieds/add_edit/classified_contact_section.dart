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
            prefixIcon: Icon(Icons.phone_outlined, size: 18),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
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
      ],
    );
  }
}
