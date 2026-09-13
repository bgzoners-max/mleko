import 'package:flutter/material.dart';
import '../../constants/amazon_theme.dart';

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
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? AmazonColors.darkCard
            : const Color(0xFFDFE3E3),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.0,
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
                      color: isClassifieds
                          ? AmazonColors.darkNavy
                          : (isDark ? const Color(0xFF232F3E) : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isClassifieds
                            ? AmazonColors.amber.withValues(alpha: 0.35)
                            : (isDark ? AmazonColors.darkBorder : AmazonColors.borderGray),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
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
                                  size: 18,
                                  color: isClassifieds
                                      ? AmazonColors.amber
                                      : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Mali Oglasi',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isClassifieds
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: isClassifieds
                                        ? Colors.white
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
                                  Icons.storefront_outlined,
                                  size: 18,
                                  color: !isClassifieds
                                      ? (isDark
                                          ? const Color(0xFF86EFAC)
                                          : const Color(0xFF166534))
                                      : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pijaca Hrane',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: !isClassifieds
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: !isClassifieds
                                        ? (isDark
                                            ? Colors.white
                                            : AmazonColors.textPrimary)
                                        : (isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary),
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
