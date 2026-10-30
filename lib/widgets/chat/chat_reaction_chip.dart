import 'package:flutter/material.dart';
import '../../core/design_system.dart';
import '../../models/message_reaction_model.dart';
import '../emoji_text.dart';

class ChatReactionChip extends StatelessWidget {
  final MessageReactionModel reaction;
  final VoidCallback onTap;

  const ChatReactionChip({super.key, required this.reaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: reaction.reactedByMe
              ? Theme.of(context).colorScheme.primaryContainer
              : (isDark ? AmazonColors.darkCard : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: reaction.reactedByMe
                ? Theme.of(context).colorScheme.primary
                : (isDark ? AmazonColors.darkBorder : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmojiText(reaction.reaction, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '${reaction.count}',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    reaction.reactedByMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
