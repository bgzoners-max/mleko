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
            // Desktop: Sve u jednom redu sa kompaktno spojenom cenom i valutom
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildConditionDropdown()),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _buildPriceTypeDropdown()),
                const SizedBox(width: 8),
                Expanded(flex: 5, child: _buildPriceWithCurrency()),
              ],
            );
          } else {
            // Srednji tablet ekran (600-719px): 2 reda
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildConditionDropdown()),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPriceTypeDropdown()),
                  ],
                ),
                const SizedBox(height: 8),
                _buildPriceWithCurrency(),
              ],
            );
          }
        } else {
          // Pozvati ili Besplatno: Nema polja cene, samo Stanje i Način formiranja
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildConditionDropdown()),
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
              Expanded(flex: 5, child: _buildPriceWithCurrency()),
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
          const SizedBox(height: 8),
        ],
        _buildPriceTypeDropdown(),
        if (hasPriceInput) ...[
          const SizedBox(height: 8),
          _buildPriceWithCurrency(),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      validator: (v) {
        if (priceType == 'fixed' && (v == null || v.trim().isEmpty)) {
          return 'Unesite cenu.';
        }
        return null;
      },
    );
  }

  Widget _buildCurrencySelector() {
    final selectedCurrency = currency.toUpperCase() == 'EUR' ? 'EUR' : 'RSD';
    return SizedBox(
      width: 92,
      height: 42,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        segments: const [
          ButtonSegment<String>(
            value: 'RSD',
            label: Text(
              'RSD',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          ButtonSegment<String>(
            value: 'EUR',
            label: Text(
              'EUR',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
        selected: {selectedCurrency},
        onSelectionChanged: (newSelection) {
          if (newSelection.isNotEmpty) {
            onCurrencyChanged(newSelection.first);
          }
        },
      ),
    );
  }

  Widget _buildPriceWithCurrency() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPriceField()),
        const SizedBox(width: 8),
        _buildCurrencySelector(),
      ],
    );
  }
}
