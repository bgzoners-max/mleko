import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';

/// Sekcija dostave i preuzimanja: lokacija, način preuzimanja,
/// lična dostava domaćina, switch-evi i opis.
class ProductDeliverySection extends StatelessWidget {
  final String? farmLocation;
  final List<String> pickupOptions;
  final ValueChanged<String> onPickupOptionToggled;
  final bool deliveryPointsLoading;
  final List<SellerDeliveryPointModel> sellerDeliveryPoints;
  final ProductDeliveryMode deliveryMode;
  final ValueChanged<ProductDeliveryMode> onDeliveryModeChanged;
  final Set<String> selectedDeliveryPointIds;
  final ValueChanged<String> onDeliveryPointToggled;
  final TextEditingController descriptionController;
  final bool isDomestic;
  final ValueChanged<bool> onDomesticChanged;
  final bool availableNow;
  final ValueChanged<bool> onAvailableNowChanged;
  final VoidCallback onEditDeliveryLocations;

  const ProductDeliverySection({
    super.key,
    this.farmLocation,
    required this.pickupOptions,
    required this.onPickupOptionToggled,
    required this.deliveryPointsLoading,
    required this.sellerDeliveryPoints,
    required this.deliveryMode,
    required this.onDeliveryModeChanged,
    required this.selectedDeliveryPointIds,
    required this.onDeliveryPointToggled,
    required this.descriptionController,
    required this.isDomestic,
    required this.onDomesticChanged,
    required this.availableNow,
    required this.onAvailableNowChanged,
    required this.onEditDeliveryLocations,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = Breakpoints.isTabletOrLarger(context);

    final pickupWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Način preuzimanja *',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        ...AppConstants.pickupOptions.map(
          (opt) => CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(opt),
            value: pickupOptions.contains(opt),
            onChanged: (_) => onPickupOptionToggled(opt),
          ),
        ),
      ],
    );

    final deliveryModeWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Lična dostava domaćina za ovaj proizvod',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            TextButton.icon(
              onPressed: onEditDeliveryLocations,
              icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
              label: const Text('Uredi lokacije'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (deliveryPointsLoading)
          const LinearProgressIndicator()
        else ...[
          _ModeTile(
            value: ProductDeliveryMode.none,
            groupValue: deliveryMode,
            title: 'Bez lične dostave domaćina',
            onChanged: onDeliveryModeChanged,
          ),
          _ModeTile(
            value: ProductDeliveryMode.allSellerPoints,
            groupValue: deliveryMode,
            title: 'Na svim mojim lokacijama',
            enabled: sellerDeliveryPoints.isNotEmpty,
            onChanged: onDeliveryModeChanged,
          ),
          _ModeTile(
            value: ProductDeliveryMode.selectedPoints,
            groupValue: deliveryMode,
            title: 'Samo na izabranim lokacijama',
            enabled: sellerDeliveryPoints.isNotEmpty,
            onChanged: onDeliveryModeChanged,
          ),
          if (sellerDeliveryPoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Još nemate definisane lokacije lične dostave. Dodajte '
                    'ih u podešavanjima da biste ih ponudili kupcima.',
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: onEditDeliveryLocations,
                    icon: const Icon(Icons.add_location_alt_outlined, size: 16),
                    label: const Text('Dodaj punktove dostave'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          if (deliveryMode == ProductDeliveryMode.selectedPoints &&
              sellerDeliveryPoints.isNotEmpty) ...[
            ...sellerDeliveryPoints.map(
              (point) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(point.summaryLabel),
                subtitle: Text(
                  point.isActive
                      ? '${point.city} • ${point.activeSlots.length} aktivnih termina'
                      : '${point.city} • neaktivna lokacija',
                ),
                value: selectedDeliveryPointIds.contains(point.id),
                onChanged: (_) => onDeliveryPointToggled(point.id),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: OutlinedButton.icon(
                onPressed: onEditDeliveryLocations,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Dodaj ili izmeni punktove dostave'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (farmLocation != null && farmLocation!.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        const TextSpan(
                          text: 'Matična lokacija gazdinstva: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: farmLocation!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ' (automatski iz profila)',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isWide) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: pickupWidget,
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 5,
                child: deliveryModeWidget,
              ),
            ],
          ),
        ] else ...[
          pickupWidget,
          const SizedBox(height: 12),
          deliveryModeWidget,
        ],
        const SizedBox(height: 16),
        if (isWide) ...[
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Domaće / Porodično gazdinstvo'),
                  value: isDomestic,
                  onChanged: onDomesticChanged,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dostupno sada'),
                  value: availableNow,
                  onChanged: onAvailableNowChanged,
                ),
              ),
            ],
          ),
        ] else ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Domaće / Porodično gazdinstvo'),
            value: isDomestic,
            onChanged: onDomesticChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dostupno sada'),
            value: availableNow,
            onChanged: onAvailableNowChanged,
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          maxLength: AppConstants.maxProductDescriptionLength,
          decoration: const InputDecoration(
              labelText: 'Opis (max 300 karaktera)'),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ProductDeliveryMode value;
  final ProductDeliveryMode groupValue;
  final String title;
  final bool enabled;
  final ValueChanged<ProductDeliveryMode> onChanged;

  const _ModeTile({
    required this.value,
    required this.groupValue,
    required this.title,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ProductDeliveryMode>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: groupValue,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      // ignore: deprecated_member_use
      onChanged: enabled
          ? (v) {
              if (v == null) return;
              onChanged(v);
            }
          : null,
    );
  }
}

