import 'package:flutter/material.dart';
import 'classified_condition_selector.dart';

class ClassifiedPriceSection extends StatelessWidget {
  final bool isConditionApplicable;
  final String? condition;
  final ValueChanged<String?>? onConditionChanged;
  final String priceType;
  final String currency;
  final TextEditingController priceController;
  final ValueChanged<String?> onPriceTypeChanged;
  final ValueChanged<String?> onCurrencyChanged;

  const ClassifiedPriceSection({
    super.key,
    this.isConditionApplicable = false,
    this.condition,
    this.onConditionChanged,
    required this.priceType,
    required this.currency,
    required this.priceController,
    required this.onPriceTypeChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;
    final isDesktopWidth = width >= 720;
    final hasPriceInput = priceType == 'fixed' || priceType == 'negotiable';

    // 1. Široki ekrani (Desktop / Tablet)
    if (isWide) {
      if (isConditionApplicable) {
        // Kada kategorija IMA stanje predmeta:
        if (hasPriceInput) {
          if (isDesktopWidth) {
            // Desktop: Sve u jednom kompaktnom redu!
            // [ Stanje predmeta ] [ Način formiranja cene ] [ Cena * ] [ Valuta ]
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildConditionDropdown()),
                const SizedBox(width: 10),
                Expanded(flex: 4, child: _buildPriceTypeDropdown()),
                const SizedBox(width: 10),
                Expanded(flex: 3, child: _buildPriceField()),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: _buildCurrencyDropdown()),
              ],
            );
          } else {
            // Srednji tablet ekran (600-719px): 2 lepa reda od po 2 polja
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildConditionDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildPriceTypeDropdown()),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildPriceField()),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: _buildCurrencyDropdown()),
                  ],
                ),
              ],
            );
          }
        } else {
          // Pozvati ili Besplatno: Nema polja cene, samo Stanje i Način formiranja u istom redu
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConditionDropdown()),
              const SizedBox(width: 10),
              Expanded(child: _buildPriceTypeDropdown()),
            ],
          );
        }
      } else {
        // Kada kategorija NEMA stanje predmeta (nekretnine, životinje, usluge):
        if (hasPriceInput) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: _buildPriceTypeDropdown()),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: _buildPriceField()),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildCurrencyDropdown()),
            ],
          );
        } else {
          return _buildPriceTypeDropdown();
        }
      }
    }

    // 2. Mobilni prikaz (< 600px)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isConditionApplicable) ...[
          _buildConditionDropdown(),
          const SizedBox(height: 10),
        ],
        _buildPriceTypeDropdown(),
        if (hasPriceInput) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildPriceField()),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildCurrencyDropdown()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildConditionDropdown() {
    return ClassifiedConditionSelector(
      isConditionApplicable: true,
      condition: condition ?? 'used',
      onChanged: onConditionChanged ?? (_) {},
    );
  }

  Widget _buildPriceTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: priceType,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Način formiranja cene',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: const [
        DropdownMenuItem(
          value: 'fixed',
          child: Text('Fiksna cena', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'negotiable',
          child: Text('Cena po dogovoru', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'call',
          child: Text('Pozvati za cenu', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem(
          value: 'free',
          child: Text('Besplatno (poklanjam)', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: onPriceTypeChanged,
    );
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: priceController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: priceType == 'fixed' ? 'Cena *' : 'Okvirna cena',
        hintText: 'npr. 2500',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (v) {
        if (priceType == 'fixed' && (v == null || v.trim().isEmpty)) {
          return 'Unesite cenu.';
        }
        return null;
      },
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: currency,
      decoration: const InputDecoration(
        labelText: 'Valuta',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}
