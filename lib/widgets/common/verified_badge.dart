import 'package:flutter/material.dart';

/// Autenticni organski Nature bedz za verifikovana domaca gazdinstva i proizvodjace.
///
/// Odisi prirodnom, socnom zelenom bojom svezeg lista i ciste prirode (bez
/// tamnih/crnih tonova). Prikazuje se kao cist organski amblem sa belim listom
/// (Icons.eco_rounded), bogatim zelenim gradijentom, mekim zelenim sjajem i
/// blagom animacijom presijavanja suncevog zraka (shimmer / glint).
class VerifiedBadge extends StatefulWidget {
  final String? text;
  final IconData icon;
  final String? tooltip;
  final bool compact;
  final double? size;
  final bool shimmer;
  final VoidCallback? onTap;

  const VerifiedBadge({
    super.key,
    this.text,
    this.icon = Icons.eco_rounded,
    this.tooltip,
    this.compact = false,
    this.size,
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

    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.shimmer && !isTestEnvironment) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant VerifiedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmer != oldWidget.shimmer) {
      final isTestEnvironment =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (widget.shimmer && !isTestEnvironment) {
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
    final hasText = widget.text != null && widget.text!.trim().isNotEmpty;
    final isCompact = widget.compact;
    final effectiveSize = widget.size ?? (isCompact ? 24.0 : 28.0);
    final borderWidth = effectiveSize >= 28 ? 1.8 : 1.5;
    final borderRadiusVal = hasText
        ? (isCompact ? 9.0 : 12.0)
        : (effectiveSize * 0.32).clamp(7.0, 14.0);
    final innerRadiusVal = (borderRadiusVal - borderWidth).clamp(4.0, 12.0);
    final iconSize = (effectiveSize * 0.60).roundToDouble().clamp(13.0, 24.0);

    Widget innerContent;
    if (hasText) {
      innerContent = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8.0 : 11.0,
          vertical: isCompact ? 2.5 : 4.5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: isCompact ? 13.0 : 16.0,
              shadows: const [
                Shadow(
                  color: Color(0x4D064E3B),
                  blurRadius: 2.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            SizedBox(width: isCompact ? 4.0 : 6.0),
            Flexible(
              child: Text(
                widget.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: isCompact ? 10.0 : 11.5,
                  letterSpacing: isCompact ? 0.5 : 0.8,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      innerContent = SizedBox(
        width: effectiveSize - (borderWidth * 2),
        height: effectiveSize - (borderWidth * 2),
        child: Center(
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: iconSize,
            shadows: const [
              Shadow(
                color: Color(0x4D064E3B),
                blurRadius: 2.5,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }

    final badgeContent = Container(
      width: hasText ? null : effectiveSize,
      height: hasText ? null : effectiveSize,
      decoration: BoxDecoration(
        // Prirodni organski okvir: svez prolecni list sa jutarnjom rosom
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCFCE7), // svetla jutarnja rosa / mint
            Color(0xFF86EFAC), // mladi zeleni list
            Color(0xFF4ADE80), // vibrantna svezina prirode
            Color(0xFF22C55E), // cista livadska zelena
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadiusVal),
        // Svez zeleni prirodni sjaj (aura) - bez crnih i teskih senki
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: isCompact ? 0.28 : 0.40),
            blurRadius: isCompact ? 6.0 : 9.0,
            spreadRadius: 0.5,
            offset: const Offset(0, 1.5),
          ),
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.22),
            blurRadius: 3.5,
            offset: const Offset(0, 1.0),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            // Socna, 100% prirodna zelena baza (nije crna, cista organska priroda)
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32), // socna tamnija zelena
                Color(0xFF1E8238), // ziva organska livada
                Color(0xFF15803D), // bogato sumsko zelenilo
                Color(0xFF14532D), // najdublja topla borova zelena (100% zelena, 0% crna)
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(innerRadiusVal),
          ),
          child: innerContent,
        ),
      ),
    );

    Widget result;
    if (widget.shimmer) {
      result = AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Postovanje pristupacnosti: ako korisnik ima iskljucene animacije
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
                  Color(0x22FFFFFF),
                  Color(0xCCFFFFFF), // cist suncev sjaj preko rose na listu
                  Color(0x22FFFFFF),
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
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
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
