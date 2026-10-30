import 'package:flutter/material.dart';
import '../../core/design_system.dart';

class ChatDateSeparator extends StatelessWidget {
  final DateTime date;
  const ChatDateSeparator({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AmazonColors.darkCard : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: isDark
                ? Border.all(color: AmazonColors.darkBorder, width: 1)
                : null,
          ),
          child: Text(
            '${date.day}.${date.month}.${date.year}.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AmazonColors.darkTextSecondary
                  : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
