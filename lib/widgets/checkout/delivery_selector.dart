import 'package:flutter/material.dart';

import '../../models/seller_delivery_models.dart';

/// Reusable widget za izbor načina dostave (Kurirska služba, Lično preuzimanje, opciono Dostava prodavca).
class DeliverySelector extends StatelessWidget {
  final DeliveryMethod selectedMethod;
  final ValueChanged<DeliveryMethod> onMethodChanged;
  final bool includeSellerDelivery;
  final bool dense;

  const DeliverySelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    this.includeSellerDelivery = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RadioGroup<DeliveryMethod>(
      groupValue: selectedMethod,
      onChanged: (val) {
        if (val != null) {
          onMethodChanged(val);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Način dostave',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          RadioListTile<DeliveryMethod>(
            value: DeliveryMethod.courier,
            contentPadding: EdgeInsets.zero,
            dense: dense,
            title: const Text('Kurirska služba'),
            subtitle: dense
                ? null
                : const Text(
                    'Dostava na adresu putem kurira (npr. Post Express, D Express)',
                  ),
          ),
          RadioListTile<DeliveryMethod>(
            value: DeliveryMethod.pickup,
            contentPadding: EdgeInsets.zero,
            dense: dense,
            title: const Text('Lično preuzimanje'),
            subtitle: dense
                ? null
                : const Text('Preuzimanje na dogovorenoj lokaciji kod prodavca'),
          ),
          if (includeSellerDelivery)
            RadioListTile<DeliveryMethod>(
              value: DeliveryMethod.sellerDelivery,
              contentPadding: EdgeInsets.zero,
              dense: dense,
              title: const Text('Dostava od strane prodavca'),
              subtitle: dense
                  ? null
                  : const Text(
                      'Prodavac lično dostavlja na definisane lokacije i termine',
                    ),
            ),
        ],
      ),
    );
  }
}
