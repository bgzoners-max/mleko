import 'package:flutter/material.dart';

class ClassifiedPriceSection extends StatelessWidget {
  final String priceType;
  final String currency;
  final TextEditingController priceController;
  final ValueChanged<String?> onPriceTypeChanged;
  final ValueChanged<String?> onCurrencyChanged;

  const ClassifiedPriceSection({
    super.key,
    required this.priceType,
    required this.currency,
    required this.priceController,
    required this.onPriceTypeChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: priceType,
          decoration: const InputDecoration(labelText: 'Način formiranja cene'),
          items: const [
            DropdownMenuItem(value: 'fixed', child: Text('Fiksna cena')),
            DropdownMenuItem(value: 'negotiable', child: Text('Cena po dogovoru')),
            DropdownMenuItem(value: 'call', child: Text('Pozvati za cenu')),
            DropdownMenuItem(value: 'free', child: Text('Besplatno (poklanjam)')),
          ],
          onChanged: onPriceTypeChanged,
        ),
        if (priceType == 'fixed' || priceType == 'negotiable') ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: priceType == 'fixed' ? 'Cena *' : 'Okvirna cena',
                    hintText: 'npr. 2500',
                  ),
                  validator: (v) {
                    if (priceType == 'fixed' && (v == null || v.trim().isEmpty)) {
                      return 'Unesite cenu.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: currency,
                  decoration: const InputDecoration(
                    labelText: 'Valuta',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'RSD',
                      child: Text('RSD (din)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text('EUR (€)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
