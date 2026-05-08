import 'dart:math' show min;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/message_model.dart';
import '../../models/message_reaction_model.dart';
import 'chat_reaction_chip.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final List<MessageReactionModel> reactions;
  final void Function(Offset? tapPosition) onShowMenu;
  final void Function(String emoji) onToggleReaction;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.reactions,
    required this.onShowMenu,
    required this.onToggleReaction,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month}.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onSecondaryTapUp: (details) => onShowMenu(details.globalPosition),
            onLongPress: () => onShowMenu(null),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: min(MediaQuery.sizeOf(context).width * 0.75, 500),
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: message.imageUrl!,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            width: 200,
                            height: 150,
                            color: Colors.black12,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  if (message.body.isNotEmpty)
                    Text(
                      message.body,
                      style: TextStyle(
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Colors.black87,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7)
                                : Colors.black38,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readAt != null
                                ? Icons.done_all
                                : Icons.done,
                            size: 14,
                            color: message.readAt != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (reactions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 8,
              right: isMe ? 8 : 0,
              bottom: 8,
            ),
            child: Wrap(
              spacing: 4,
              children: reactions
                  .map((r) => ChatReactionChip(
                        reaction: r,
                        onTap: () => onToggleReaction(r.reaction),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
