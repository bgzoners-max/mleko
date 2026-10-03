import 'package:flutter/material.dart';

class ClassifiedSellerTypeSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String sellerType;
  final ValueChanged<String> onChanged;

  const ClassifiedSellerTypeSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.sellerType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final isBusiness = sellerType == 'business';

    Widget buildTypeCard({
      required String type,
      required String title,
      required String subtitle,
      required IconData icon,
      required bool selected,
    }) {
      final activeColor = type == 'business'
          ? const Color(0xFF2563EB)
          : colorScheme.primary;

      return InkWell(
        onTap: () => onChanged(type),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.08)
                : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? activeColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: selected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? activeColor
                      : colorScheme.onSurfaceVariant,
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
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected
                                  ? (isDark ? Colors.white : colorScheme.onSurface)
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? activeColor
                                  : (isDark ? Colors.white38 : Colors.black38),
                              width: selected ? 6 : 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tip oglašivača * (Zakonska deklaracija)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Prema Zakonu o zaštiti potrošača i Zakonu o elektronskoj trgovini, oglašivač je dužan da se izjasni da li nastupa kao fizičko ili pravno lice / trgovac.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            buildTypeCard(
              type: 'individual',
              title: 'Fizičko lice',
              subtitle:
                  'Prodaja ličnih i polovnih stvari, sopstvene robe ili poljoprivrednih proizvoda bez registrovane delatnosti.',
              icon: Icons.person_outline_rounded,
              selected: !isBusiness,
            ),
            const SizedBox(height: 10),
            buildTypeCard(
              type: 'business',
              title: 'Pravno lice / Trgovac',
              subtitle:
                  'Preduzetnik, firma, registrovana radnja ili registrovano poljoprivredno gazdinstvo koje nastupa u okviru svoje delatnosti.',
              icon: Icons.storefront_outlined,
              selected: isBusiness,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBusiness
                    ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08)
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isBusiness
                      ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: isBusiness
                        ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8))
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBusiness
                          ? 'Kao registrovan trgovac / pravno lice, obavezni ste da poslujete u skladu sa Zakonom o zaštiti potrošača i obezbedite zakonska prava kupcima (pravo na jednostrani odustanak od ugovora na daljinu u roku od 14 dana, saobraznost robe, izdavanje računa).'
                          : 'Na kupovinu od fizičkog lica ne primenjuju se odredbe Zakona o zaštiti potrošača o pravu na jednostrani odustanak od ugovora u roku od 14 dana.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isBusiness
                            ? (isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1E3A8A))
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
