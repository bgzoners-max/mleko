import 'package:flutter/material.dart';

/// Autenticni organski Nature bedz za verifikovana domaca gazdinstva i proizvodjace.
///
/// Koristi prirodni amblem (podrazumevano prepoznatljivi '🌿' herb/list)
/// uokviren svezim prirodnim ivicama i mekom zelenom aurom.
/// Izbegava ShaderMask bagove u CanvasKit/WebGL-u i garantuje ostar i cist
/// prikaz na svim telefonima, tabletima i racunarima.
class VerifiedBadge extends StatelessWidget {
  final String? text;
  final String emoji;
  final IconData? icon;
  final String? tooltip;
  final bool compact;
  final double? size;
  final VoidCallback? onTap;

  const VerifiedBadge({
    super.key,
    this.text,
    this.emoji = '🌿',
    this.icon,
    this.tooltip,
    this.compact = false,
    this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = text != null && text!.trim().isNotEmpty;
    final isCompact = compact;
    final effectiveSize = size ?? (isCompact ? 24.0 : 28.0);
    final borderRadiusVal = hasText
        ? (isCompact ? 9.0 : 12.0)
        : (effectiveSize * 0.30).clamp(6.0, 12.0);
    final emojiSize = (effectiveSize * 0.60).clamp(13.0, 22.0);
    final iconSize = (effectiveSize * 0.58).clamp(12.0, 20.0);

    // Boje prilagodjene temi: svetla dewy rosa ili tamna sumska pozadina
    final bgColor = isDark ? const Color(0xFF16381C) : const Color(0xFFE8F5E9);
    final borderColor =
        isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784);
    final textColor =
        isDark ? const Color(0xFFC8E6C9) : const Color(0xFF1B5E20);

    Widget innerBadge;
    if (icon != null) {
      innerBadge = Icon(
        icon,
        color: textColor,
        size: iconSize,
      );
    } else {
      innerBadge = Text(
        emoji,
        style: TextStyle(
          fontSize: emojiSize,
          height: 1.0,
        ),
      );
    }

    Widget content;
    if (hasText) {
      content = Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadiusVal),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32)
                  .withValues(alpha: isCompact ? 0.12 : 0.18),
              blurRadius: 4.0,
              offset: const Offset(0, 1.0),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7.0 : 10.0,
          vertical: isCompact ? 2.5 : 4.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            innerBadge,
            SizedBox(width: isCompact ? 4.0 : 6.0),
            Flexible(
              child: Text(
                text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 10.5 : 12.0,
                  letterSpacing: 0.2,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Container(
        width: effectiveSize,
        height: effectiveSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadiusVal),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32)
                  .withValues(alpha: isCompact ? 0.14 : 0.22),
              blurRadius: isCompact ? 4.0 : 6.0,
              offset: const Offset(0, 1.0),
            ),
          ],
        ),
        child: innerBadge,
      );
    }

    Widget result = content;

    if (tooltip != null && tooltip!.isNotEmpty) {
      result = Tooltip(
        message: tooltip!,
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        child: result,
      );
    }

    if (onTap != null) {
      result = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        child: result,
      );
    }

    return result;
  }
}
