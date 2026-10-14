import 'package:flutter/material.dart';

/// Istaknuta Call-to-Action kartica za kupce koji žele da postanu prodavci / otvore gazdinstvo.
/// Pozicionirana na vrhu sidebara, odmah pre sekcije sa porudžbinama i omiljenim proizvodima.
class BecomeSellerCtaCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const BecomeSellerCtaCard({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prirodne zelene nijanse za promociju otvaranja gazdinstva
    final bgColor = isDark
        ? (isSelected ? const Color(0xFF193B26) : const Color(0xFF132B1D))
        : (isSelected ? const Color(0xFFE2F7E9) : const Color(0xFFEFF8F2));

    final borderColor = isSelected
        ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF1E462E) : const Color(0xFFC7E7D1));

    final iconBgColor = isDark
        ? const Color(0xFF1E462E)
        : const Color(0xFFD4EEDC);

    final primaryGreen = isDark
        ? const Color(0xFF81C784)
        : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    size: 24,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Prodaješ domaću hranu?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.grey.shade900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Otvori profil gazdinstva i prodaj direktno',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Otvori gazdinstvo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
