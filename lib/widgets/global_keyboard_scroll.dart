import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Globalni omotač koji omogućava navigaciju tastaturom (PgUp, PgDn, Home, End)
/// na stranicama aplikacije, bez ometanja unosa teksta i tastera Space.
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

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final context = focus.context;
    if (context == null) return false;
    return context.widget is EditableText ||
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        // AKO JE FOKUSIRANO BILO KOJE TEKSTUALNO POLJE -> NIKADA NE PRESREĆI TASTERE
        if (_isTextInputFocused()) {
          return KeyEventResult.ignored;
        }

        // Space NIKADA ne vezujemo ovde jer ometa kucanje u formama.
        // Skrolovanje tastaturom dozvoljavamo samo za eksplicitne navigacione tastere:
        if (event.logicalKey == LogicalKeyboardKey.pageUp) {
          _handleScroll(context, AxisDirection.up, ScrollIncrementType.page);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.pageDown) {
          _handleScroll(context, AxisDirection.down, ScrollIncrementType.page);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.home) {
          _handleScroll(context, AxisDirection.up, ScrollIncrementType.page,
              isExtreme: true);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.end) {
          _handleScroll(context, AxisDirection.down, ScrollIncrementType.page,
              isExtreme: true);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  void _handleScroll(BuildContext context, AxisDirection direction,
      ScrollIncrementType type,
      {bool isExtreme = false}) {
    if (_isTextInputFocused()) return;

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

