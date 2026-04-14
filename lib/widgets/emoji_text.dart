import 'package:flutter/material.dart';

const List<String> _emojiFontFallback = [
  'Noto Color Emoji',
  'Segoe UI Emoji',
  'Apple Color Emoji',
  'Segoe UI Symbol',
  'Noto Emoji',
];

TextStyle emojiTextStyle([TextStyle? baseStyle]) {
  final style = baseStyle ?? const TextStyle();
  final existing = style.fontFamilyFallback ?? const <String>[];
  return style.copyWith(
    fontFamilyFallback: [
      ...existing,
      ..._emojiFontFallback.where((font) => !existing.contains(font)),
    ],
  );
}

class EmojiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const EmojiText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: emojiTextStyle(style),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
