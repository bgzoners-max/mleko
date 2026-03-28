import 'package:flutter/material.dart';

/// Semantics wrapper za InkWell/GestureDetector - za screen readers
class SemanticButton extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  const SemanticButton({
    required this.label,
    required this.child,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      child: child,
    );
  }
}

/// Template za tile sa semantic labelama
class SemanticListTile extends StatelessWidget {
  final String label;
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const SemanticListTile({
    required this.label,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(child: title),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
