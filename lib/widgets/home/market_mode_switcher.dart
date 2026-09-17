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
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2620) : const Color(0xFFEDF2ED),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3A30) : const Color(0xFFDEE5DE),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: _MarketSegmentPill(
                isSelected: isClassifieds,
                icon: Icons.campaign_rounded,
                title: 'Mali Oglasi',
                onTap: () => onModeChanged(MarketMode.classifieds),
              ),
            ),
            Expanded(
              child: _MarketSegmentPill(
                isSelected: !isClassifieds,
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
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MarketSegmentPill({
    required this.isSelected,
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

    final Color backgroundColor;
    final Color textColor;
    final Color iconColor;
    final List<BoxShadow> shadows;
    final Border? border;

    if (isSelected) {
      backgroundColor = isDark ? const Color(0xFF2C392E) : Colors.white;
      textColor = isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);
      iconColor = isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);
      border = Border.all(
        color: isDark ? const Color(0xFF3E4E40) : const Color(0xFFE2E9E2),
        width: 0.8,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.07),
          blurRadius: 5,
          offset: const Offset(0, 1.5),
        ),
      ];
    } else {
      backgroundColor = _isHovered
          ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.035))
          : Colors.transparent;
      textColor = _isHovered
          ? (isDark ? Colors.white : const Color(0xFF2B3A2C))
          : (isDark ? const Color(0xFFA0ABA0) : const Color(0xFF5F6E5F));
      iconColor = textColor;
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
        height: 36,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: border,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              AppHaptics.selection();
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: iconColor,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
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
