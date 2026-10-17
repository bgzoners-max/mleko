import 'package:flutter/material.dart';

/// Kanonska lista predloženih oznaka za gazdinstva/prodavce.
const kEditProfileSellerTags = [
  'Bio sertifikat',
  'Direktna dostava',
  'Preuzimanje na licu mesta',
  'Plaćanje gotovinom',
  'Plaćanje karticom',
  'PDV obveznik',
  'Organski uzgoj',
  'Sezonski',
];

/// Sekcija „Oznake gazdinstva / prodavca" — FilterChip izbor oznaka.
///
/// Izdvojena iz EditProfileForm radi održavanja fajla ispod limita od
/// 700 linija (tool/check_file_size.dart). Lista [selectedTags] se
/// mutira na mestu pozivaoca preko [onSelectionChanged].
class EditProfileSellerTagsSection extends StatelessWidget {
  final List<String> selectedTags;
  final void Function(List<String> tags) onSelectionChanged;

  const EditProfileSellerTagsSection({
    super.key,
    required this.selectedTags,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Oznake gazdinstva / prodavca',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kEditProfileSellerTags
              .map((tag) => FilterChip(
                    label:
                        Text(tag, style: const TextStyle(fontSize: 13)),
                    selected: selectedTags.contains(tag),
                    onSelected: (v) {
                      final next = List<String>.from(selectedTags);
                      if (v) {
                        next.add(tag);
                      } else {
                        next.remove(tag);
                      }
                      onSelectionChanged(next);
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}
