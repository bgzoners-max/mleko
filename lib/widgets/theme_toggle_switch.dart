import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/haptic.dart';
import '../providers/app_settings_provider.dart';

/// Prekidač (toggle) za promenu svetle/tamne teme sa glatkom animacijom
/// i taktilnim odzivom.
class ThemeToggleSwitch extends StatelessWidget {
  final bool isIconOnly;

  const ThemeToggleSwitch({super.key, this.isIconOnly = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final isDark = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final tooltipText =
        isDark ? 'Prebaci na svetlu temu' : 'Prebaci na tamnu temu';

    if (isIconOnly) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: anim,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
            key: ValueKey<bool>(isDark),
            size: 22,
            color: isDark ? Colors.amber.shade400 : Colors.grey.shade800,
          ),
        ),
        tooltip: tooltipText,
        onPressed: () {
          AppHaptics.light();
          settings.toggleTheme(context);
        },
      );
    }

    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        toggled: isDark,
        label: tooltipText,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            AppHaptics.light();
            settings.toggleTheme(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pozadinske ikonice na stazi prekidača
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          size: 13,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.amber.shade700,
                        ),
                        Icon(
                          Icons.nightlight_round,
                          size: 13,
                          color: isDark
                              ? Colors.indigo.shade200
                              : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),

                  // Klizno dugme (Thumb)
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOutCubic,
                    alignment:
                        isDark ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 3,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isDark
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 12,
                          color: isDark
                              ? Colors.amber.shade300
                              : Colors.amber.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
