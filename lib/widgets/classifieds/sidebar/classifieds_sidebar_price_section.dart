import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system.dart';
import '../../../providers/classifieds_provider.dart';

/// Sekcija raspona cena (EUR / RSD) sa izborom valute, TextField poljima i brzim čipovima.
class ClassifiedsSidebarPriceSection extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final VoidCallback onApplyPrice;
  final void Function(double? min, double? max) onQuickPrice;
  final bool isDark;

  const ClassifiedsSidebarPriceSection({
    super.key,
    required this.classifieds,
    required this.minPriceController,
    required this.maxPriceController,
    required this.onApplyPrice,
    required this.onQuickPrice,
    required this.isDark,
  });

  Widget _buildCurrencyChip(String label, String? currencyValue) {
    final isSelected = classifieds.selectedCurrency == currencyValue;
    return InkWell(
      onTap: () => classifieds.selectCurrency(currencyValue),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AmazonColors.green.withValues(alpha: 0.25)
                  : AmazonColors.green.withValues(alpha: 0.12))
              : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                : (isDark
                    ? AmazonColors.darkTextPrimary
                    : AmazonColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPricePill(
    String label,
    double? min,
    double? max, {
    required String targetCurrency,
  }) {
    final isSelected = classifieds.minPrice == min &&
        classifieds.maxPrice == max &&
        (classifieds.selectedCurrency == null ||
            classifieds.selectedCurrency == targetCurrency);
    return InkWell(
      onTap: () {
        if (classifieds.selectedCurrency == null) {
          classifieds.selectCurrency(targetCurrency);
        }
        onQuickPrice(min, max);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AmazonColors.amber.withValues(alpha: 0.25)
                  : AmazonColors.amberLight)
              : (isDark ? AmazonColors.darkCanvas : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AmazonColors.amberDark
                : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AmazonColors.amberLight : AmazonColors.amberDark)
                : (isDark
                    ? AmazonColors.darkTextPrimary
                    : AmazonColors.textPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = classifieds.selectedCurrency;
    final isRsd = currency == 'RSD';
    final headerLabel = currency == null
        ? 'CENA (EUR / RSD)'
        : (isRsd ? 'CENA (RSD)' : 'CENA (€)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            headerLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark
                  ? AmazonColors.darkTextSecondary
                  : AmazonColors.textSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildCurrencyChip('Sve', null),
            _buildCurrencyChip('EUR (€)', 'EUR'),
            _buildCurrencyChip('RSD', 'RSD'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: minPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => onApplyPrice(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Od',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AmazonColors.darkTextSecondary
                          : AmazonColors.textSecondary,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark
                            ? AmazonColors.darkBorder
                            : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark
                            ? AmazonColors.darkBorder
                            : AmazonColors.borderGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: SizedBox(
                height: 34,
                child: TextField(
                  controller: maxPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => onApplyPrice(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AmazonColors.darkTextPrimary
                        : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Do',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AmazonColors.darkTextSecondary
                          : AmazonColors.textSecondary,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark
                            ? AmazonColors.darkBorder
                            : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark
                            ? AmazonColors.darkBorder
                            : AmazonColors.borderGray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: onApplyPrice,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isDark ? AmazonColors.darkAmberCta : AmazonColors.amber,
                  foregroundColor: AmazonColors.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick price chips prilagođeni valuti
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: isRsd
              ? [
                  _buildQuickPricePill('< 5.000', null, 5000,
                      targetCurrency: 'RSD'),
                  _buildQuickPricePill('5–20k', 5000, 20000,
                      targetCurrency: 'RSD'),
                  _buildQuickPricePill('20–50k', 20000, 50000,
                      targetCurrency: 'RSD'),
                  _buildQuickPricePill('50k+ RSD', 50000, null,
                      targetCurrency: 'RSD'),
                ]
              : [
                  _buildQuickPricePill('< 50 €', null, 50,
                      targetCurrency: 'EUR'),
                  _buildQuickPricePill('50–200 €', 50, 200,
                      targetCurrency: 'EUR'),
                  _buildQuickPricePill('200–500 €', 200, 500,
                      targetCurrency: 'EUR'),
                  _buildQuickPricePill('500 € +', 500, null,
                      targetCurrency: 'EUR'),
                ],
        ),
      ],
    );
  }
}
