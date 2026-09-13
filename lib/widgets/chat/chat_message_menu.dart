import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import '../../models/message_model.dart';
import '../emoji_text.dart';

const kChatReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

bool get _isDesktopPlatform =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;

void showChatMessageActions({
  required BuildContext context,
  required MessageModel message,
  required bool isMe,
  required void Function(String emoji) onReaction,
  required VoidCallback onDelete,
  Offset? tapPosition,
}) {
  if (_isDesktopPlatform && tapPosition != null) {
    _showDesktopContextMenu(
      context: context,
      message: message,
      isMe: isMe,
      position: tapPosition,
      onReaction: onReaction,
      onDelete: onDelete,
    );
  } else {
    _showMobileBottomSheet(
      context: context,
      message: message,
      isMe: isMe,
      onReaction: onReaction,
      onDelete: onDelete,
    );
  }
}

Future<void> _showDesktopContextMenu({
  required BuildContext context,
  required MessageModel message,
  required bool isMe,
  required Offset position,
  required void Function(String emoji) onReaction,
  required VoidCallback onDelete,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final rel = RelativeRect.fromRect(
    Rect.fromLTWH(position.dx, position.dy, 1, 1),
    Offset.zero & overlay.size,
  );

  final result = await showMenu<String>(
    context: context,
    position: rel,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    items: [
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: kChatReactionEmojis.map((emoji) {
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.pop(context, 'reaction:$emoji');
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: EmojiText(
                  emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const PopupMenuDivider(height: 1),
      const PopupMenuItem<String>(
        value: 'copy',
        child: Row(
          children: [
            Icon(Icons.copy_outlined, size: 18),
            SizedBox(width: 10),
            Text('Kopiraj poruku'),
          ],
        ),
      ),
      if (isMe)
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Obriši poruku', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
    ],
  );

  if (result == null || !context.mounted) return;
  if (result.startsWith('reaction:')) {
    onReaction(result.substring(9));
  } else if (result == 'copy') {
    await Clipboard.setData(ClipboardData(text: message.body));
    if (context.mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Poruka kopirana')));
    }
  } else if (result == 'delete') {
    onDelete();
  }
}

void _showMobileBottomSheet({
  required BuildContext context,
  required MessageModel message,
  required bool isMe,
  required void Function(String emoji) onReaction,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: kChatReactionEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onReaction(emoji);
                  },
                  child: EmojiText(
                    emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Kopiraj poruku'),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message.body));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Poruka kopirana')),
              );
            },
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Obriši poruku',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
        ],
      ),
    ),
  );
}
