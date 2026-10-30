import 'package:flutter/material.dart';
import '../../../core/design_system.dart' show AmazonColors;
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_design.dart';

class ClassifiedDescriptionCard extends StatelessWidget {
  final ClassifiedAdModel ad;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const ClassifiedDescriptionCard({
    super.key,
    required this.ad,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
  });

  List<InlineSpan> _parseFormattedDescription(String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
    int lastMatchEnd = 0;

    for (final Match m in exp.allMatches(text)) {
      if (m.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, m.start),
          style: baseStyle,
        ));
      }
      final rawMatch = m.group(0)!;
      if (rawMatch.startsWith('**') &&
          rawMatch.endsWith('**') &&
          rawMatch.length >= 4) {
        spans.add(TextSpan(
          text: rawMatch.substring(2, rawMatch.length - 2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (rawMatch.startsWith('*') &&
          rawMatch.endsWith('*') &&
          rawMatch.length >= 2) {
        spans.add(TextSpan(
          text: rawMatch.substring(1, rawMatch.length - 1),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      lastMatchEnd = m.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = theme.textTheme.bodyMedium?.copyWith(
          height: 1.55,
          fontSize: 14.5,
          color: colorScheme.onSurface,
        ) ??
        TextStyle(
          height: 1.55,
          fontSize: 14.5,
          color: colorScheme.onSurface,
        );

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Detaljan opis',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText.rich(
            TextSpan(
              children: ad.description.isEmpty
                  ? [
                      TextSpan(
                        text:
                            'Prodavac nije uneo detaljan opis za ovaj oglas.',
                        style: defaultStyle.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    ]
                  : _parseFormattedDescription(ad.description, defaultStyle),
            ),
          ),
        ],
      ),
    );
  }
}
