import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// Pojedinačni tab u desktop navigaciji sa hover efektom i aktivnim indikatorom.
class DesktopNavTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? badge;
  final bool isCapsule;
  final VoidCallback onTap;

  const DesktopNavTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    this.badge,
    this.isCapsule = false,
    required this.onTap,
  });

  @override
  State<DesktopNavTab> createState() => _DesktopNavTabState();
}

class _DesktopNavTabState extends State<DesktopNavTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCapsule = widget.isCapsule;

    final Color activeColor;
    final Color inactiveColor;
    final Color bgColor;
    final Border border;
    final List<BoxShadow> shadows;

    if (isCapsule) {
      activeColor = isDark ? AmazonColors.lightGreen : const Color(0xFF15803D);
      inactiveColor = isDark ? Colors.white70 : const Color(0xFF2C3E30);

      if (widget.isActive) {
        bgColor = isDark ? const Color(0xFF1F3F27) : Colors.white;
        border = Border.all(
          color: isDark ? const Color(0xFF387547) : const Color(0xFFB7DFBC),
          width: 1.0,
        );
        shadows = [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0x1815803D),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ];
      } else {
        bgColor = _isHovered
            ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65))
            : Colors.transparent;
        border = Border.all(color: Colors.transparent, width: 1.0);
        shadows = const [];
      }
    } else {
      activeColor = isDark ? AmazonColors.lightGreen : AmazonColors.green;
      inactiveColor = isDark ? Colors.white70 : AmazonColors.darkNavy;

      if (widget.isActive) {
        bgColor = isDark ? const Color(0xFF1B2F21) : const Color(0xFFE8F5E9);
        border = Border.all(
          color: isDark ? const Color(0xFF2E633B) : const Color(0xFFC8E6C9),
          width: 1.0,
        );
      } else {
        bgColor = _isHovered
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F2))
            : Colors.transparent;
        border = Border.all(color: Colors.transparent, width: 1.0);
      }
      shadows = const [];
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isCapsule ? 10 : 9,
            vertical: isCapsule ? 5.5 : 6,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(isCapsule ? 7 : 8),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
              ),
              if (widget.badge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isDark ? AmazonColors.darkAmberCta : AmazonColors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      color: AmazonColors.darkNavy,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
