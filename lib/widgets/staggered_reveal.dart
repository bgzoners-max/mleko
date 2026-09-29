import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_settings_provider.dart';

/// Ulazna animacija sa kašnjenjem po indeksu — mreža kartica "diše" (blagi
/// fade + slide-up u kaskadi), umesto da se pojavi kao statičan zid.
///
/// Poštuje korisničko podešavanje "Animacije": kada su isključene, sadržaj se
/// prikazuje odmah (bez ikakvih tajmera ili animacija).
class StaggeredReveal extends StatefulWidget {
  /// Redni broj elementa u listi (određuje kašnjenje).
  final int index;

  final Widget child;

  /// Korak kašnjenja po indeksu.
  final Duration step;

  /// Trajanje same animacije.
  final Duration duration;

  const StaggeredReveal({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return; // pokreni tačno jednom
    _started = true;

    // Nullable lookup: bezbedno i van punog app stabla (npr. izolovani testovi).
    final enabled =
        context.read<AppSettingsProvider?>()?.animationsEnabled ?? false;
    if (!enabled) {
      _controller.value = 1;
      return;
    }

    // Kasniji elementi ne smeju predugo da čekaju (cap na 6 koraka).
    final steps = widget.index > 6 ? 6 : widget.index;
    final delay = widget.step * steps;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
