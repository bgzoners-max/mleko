import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/seller_delivery_models.dart';

/// Reusable forma za unos podataka o kupcu (adresa, grad, poštanski broj, telefon, napomena).
/// Koristi se na single checkout ekranu i u multi-item checkout formi.
class BuyerForm extends StatelessWidget {
  final DeliveryMethod deliveryMethod;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool savePhoneToProfile;
  final ValueChanged<bool?> onSavePhoneChanged;
  final bool isUserLoggedIn;
  final bool showNoticeBox;

  const BuyerForm({
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
    this.showNoticeBox = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showNoticeBox) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kad pošalješ upit, prodavac će ga primiti i nastaviti razgovor sa tobom o količini, mestu i načinu isporuke.',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              labelText: 'Napomena za preuzimanje (opciono)',
            ),
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
            labelText: 'Napomena (npr. Treba za subotu)',
          ),
        ),
      ],
    );
  }
}
