import 'package:flutter/material.dart';

import '../../models/seller_delivery_models.dart';

class CheckoutDeliveryOptions extends StatelessWidget {
  final bool deliveryLoading;
  final bool hasSellerDeliveryOptions;
  final String? deliveryRestrictionMessage;
  final DeliveryMethod deliveryMethod;
  final ValueChanged<DeliveryMethod?> onDeliveryMethodChanged;
  final List<String> deliveryCities;
  final String? selectedDeliveryCity;
  final ValueChanged<String?> onCityChanged;
  final List<SellerDeliveryPointModel> pointsForSelectedCity;
  final String? selectedDeliveryPointId;
  final ValueChanged<String?> onPointChanged;
  final SellerDeliveryPointModel? selectedDeliveryPoint;
  final String? selectedDeliverySlotId;
  final ValueChanged<String?> onSlotChanged;
  final DeliverySelectionModel? deliverySelection;

  const CheckoutDeliveryOptions({
    super.key,
    required this.deliveryLoading,
    required this.hasSellerDeliveryOptions,
    required this.deliveryRestrictionMessage,
    required this.deliveryMethod,
    required this.onDeliveryMethodChanged,
    required this.deliveryCities,
    required this.selectedDeliveryCity,
    required this.onCityChanged,
    required this.pointsForSelectedCity,
    required this.selectedDeliveryPointId,
    required this.onPointChanged,
    required this.selectedDeliveryPoint,
    required this.selectedDeliverySlotId,
    required this.onSlotChanged,
    required this.deliverySelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RadioGroup<DeliveryMethod>(
      groupValue: deliveryMethod,
      onChanged: onDeliveryMethodChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Način dostave',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const RadioListTile<DeliveryMethod>(
            value: DeliveryMethod.courier,
            contentPadding: EdgeInsets.zero,
            title: Text('Kurirska služba'),
            subtitle: Text(
                'Dostava na adresu putem kurira (npr. Post Express, D Express)'),
          ),
          const RadioListTile<DeliveryMethod>(
            value: DeliveryMethod.pickup,
            contentPadding: EdgeInsets.zero,
            title: Text('Lično preuzimanje'),
            subtitle: Text(
                'Preuzimanje na dogovorenoj lokaciji kod prodavca'),
          ),
          if (deliveryLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ] else if (hasSellerDeliveryOptions) ...[
            const RadioListTile<DeliveryMethod>(
              value: DeliveryMethod.sellerDelivery,
              contentPadding: EdgeInsets.zero,
              title: Text('Dostava od strane prodavca'),
              subtitle: Text(
                  'Prodavac lično dostavlja na definisane lokacije i termine'),
            ),
          if (deliveryRestrictionMessage != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                deliveryRestrictionMessage!,
                style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
              ),
            ),
          ],
          if (deliveryMethod == DeliveryMethod.sellerDelivery) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedDeliveryCity,
              decoration: const InputDecoration(labelText: 'Grad'),
              items: deliveryCities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    ),
                  )
                  .toList(),
              onChanged: onCityChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedDeliveryPointId,
              decoration: const InputDecoration(labelText: 'Lokacija'),
              items: pointsForSelectedCity
                  .map(
                    (point) => DropdownMenuItem<String>(
                      value: point.id,
                      child: Text(point.summaryLabel),
                    ),
                  )
                  .toList(),
              onChanged: onPointChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedDeliverySlotId,
              decoration: const InputDecoration(labelText: 'Termin'),
              items: (selectedDeliveryPoint?.activeSlots ?? const [])
                  .map(
                    (slot) => DropdownMenuItem<String>(
                      value: slot.id,
                      child: Text(
                        '${slot.weekdayLabel}, ${slot.timeRangeLabel}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onSlotChanged,
            ),
            if (deliverySelection != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliverySelection!.scheduleLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deliverySelection!.pointLabel}, ${deliverySelection!.address}',
                    ),
                    if (deliverySelection!.feeLabel != null)
                      Text('Dostava: ${deliverySelection!.feeLabel}'),
                    if (deliverySelection!.minOrderLabel != null)
                      Text(
                        'Minimum za termin: ${deliverySelection!.minOrderLabel}',
                      ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ],
    ),
  );
  }
}
