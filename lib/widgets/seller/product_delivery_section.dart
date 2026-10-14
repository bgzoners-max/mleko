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
        Text('Način preuzimanja *',
            style: Theme.of(context).textTheme.labelLarge),
        ...AppConstants.pickupOptions.map((opt) => CheckboxListTile(
              title: Text(opt),
              value: pickupOptions.contains(opt),
              onChanged: (_) => onPickupOptionToggled(opt),
            )),
        const SizedBox(height: 8),
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
              sellerDeliveryPoints.isNotEmpty) ...[
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

