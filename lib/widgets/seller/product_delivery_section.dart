import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';

/// Sekcija dostave i preuzimanja: lokacija, način preuzimanja,
/// lična dostava domaćina, switch-evi i opis.
class ProductDeliverySection extends StatelessWidget {
  final String? location;
  final ValueChanged<String?> onLocationChanged;
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

  const ProductDeliverySection({
    super.key,
    required this.location,
    required this.onLocationChanged,
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(location),
          initialValue: location,
          decoration: const InputDecoration(labelText: 'Lokacija *'),
          items: AppConstants.regions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: onLocationChanged,
        ),
        const SizedBox(height: 16),
        Text('Način preuzimanja *',
            style: Theme.of(context).textTheme.labelLarge),
        ...AppConstants.pickupOptions.map((opt) => CheckboxListTile(
              title: Text(opt),
              value: pickupOptions.contains(opt),
              onChanged: (_) => onPickupOptionToggled(opt),
            )),
        const SizedBox(height: 8),
        Text(
          'Lična dostava domaćina za ovaj proizvod',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        if (deliveryPointsLoading)
          const LinearProgressIndicator()
        else ...[
          const _InfoBox(
            text: 'Izaberite kako ovaj proizvod koristi vašu ličnu dostavu. '
                'Ako prodajete isti proizvod samo u određenom gradu ili na '
                'određenoj adresi, koristite opciju '
                '"Samo na izabranim lokacijama".',
          ),
          const SizedBox(height: 8),
          _ModeTile(
            value: ProductDeliveryMode.none,
            groupValue: deliveryMode,
            title: 'Bez lične dostave domaćina',
            subtitle: 'Koristite ovo ako proizvod nije za vašu organizovanu '
                'dostavu. Kupac se može dogovoriti sa vama direktno, ali ne '
                'bira vaše definisane punktove i termine.',
            onChanged: onDeliveryModeChanged,
          ),
          _ModeTile(
            value: ProductDeliveryMode.allSellerPoints,
            groupValue: deliveryMode,
            title: 'Na svim mojim lokacijama',
            subtitle: 'Koristite ovo ako ovaj proizvod može da ide na svaki '
                'vaš aktivan punkt dostave. Kupac bira bilo koji grad, '
                'adresu i termin koje ste već definisali.',
            enabled: sellerDeliveryPoints.isNotEmpty,
            onChanged: onDeliveryModeChanged,
          ),
          _ModeTile(
            value: ProductDeliveryMode.selectedPoints,
            groupValue: deliveryMode,
            title: 'Samo na izabranim lokacijama',
            subtitle: 'Koristite ovo kada proizvod nosite samo na određene '
                'gradove ili adrese. Ispod zatim čekirate tačne punktove na '
                'kojima je proizvod dostupan.',
            enabled: sellerDeliveryPoints.isNotEmpty,
            onChanged: onDeliveryModeChanged,
          ),
          if (sellerDeliveryPoints.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Još nemate definisane lokacije lične dostave. Prvo ih '
                'dodajte u Seller Settings, pa se vratite ovde da uključite '
                'dostavu po proizvodu.',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          if (deliveryMode == ProductDeliveryMode.selectedPoints)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'Čekirajte samo one lokacije na kojima kupac stvarno može '
                'da poruči ovaj proizvod.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          if (deliveryMode == ProductDeliveryMode.selectedPoints &&
              sellerDeliveryPoints.isNotEmpty)
            ...sellerDeliveryPoints.map(
              (point) => CheckboxListTile(
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
        ],
        if (Breakpoints.isTabletOrLarger(context)) ...[
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
              const SizedBox(width: 16),
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
            title: const Text('Domaće / Porodično gazdinstvo'),
            value: isDomestic,
            onChanged: onDomesticChanged,
          ),
          SwitchListTile(
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

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.green.shade900, height: 1.4),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ProductDeliveryMode value;
  final ProductDeliveryMode groupValue;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<ProductDeliveryMode> onChanged;

  const _ModeTile({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
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
      title: Text(title),
      subtitle: Text(subtitle),
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

