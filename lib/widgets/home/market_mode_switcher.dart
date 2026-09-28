import 'package:flutter/material.dart';
import '../../core/haptic.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClassifieds = currentMode == MarketMode.classifieds;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18221B) : const Color(0xFFEFF4EF),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3E32) : const Color(0xFFD6E0D6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _MarketSegmentPill(
                isSelected: isClassifieds,
                isClassifieds: true,
                icon: Icons.campaign_rounded,
                title: 'Mali Oglasi',
                onTap: () => onModeChanged(MarketMode.classifieds),
              ),
            ),
            Expanded(
              child: _MarketSegmentPill(
                isSelected: !isClassifieds,
                isClassifieds: false,
                icon: Icons.storefront_rounded,
                title: 'Pijaca Hrane',
                onTap: () => onModeChanged(MarketMode.foodMarket),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketSegmentPill extends StatefulWidget {
  final bool isSelected;
  final bool isClassifieds;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MarketSegmentPill({
    required this.isSelected,
    required this.isClassifieds,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<_MarketSegmentPill> createState() => _MarketSegmentPillState();
}

class _MarketSegmentPillState extends State<_MarketSegmentPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.isSelected;
    final isClassifieds = widget.isClassifieds;

    final Color backgroundColor;
    final Color textColor;
    final Color iconColor;
    final List<BoxShadow> shadows;
    final Border? border;

    if (isSelected) {
      if (isClassifieds) {
        backgroundColor = isDark ? const Color(0xFF382312) : Colors.white;
        textColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFC45500);
        iconColor = isDark ? const Color(0xFFFFA726) : const Color(0xFFE65100);
        border = Border.all(
          color: isDark ? const Color(0xFFFF9800) : const Color(0xFFFFB74D),
          width: 1.2,
        );
        shadows = [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.30 : 0.18),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ];
      } else {
        backgroundColor = isDark ? const Color(0xFF193220) : Colors.white;
        textColor = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20);
        iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        border = Border.all(
          color: isDark ? const Color(0xFF4CAF50) : const Color(0xFFA5D6A7),
          width: 1.2,
        );
        shadows = [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: isDark ? 0.30 : 0.18),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ];
      }
    } else {
      backgroundColor = _isHovered
          ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04))
          : Colors.transparent;
      textColor = _isHovered
          ? (isDark ? Colors.white : const Color(0xFF1F2937))
          : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151));
      iconColor = isClassifieds
          ? (isDark
              ? const Color(0xFFFFB74D).withValues(alpha: 0.85)
              : const Color(0xFFE65100).withValues(alpha: 0.8))
          : (isDark
              ? const Color(0xFF81C784).withValues(alpha: 0.85)
              : const Color(0xFF2E7D32).withValues(alpha: 0.8));
      border = null;
      shadows = const [];
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minHeight: (42.0 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35)).roundToDouble(),
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: border,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              AppHaptics.selection();
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.15,
                        color: textColor,
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
