import 'package:flutter/material.dart';

class ClassifiedDescriptionField extends StatefulWidget {
  final TextEditingController controller;

  const ClassifiedDescriptionField({super.key, required this.controller});

  @override
  State<ClassifiedDescriptionField> createState() =>
      _ClassifiedDescriptionFieldState();
}

class _ClassifiedDescriptionFieldState
    extends State<ClassifiedDescriptionField> {
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  bool _isApplyingUndoRedo = false;

  @override
  void initState() {
    super.initState();
    _undoStack.add(widget.controller.value);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ClassifiedDescriptionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      _undoStack.clear();
      _redoStack.clear();
      _undoStack.add(widget.controller.value);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_isApplyingUndoRedo) return;
    final current = widget.controller.value;
    if (_undoStack.isEmpty || _undoStack.last.text != current.text) {
      _undoStack.add(current);
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
      if (_redoStack.isNotEmpty) {
        _redoStack.clear();
      }
      setState(() {});
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isApplyingUndoRedo = true;
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final previous = _undoStack.last;
      widget.controller.value = previous;
      _isApplyingUndoRedo = false;
      setState(() {});
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isApplyingUndoRedo = true;
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      widget.controller.value = next;
      _isApplyingUndoRedo = false;
      setState(() {});
    }
  }

  void _applyFormat(String marker, {String placeholder = 'tekst'}) {
    final val = widget.controller.value;
    final text = val.text;
    final selection = val.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final start = selection.isValid ? selection.start : text.length;
      final insertText = '$marker$placeholder$marker';
      final newText = text.replaceRange(start, start, insertText);
      final selectStart = start + marker.length;
      final selectEnd = selectStart + placeholder.length;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: selectStart, extentOffset: selectEnd),
      );
    } else {
      final start = selection.start;
      final end = selection.end;
      final selectedText = text.substring(start, end);
      final markerLen = marker.length;

      // Toggle unwrap if already wrapped
      if (selectedText.startsWith(marker) &&
          selectedText.endsWith(marker) &&
          selectedText.length >= markerLen * 2) {
        final unwrapped =
            selectedText.substring(markerLen, selectedText.length - markerLen);
        final newText = text.replaceRange(start, end, unwrapped);
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + unwrapped.length,
          ),
        );
      } else {
        final wrapped = '$marker$selectedText$marker';
        final newText = text.replaceRange(start, end, wrapped);
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + wrapped.length,
          ),
        );
      }
    }
  }

  void _applyListPrefix(bool isNumbered) {
    final val = widget.controller.value;
    final text = val.text;
    final selection = val.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    if (!selection.isValid || selection.isCollapsed) {
      final prefix = isNumbered ? '1. ' : '• ';
      final needsNewline = start > 0 && text[start - 1] != '\n';
      final insertText = '${needsNewline ? '\n' : ''}$prefix';
      final newText = text.replaceRange(start, start, insertText);
      final newCursor = start + insertText.length;
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      final selectedText = text.substring(start, end);
      final lines = selectedText.split('\n');
      final formatted = <String>[];
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) {
          formatted.add(line);
        } else {
          final prefix = isNumbered ? '${i + 1}. ' : '• ';
          if (line.startsWith(prefix)) {
            formatted.add(line.substring(prefix.length));
          } else {
            formatted.add('$prefix$line');
          }
        }
      }
      final replacement = formatted.join('\n');
      final newText = text.replaceRange(start, end, replacement);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + replacement.length,
        ),
      );
    }
  }

  Widget _buildToolbarButton({
    required Widget child,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 30,
          alignment: Alignment.center,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.35,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final canUndo = _undoStack.length > 1;
    final canRedo = _redoStack.isNotEmpty;
    final primaryIconColor = isDark ? colorScheme.primary : const Color(0xFF1E3A8A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 15,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'Detaljan opis proizvoda',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Toolbar kontejner za bold, italic, undo/redo, liste ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(9)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _buildToolbarButton(
                      tooltip: 'Podebljano (Bold)',
                      onPressed: () => _applyFormat('**'),
                      child: Text(
                        'B',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: primaryIconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      tooltip: 'Iskošeno (Italic)',
                      onPressed: () => _applyFormat('*'),
                      child: Text(
                        'I',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: primaryIconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      tooltip: 'Poništi (Undo)',
                      onPressed: canUndo ? _undo : null,
                      child: Icon(
                        Icons.undo_rounded,
                        size: 18,
                        color: canUndo
                            ? primaryIconColor
                            : (isDark ? Colors.white30 : Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      tooltip: 'Ponovi (Redo)',
                      onPressed: canRedo ? _redo : null,
                      child: Icon(
                        Icons.redo_rounded,
                        size: 18,
                        color: canRedo
                            ? primaryIconColor
                            : (isDark ? Colors.white30 : Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      height: 16,
                      width: 1,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    const SizedBox(width: 6),
                    _buildToolbarButton(
                      tooltip: 'Numerisana lista',
                      onPressed: () => _applyListPrefix(true),
                      child: Icon(
                        Icons.format_list_numbered_rounded,
                        size: 19,
                        color: primaryIconColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildToolbarButton(
                      tooltip: 'Lista sa tačkama',
                      onPressed: () => _applyListPrefix(false),
                      child: Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 19,
                        color: primaryIconColor,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Multiline polje za unos opisa ──
              TextFormField(
                controller: widget.controller,
                minLines: 4,
                maxLines: 7,
                maxLength: 2000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Opišite stanje, karakteristike, razlog prodaje, zamene itd.',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
