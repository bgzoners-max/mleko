import 'package:flutter/material.dart';

/// Prestižni LoL/Hextech-inspirisani bedž za verifikovana gazdinstva i proizvođače.
///
/// Koristi dvostruki Container sa zlatnim gradijentnim okvirom, smaragdnom
/// bazom i suptilnom periodičnom animacijom presijavanja (shimmer / glint).
class VerifiedBadge extends StatefulWidget {
  final String text;
  final IconData icon;
  final String? tooltip;
  final bool compact;
  final bool shimmer;
  final VoidCallback? onTap;

  const VerifiedBadge({
    super.key,
    this.text = 'VERIFIKOVANO GAZDINSTVO',
    this.icon = Icons.workspace_premium_rounded,
    this.tooltip,
    this.compact = false,
    this.shimmer = true,
    this.onTap,
  });

  @override
  State<VerifiedBadge> createState() => _VerifiedBadgeState();
}

class _VerifiedBadgeState extends State<VerifiedBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // Presijavanje traje prvih ~35% ciklusa (oko 1.1s), a preostalih 65% je pauza.
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
    );

    if (widget.shimmer) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VerifiedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer != oldWidget.shimmer) {
      if (widget.shimmer) {
        _controller.repeat();
      } else {
        _controller
          ..stop()
          ..reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = widget.compact;
    final borderRadiusVal = isCompact ? 9.0 : 12.0;
    final innerRadiusVal = isCompact ? 7.5 : 10.0;
    final borderWidth = isCompact ? 1.4 : 1.8;

    final badgeContent = Container(
      decoration: BoxDecoration(
        // Zlatni gradijent za metalik okvir
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF59E0B),
            Color(0xFFFDE68A),
            Color(0xFFD97706),
            Color(0xFFB45309),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadiusVal),
        // Zlatni sjaj (glow efekat)
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: isCompact ? 0.25 : 0.35),
            blurRadius: isCompact ? 5.0 : 8.0,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            // Duboka smaragdno-zelena baza (Hextech Emerald)
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF0F3D17),
                Color(0xFF08260E),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(innerRadiusVal),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8.0 : 11.0,
            vertical: isCompact ? 2.5 : 4.5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: const Color(0xFFFDE68A),
                size: isCompact ? 13.0 : 16.0,
              ),
              SizedBox(width: isCompact ? 4.0 : 6.0),
              Flexible(
                child: Text(
                  widget.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFFDE68A),
                    fontWeight: FontWeight.w800,
                    fontSize: isCompact ? 10.0 : 11.5,
                    letterSpacing: isCompact ? 0.6 : 0.9,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget result;
    if (widget.shimmer) {
      result = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Poštovanje pristupačnosti: ako korisnik ima isključene animacije
          if (MediaQuery.of(context).disableAnimations) {
            return child!;
          }

          final progress = _animation.value;
          // Tokom pauze (progress == 1.0) nema shader preslikavanja
          if (_controller.value > 0.35) {
            return child!;
          }

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-2.5 + (progress * 5.0), -1.0),
                end: Alignment(-1.5 + (progress * 5.0), 1.0),
                colors: const [
                  Colors.transparent,
                  Color(0x33FFFFFF),
                  Color(0x99FFF9C4), // topao zlatno-beli zrak
                  Color(0x33FFFFFF),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: badgeContent,
      );
    } else {
      result = badgeContent;
    }

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      result = Tooltip(
        message: widget.tooltip!,
        child: result,
      );
    }

    if (widget.onTap != null) {
      result = InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        child: result,
      );
    }

    return result;
  }
}
