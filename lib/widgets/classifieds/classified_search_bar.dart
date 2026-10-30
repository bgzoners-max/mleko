import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../providers/classifieds_provider.dart';

class ClassifiedSearchBar extends StatelessWidget {
  final ClassifiedsProvider classifieds;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const ClassifiedSearchBar({
    super.key,
    required this.classifieds,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AmazonColors.darkCard : AmazonColors.cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AmazonColors.darkBorder : AmazonColors.borderGray,
          width: 1.2,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search,
            size: 20,
            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                final q = val.trim().isEmpty ? null : val.trim();
                classifieds.search(q);
              },
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Pretraži male oglase (traktori, mehanizacija, alati, tehnika...)',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 16),
              color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                searchController.clear();
                onSearchChanged('');
              },
            ),
          InkWell(
            onTap: () {
              final q = searchController.text.trim();
              classifieds.search(q.isEmpty ? null : q);
            },
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: Container(
              width: 44,
              height: 42,
              decoration: const BoxDecoration(
                color: AmazonColors.amberLight,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.search,
                  size: 20,
                  color: AmazonColors.darkNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
