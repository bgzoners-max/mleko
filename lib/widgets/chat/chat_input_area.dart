import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController messageController;
  final bool isUploadingImage;
  final bool isSending;
  final VoidCallback onPickImage;
  final void Function([String?]) onSend;
  final List<String> quickReplies;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.isUploadingImage,
    required this.isSending,
    required this.onPickImage,
    required this.onSend,
    required this.quickReplies,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quickReplies.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: quickReplies
                    .map((reply) => ActionChip(
                          label: Text(reply, style: const TextStyle(fontSize: 12)),
                          onPressed: isSending ? null : () => onSend(reply),
                        ))
                    .toList(),
              ),
            if (quickReplies.isNotEmpty) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Poruka...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: IconButton(
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.image_outlined),
                        onPressed: onPickImage,
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isSending ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
