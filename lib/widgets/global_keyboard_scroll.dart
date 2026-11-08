import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Globalni omotač koji omogućava navigaciju tastaturom (PgUp, PgDn, Home, End)
/// na desktopu i webu, bez ometanja unosa teksta i tastera Space u formama.
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
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
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

  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    // Ako je fokusirano polje za unos teksta (npr. pretraga, forma), ne presrećemo navigaciju
    if (_isTextInputFocused()) {
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.pageUp) {
      return _performScroll(AxisDirection.up, ScrollIncrementType.page);
    }
    if (event.logicalKey == LogicalKeyboardKey.pageDown) {
      return _performScroll(AxisDirection.down, ScrollIncrementType.page);
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      return _performScroll(AxisDirection.up, ScrollIncrementType.page,
          isExtreme: true);
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      return _performScroll(AxisDirection.down, ScrollIncrementType.page,
          isExtreme: true);
    }

    return false;
  }

  bool _performScroll(
    AxisDirection direction,
    ScrollIncrementType type, {
    bool isExtreme = false,
  }) {
    if (!mounted) return false;
    if (_isTextInputFocused()) return false;

    final position = _findActiveScrollPosition();
    if (position == null) return false;

    _animateScroll(position, direction, type, isExtreme: isExtreme);
    return true;
  }

  ScrollPosition? _findActiveScrollPosition() {
    // 1. Ako je fokusirani kontekst unutar Scrollable widgeta, koristi njegovu poziciju
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext != null) {
      final scrollable = Scrollable.maybeOf(focusedContext);
      if (scrollable != null &&
          scrollable.position.hasPixels &&
          scrollable.position.maxScrollExtent > 0 &&
          (scrollable.axisDirection == AxisDirection.down ||
              scrollable.axisDirection == AxisDirection.up)) {
        return scrollable.position;
      }

      final descendantScroll = _findScrollableInSubtree(focusedContext);
      if (descendantScroll != null) {
        return descendantScroll;
      }
    }

    // 2. Ako PrimaryScrollController ima aktivne klijente
    final primary = PrimaryScrollController.maybeOf(context);
    if (primary != null && primary.hasClients) {
      for (final pos in primary.positions) {
        if (pos.hasPixels && pos.maxScrollExtent > 0) {
          return pos;
        }
      }
    }

    // 3. Pronađi aktivni vertikalni Scrollable u stablu
    return _findScrollableInSubtree(context);
  }

  ScrollPosition? _findScrollableInSubtree(BuildContext rootContext) {
    final List<ScrollPosition> candidates = <ScrollPosition>[];

    void visitor(Element element) {
      if (element.widget is Scrollable) {
        final dynamic state = (element as StatefulElement).state;
        if (state is ScrollableState) {
          if (state.axisDirection == AxisDirection.down ||
              state.axisDirection == AxisDirection.up) {
            if (state.position.hasPixels && state.position.maxScrollExtent > 0) {
              candidates.add(state.position);
            }
          }
        }
      }
      element.visitChildElements(visitor);
    }

    rootContext.visitChildElements(visitor);

    if (candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    // Ako ima više kandidata, prioritet dajemo najvećem vidljivom prozoru (glavni sadržaj),
    // a potom onom sa većim dometom skrolovanja.
    candidates.sort((a, b) {
      final viewportCompare = b.viewportDimension.compareTo(a.viewportDimension);
      if (viewportCompare != 0) return viewportCompare;
      return b.maxScrollExtent.compareTo(a.maxScrollExtent);
    });

    return candidates.first;
  }

  void _animateScroll(
    ScrollPosition position,
    AxisDirection direction,
    ScrollIncrementType type, {
    bool isExtreme = false,
  }) {
    if (!position.hasPixels) return;

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

    if ((target - position.pixels).abs() < 1.0) return;

    position.animateTo(
      target,
      duration: Duration(milliseconds: isExtreme ? 250 : 150),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
