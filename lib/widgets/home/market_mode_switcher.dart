import 'package:flutter/material.dart';

enum MarketMode {
  classifieds,
  foodMarket,
}

class MarketModeSwitcher extends StatelessWidget {
  final MarketMode currentMode;
  final ValueChanged<MarketMode> onModeChanged;

  const MarketModeSwitcher({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = (constraints.maxWidth - 4) / 2;
          final isClassifieds = currentMode == MarketMode.classifieds;

          return Stack(
            children: [
              // 1. Pozadinski klizač - OBAVEZNO IgnorePointer da nikada ne blokira klikove!
              IgnorePointer(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  alignment: isClassifieds
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: tabWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? colorScheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Interaktivna dugmad - Positioned.fill za punu visinu i širinu
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onModeChanged(MarketMode.classifieds),
                          child: Container(
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 19,
                                  color: isClassifieds
                                      ? (isDark
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary)
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Svi Oglasi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isClassifieds
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isClassifieds
                                        ? (isDark
                                            ? colorScheme.onPrimary
                                            : colorScheme.primary)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onModeChanged(MarketMode.foodMarket),
                          child: Container(
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cottage_outlined,
                                  size: 19,
                                  color: !isClassifieds
                                      ? (isDark
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary)
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Pijaca Hrane',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: !isClassifieds
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: !isClassifieds
                                        ? (isDark
                                            ? colorScheme.onPrimary
                                            : colorScheme.primary)
                                        : colorScheme.onSurfaceVariant,
                                  ),
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
            ],
          );
        },
      ),
    );
  }
}
