import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';

/// Dugme koje pri tapu reprodukuje blagu bounce (scale) animaciju i haptic,
/// zatim poziva [onPressed]. Poštuje podešavanje "Animacije" (isključeno = bez animacije).
class BounceTapButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget Function(VoidCallback onPressed) builder;

  const BounceTapButton({
    super.key,
    required this.onPressed,
    required this.builder,
  });

  @override
  State<BounceTapButton> createState() => _BounceTapButtonState();
}

class _BounceTapButtonState extends State<BounceTapButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(BuildContext context) {
    if (widget.onPressed == null || _controller.isAnimating) return;
    final animationsEnabled = context.read<AppSettingsProvider>().animationsEnabled;
    HapticFeedback.lightImpact();
    if (animationsEnabled) {
      _controller.forward(from: 0).then((_) {
        if (mounted) widget.onPressed?.call();
      });
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = context.watch<AppSettingsProvider>().animationsEnabled;
    if (!animationsEnabled) {
      return widget.builder(() => _handleTap(context));
    }
    return ScaleTransition(
      scale: _scale,
      child: _controller.isAnimating
          ? IgnorePointer(child: widget.builder(() => _handleTap(context)))
          : widget.builder(() => _handleTap(context)),
    );
  }
}
