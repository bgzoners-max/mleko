import 'package:flutter/material.dart';
import 'classified_condition_selector.dart';

class ClassifiedPriceSection extends StatelessWidget {
  final bool isConditionApplicable;
  final String? condition;
  final ValueChanged<String?>? onConditionChanged;
  final String sellerType;
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
    this.sellerType = 'individual',
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
    final hasPriceInput = priceType == 'fixed' || priceType == 'negotiable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isConditionApplicable) ...[
          _buildConditionSelector(),
          const SizedBox(height: 10),
        ],
        if (isWide) ...[
          if (hasPriceInput)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPriceTypeDropdown()),
                const SizedBox(width: 8),
                Expanded(child: _buildPriceWithCurrency(context)),
              ],
            )
          else
            _buildPriceTypeDropdown(),
        ] else ...[
          _buildPriceTypeDropdown(),
          if (hasPriceInput) ...[
            const SizedBox(height: 8),
            _buildPriceWithCurrency(context),
          ],
        ],
      ],
    );
  }

  Widget _buildConditionSelector() {
    return ClassifiedConditionSelector(
      isConditionApplicable: true,
      condition: condition ?? (sellerType == 'business' ? 'new' : 'used'),
      sellerType: sellerType,
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

  Widget _buildCurrencySelector(BuildContext context) {
    final selectedCurrency = currency.toUpperCase() == 'EUR' ? 'EUR' : 'RSD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            BorderSide(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              width: 1.0,
            ),
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

  Widget _buildPriceWithCurrency(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildPriceField()),
        const SizedBox(width: 8),
        _buildCurrencySelector(context),
      ],
    );
  }
}
