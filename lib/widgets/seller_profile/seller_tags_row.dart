import 'package:flutter/material.dart';

class SellerTagsRow extends StatelessWidget {
  final List<String> tags;
  const SellerTagsRow({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    final normalized =
        tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    const trustLabels = [
      'Provereno gazdinstvo',
      'Redovna isporuka',
      'Dostava u vaš grad',
    ];
    final trustTags = <String>[];
    final otherTags = <String>[];

    for (final t in normalized) {
      if (trustLabels.any((lbl) => lbl.toLowerCase() == t.toLowerCase())) {
        trustTags.add(t);
      } else {
        otherTags.add(t);
      }
    }

    if (normalized.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    if (trustTags.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: trustTags.map((t) {
              IconData icon;
              Color color;
              String tooltip;
              final lower = t.toLowerCase();
              if (lower == 'provereno gazdinstvo') {
                icon = Icons.verified;
                color = Colors.green.shade700;
                tooltip = 'Gazdinstvo je provereno od strane platforme.';
              } else if (lower == 'redovna isporuka') {
                icon = Icons.autorenew;
                color = Colors.blue.shade700;
                tooltip = 'Prodavac redovno isporučuje porudžbine na vreme.';
              } else {
                icon = Icons.local_shipping_outlined;
                color = Colors.orange.shade800;
                tooltip =
                    'Prodavac organizuje dostavu u vaš grad (ili dogovorom).';
              }
              return Tooltip(
                message: tooltip,
                child: Chip(
                  avatar: Icon(icon, size: 16, color: Colors.white),
                  label: Text(
                    t,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  backgroundColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }

    if (otherTags.isNotEmpty) {
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, trustTags.isNotEmpty ? 8 : 0, 16, 0),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: otherTags
                .map((t) => Chip(
                      avatar: const Icon(Icons.label_outline, size: 14),
                      label: Text(t, style: const TextStyle(fontSize: 12)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
