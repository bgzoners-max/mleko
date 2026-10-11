import 'package:flutter/material.dart';
import '../../core/design_system.dart';

/// Pojedinačni tab u desktop navigaciji sa hover efektom i aktivnim indikatorom.
class DesktopNavTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const DesktopNavTab({
    super.key,
    required this.label,
    required this.icon,
    required this.isActive,
    this.badge,
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

    final activeColor = isDark ? AmazonColors.lightGreen : AmazonColors.green;
    final inactiveColor = isDark ? Colors.white70 : AmazonColors.darkNavy;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive
                ? (isDark ? const Color(0xFF1B2F21) : const Color(0xFFE8F5E9))
                : (_isHovered
                    ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F2))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive
                  ? (isDark ? const Color(0xFF2E633B) : const Color(0xFFC8E6C9))
                  : Colors.transparent,
              width: 1,
            ),
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
