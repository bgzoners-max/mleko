import 'package:flutter/material.dart';

import '../../constants/amazon_theme.dart';

class ProductDescription extends StatelessWidget {
  final String description;

  const ProductDescription({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor =
        isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
        const SizedBox(height: 12),
        Text(
          'Opis proizvoda',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: headerColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: isDark ? Colors.grey.shade300 : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
