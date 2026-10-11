import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system.dart';
import '../../../providers/classifieds_provider.dart';

/// Sekcija raspona cena u EUR sa TextField poljima i brzim čipovima.
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

  Widget _buildQuickPricePill(String label, double? min, double? max) {
    final isSelected = classifieds.minPrice == min && classifieds.maxPrice == max;
    return InkWell(
      onTap: () => onQuickPrice(min, max),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AmazonColors.amber.withValues(alpha: 0.25) : AmazonColors.amberLight)
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
                : (isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'CENA (€)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
            ),
          ),
        ),
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
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Od',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
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
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Do',
                    hintStyle: TextStyle(
                      fontSize: 11,
                      color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
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
                  backgroundColor: isDark ? AmazonColors.darkAmberCta : AmazonColors.amber,
                  foregroundColor: AmazonColors.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick price chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildQuickPricePill('< 50 €', null, 50),
            _buildQuickPricePill('50–200 €', 50, 200),
            _buildQuickPricePill('200–500 €', 200, 500),
            _buildQuickPricePill('500 € +', 500, null),
          ],
        ),
      ],
    );
  }
}
