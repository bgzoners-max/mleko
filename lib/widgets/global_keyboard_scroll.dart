import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Globalni omotač koji omogućava navigaciju tastaturom (PgUp, PgDn, Home, End, Space, Arrows)
/// na svim stranicama aplikacije, simulirajući standardno desktop/web iskustvo.
class GlobalKeyboardScroll extends StatefulWidget {
  final Widget child;

  const GlobalKeyboardScroll({super.key, required this.child});

  @override
  State<GlobalKeyboardScroll> createState() => _GlobalKeyboardScrollState();
}

class _GlobalKeyboardScrollState extends State<GlobalKeyboardScroll> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'GlobalKeyboardScrollFocus');

  @override
  void initState() {
    super.initState();
    // Umesto autofocus: true, zahtevamo fokus nakon što se frejm iscrta.
    // Ovo sprečava "RenderBox was not laid out" grešku tokom inicijalizacije.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Page Up / Down
        const SingleActivator(LogicalKeyboardKey.pageUp): () =>
            _handleScroll(context, AxisDirection.up, ScrollIncrementType.page),
        const SingleActivator(LogicalKeyboardKey.pageDown): () =>
            _handleScroll(context, AxisDirection.down, ScrollIncrementType.page),
        // Home / End
        const SingleActivator(LogicalKeyboardKey.home): () =>
            _handleScroll(context, AxisDirection.up, ScrollIncrementType.page,
                isExtreme: true),
        const SingleActivator(LogicalKeyboardKey.end): () =>
            _handleScroll(context, AxisDirection.down, ScrollIncrementType.page,
                isExtreme: true),
        // Space / Shift+Space (Web standard)
        const SingleActivator(LogicalKeyboardKey.space): () =>
            _handleScroll(context, AxisDirection.down, ScrollIncrementType.page),
        const SingleActivator(LogicalKeyboardKey.space, shift: true): () =>
            _handleScroll(context, AxisDirection.up, ScrollIncrementType.page),
        // Arrows (Fine scrolling)
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _handleScroll(context, AxisDirection.up, ScrollIncrementType.line),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _handleScroll(context, AxisDirection.down, ScrollIncrementType.line),
      },
      child: Focus(
        focusNode: _focusNode,
        child: widget.child,
      ),
    );
  }

  void _handleScroll(BuildContext context, AxisDirection direction,
      ScrollIncrementType type,
      {bool isExtreme = false}) {
    // Koristimo kontekst fokusiranog elementa ako postoji, jer je on bliži Scrollable-u
    final BuildContext effectiveContext = primaryFocus?.context ?? context;
    final ScrollController? primary =
        PrimaryScrollController.maybeOf(effectiveContext);

    if (primary != null && primary.hasClients) {
      for (final position in primary.positions) {
        double delta;
        if (isExtreme) {
          delta = direction == AxisDirection.down
              ? position.maxScrollExtent
              : -position.pixels;
        } else if (type == ScrollIncrementType.page) {
          delta = direction == AxisDirection.down
              ? position.viewportDimension * 0.8
              : -position.viewportDimension * 0.8;
        } else {
          // Line scroll - pomeramo za fiksnu vrednost
          delta = direction == AxisDirection.down ? 80.0 : -80.0;
        }

        final double target =
            (position.pixels + delta).clamp(0.0, position.maxScrollExtent);
        
        position.animateTo(
          target,
          duration: Duration(milliseconds: isExtreme ? 400 : 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }
}
