import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/seller_delivery_models.dart';

class CheckoutSingleBuyerForm extends StatelessWidget {
  final DeliveryMethod deliveryMethod;
  final ValueChanged<DeliveryMethod> onDeliveryMethodChanged;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool showSavePhone;
  final bool savePhoneToProfile;
  final ValueChanged<bool> onSavePhoneChanged;

  const CheckoutSingleBuyerForm({
    super.key,
    required this.deliveryMethod,
    required this.onDeliveryMethodChanged,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.phoneController,
    required this.noteController,
    required this.showSavePhone,
    required this.savePhoneToProfile,
    required this.onSavePhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Način dostave', style: Theme.of(context).textTheme.titleSmall),
        RadioGroup<DeliveryMethod>(
          groupValue: deliveryMethod,
          onChanged: (v) {
            if (v != null) {
              onDeliveryMethodChanged(v);
            }
          },
          child: const Column(
            children: [
              RadioListTile<DeliveryMethod>(
                value: DeliveryMethod.courier,
                title: Text('Kurirska služba'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              RadioListTile<DeliveryMethod>(
                value: DeliveryMethod.pickup,
                title: Text('Lično preuzimanje'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kad pošalješ upit, prodavac će ga primiti i nastaviti razgovor sa tobom o količini, mestu i načinu isporuke.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
            decoration: const InputDecoration(labelText: 'Poštanski broj'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 8),
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
        ],
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Kontakt telefon *'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: noteController,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Napomena (npr. Treba za subotu)'),
        ),
        const SizedBox(height: 4),
        if (showSavePhone)
          CheckboxListTile(
            value: savePhoneToProfile,
            onChanged: (v) => onSavePhoneChanged(v ?? false),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'Sačuvaj ovaj broj u profilu',
              style: TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }
}
