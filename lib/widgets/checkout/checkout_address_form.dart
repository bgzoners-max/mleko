import 'package:flutter/material.dart';

import '../../models/seller_delivery_models.dart';

class CheckoutAddressForm extends StatelessWidget {
  final DeliveryMethod deliveryMethod;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool savePhoneToProfile;
  final ValueChanged<bool?> onSavePhoneChanged;
  final bool isUserLoggedIn;

  const CheckoutAddressForm({
    super.key,
    required this.deliveryMethod,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.phoneController,
    required this.noteController,
    required this.savePhoneToProfile,
    required this.onSavePhoneChanged,
    required this.isUserLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (deliveryMethod == DeliveryMethod.courier) ...[
          TextField(
            controller: addressController,
            decoration:
                const InputDecoration(labelText: 'Adresa (ulica i broj)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cityController,
            decoration: const InputDecoration(labelText: 'Grad'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: postalCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Poštanski broj'),
          ),
          const SizedBox(height: 12),
        ] else if (deliveryMethod == DeliveryMethod.pickup) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Dogovori se sa prodavcem o mestu i vremenu preuzimanja.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (deliveryMethod == DeliveryMethod.sellerDelivery) ...[
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
                labelText: 'Napomena za preuzimanje (opciono)'),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Kontakt telefon *'),
        ),
        if (isUserLoggedIn)
          CheckboxListTile(
            value: savePhoneToProfile,
            onChanged: onSavePhoneChanged,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Sačuvaj ovaj broj u profilu',
              style: TextStyle(fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Napomena (npr. Treba za subotu)'),
        ),
      ],
    );
  }
}
