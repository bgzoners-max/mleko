import 'package:flutter/material.dart';

class ClassifiedSellerTypeSection extends StatefulWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String sellerType;
  final ValueChanged<String> onChanged;
  final bool initialExpanded;

  const ClassifiedSellerTypeSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.sellerType,
    required this.onChanged,
    this.initialExpanded = false,
  });

  @override
  State<ClassifiedSellerTypeSection> createState() =>
      _ClassifiedSellerTypeSectionState();
}

class _ClassifiedSellerTypeSectionState
    extends State<ClassifiedSellerTypeSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final colorScheme = widget.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isBusiness = widget.sellerType == 'business';

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
        onTap: () => widget.onChanged(type),
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: _isExpanded ? 9 : 6.5,
          ),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: isDark ? 0.20 : 0.08)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? activeColor
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: _isExpanded
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor.withValues(alpha: 0.15)
                      : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? activeColor
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected
                                    ? (isDark
                                        ? Colors.white
                                        : colorScheme.onSurface)
                                    : colorScheme.onSurface,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? activeColor
                                  : (isDark ? Colors.white38 : Colors.black38),
                              width: selected ? 4.5 : 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 280;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: 1.0,
            ),
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tip oglašivača * (Zakonska deklaracija)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prema Zakonu o zaštiti potrošača i Zakonu o elektronskoj trgovini, oglašivač je dužan da se izjasni da li nastupa kao fizičko ili pravno lice / trgovac.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: buildTypeCard(
                            type: 'individual',
                            title: 'Fizičko lice',
                            subtitle:
                                'Prodaja ličnih i polovnih stvari, sopstvene robe ili poljoprivrednih proizvoda bez registrovane delatnosti.',
                            icon: Icons.person_outline_rounded,
                            selected: !isBusiness,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          flex: 10,
                          child: buildTypeCard(
                            type: 'business',
                            title: 'Pravno lice / Trgovac',
                            subtitle:
                                'Preduzetnik, firma, registrovana radnja ili registrovano poljoprivredno gazdinstvo u okviru delatnosti.',
                            icon: Icons.storefront_outlined,
                            selected: isBusiness,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    buildTypeCard(
                      type: 'individual',
                      title: 'Fizičko lice',
                      subtitle:
                          'Prodaja ličnih i polovnih stvari, sopstvene robe ili poljoprivrednih proizvoda bez registrovane delatnosti.',
                      icon: Icons.person_outline_rounded,
                      selected: !isBusiness,
                    ),
                    const SizedBox(height: 6),
                    buildTypeCard(
                      type: 'business',
                      title: 'Pravno lice / Trgovac',
                      subtitle:
                          'Preduzetnik, firma, registrovana radnja ili registrovano poljoprivredno gazdinstvo koje nastupa u okviru svoje delatnosti.',
                      icon: Icons.storefront_outlined,
                      selected: isBusiness,
                    ),
                  ],
                  if (_isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBusiness
                            ? const Color(0xFF2563EB)
                                .withValues(alpha: isDark ? 0.15 : 0.08)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBusiness
                              ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isBusiness
                                ? (isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF1D4ED8))
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isBusiness
                                  ? 'Kao registrovan trgovac / pravno lice, obavezni ste da poslujete u skladu sa Zakonom o zaštiti potrošača i obezbedite zakonska prava kupcima (pravo na jednostrani odustanak od ugovora na daljinu u roku od 14 dana, saobraznost robe, izdavanje računa).'
                                  : 'Na kupovinu od fizičkog lica ne primenjuju se odredbe Zakona o zaštiti potrošača o pravu na jednostrani odustanak od ugovora u roku od 14 dana.',
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.3,
                                color: isBusiness
                                    ? (isDark
                                        ? const Color(0xFFBFDBFE)
                                        : const Color(0xFF1E3A8A))
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Center(
                    child: Tooltip(
                      message: _isExpanded
                          ? 'Sakrij objašnjenje'
                          : 'Prikaži objašnjenje za fizičko i pravno lice',
                      child: InkWell(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded
                                    ? 'Sakrij objašnjenje'
                                    : 'Objašnjenje',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 17,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
