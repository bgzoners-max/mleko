import 'package:flutter/material.dart';
import '../category_icon.dart';

class SearchCategoryPill extends StatefulWidget {
  final String label;
  final int? count;
  final String? icon;
  final bool selected;
  final bool fullWidth;
  final VoidCallback onTap;

  const SearchCategoryPill({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.fullWidth,
    required this.onTap,
  });

  @override
  State<SearchCategoryPill> createState() => _SearchCategoryPillState();
}

class _SearchCategoryPillState extends State<SearchCategoryPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1F5A3B);
    final selected = widget.selected;
    final hasCount = widget.count != null;
    final foregroundColor = selected ? Colors.white : const Color(0xFF244030);
    final backgroundColor = selected
        ? activeColor
        : (_hovered ? const Color(0xFFE6F0E9) : Colors.white);
    final borderColor = selected
        ? activeColor
        : (_hovered ? const Color(0xFF7FA489) : const Color(0xFFD6E1D9));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.fullWidth ? 14 : 16,
              vertical: widget.fullWidth ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: _hovered || selected
                  ? [
                      BoxShadow(
                        color: selected
                            ? activeColor.withValues(alpha: 0.24)
                            : const Color(0x1A244030),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                buildCategoryIcon(
                  widget.icon,
                  size: 18,
                  color: foregroundColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: widget.fullWidth ? 1 : 0,
                  child: Text(
                    hasCount
                        ? '${widget.label} (${widget.count})'
                        : widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
