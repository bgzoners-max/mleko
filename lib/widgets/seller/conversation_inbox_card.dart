import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/app_error.dart';
import '../../models/product_model.dart';
import '../../services/services.dart';
import '../app_network_image.dart';
import '../error_dialog.dart';
import '../home/seller_inbox_item.dart';

class ConversationInboxCard extends StatefulWidget {
  final SellerInboxItem item;
  final VoidCallback onRefresh;

  const ConversationInboxCard({
    super.key,
    required this.item,
    required this.onRefresh,
  });

  @override
  State<ConversationInboxCard> createState() => _ConversationInboxCardState();
}

class _ConversationInboxCardState extends State<ConversationInboxCard> {
  bool _isProcessing = false;

  Future<void> _toggleFavorite() async {
    final cid = widget.item.conversationId;
    if (cid == null) return;

    setState(() => _isProcessing = true);
    try {
      await context.read<ChatService>().setConversationUserPrefs(
            cid,
            isFavorite: !widget.item.isFavorite,
          );
      widget.onRefresh();
    } catch (e, stack) {
      if (!mounted) return;
      LoggerService.error(
        'Greška pri promeni favorite statusa konverzacije',
        e,
        stackTrace: stack,
        extra: {
          'conversationId': cid,
          'isFavorite': !widget.item.isFavorite,
        },
      );
      ErrorSnackBar.show(context, error: AppError.from(e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmHide(BuildContext context) async {
    final chatService = context.read<ChatService>();
    final cid = widget.item.conversationId;
    if (cid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ukloni sa liste?'),
        content: const Text(
          'Razgovor neće biti prikazan u inbox-u. Istorija ostaje — ponovo će se pojaviti kada otvoriš chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Otkaži'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ukloni'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    setState(() => _isProcessing = true);
    try {
      await chatService.setConversationUserPrefs(cid, hidden: true);
      widget.onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Razgovor je uklonjen sa liste.')),
        );
      }
    } catch (e, stack) {
      if (context.mounted) {
        LoggerService.error(
          'Greška pri sakrivanju konverzacije',
          e,
          stackTrace: stack,
          extra: {
            'conversationId': cid,
          },
        );
        ErrorSnackBar.show(context, error: AppError.from(e));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.item;
    final cid = c.conversationId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                if (cid != null) context.push('/chat/$cid');
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              c.otherPartyImageUrl != null && c.otherPartyImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: AppNetworkImage.profileSmall(
                        imageUrl: c.otherPartyImageUrl!,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        if (c.isFavorite)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.star,
                                size: 14, color: Colors.amber.shade700),
                          ),
                        Expanded(
                          child: c.buyerId != null
                              ? InkWell(
                                  onTap: () =>
                                      context.push('/buyer/${c.buyerId}'),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          c.otherPartyName ?? 'Kupac',
                                          style: TextStyle(
                                            fontWeight: c.unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.person_outline,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary),
                                    ],
                                  ),
                                )
                              : Text(
                                  c.otherPartyName ?? 'Kupac',
                                  style: TextStyle(
                                    fontWeight: c.unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (c.productName != null)
                      Text(
                        '${c.productName}${c.quantityKg != null ? ' · ${ProductModel.formatQuantityWithUnit(c.quantityKg!, c.unitType ?? ProductModel.unitKg)}' : ''}',
                      ),
                    Text(
                      c.lastMessageBody ?? 'Nema poruka',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.unreadCount > 0
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (c.statusLabel != null)
                      Text(
                        c.statusLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (cid != null) ...[
                IconButton(
                  tooltip: _isProcessing
                      ? null
                      : (c.isFavorite ? 'Ukloni iz omiljenih' : 'Omiljeni'),
                  icon: Icon(
                    c.isFavorite ? Icons.star : Icons.star_outline,
                    color: c.isFavorite ? Colors.amber.shade700 : null,
                  ),
                  onPressed: _isProcessing ? null : _toggleFavorite,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) async {
                    if (_isProcessing) return;
                    if (v == 'fav') {
                      await _toggleFavorite();
                    } else if (v == 'hide') {
                      await _confirmHide(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'fav',
                      child: Text(
                        c.isFavorite
                            ? 'Ukloni iz omiljenih'
                            : 'Označi kao omiljeni',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'hide',
                      child: Text('Ukloni sa liste'),
                    ),
                  ],
                ),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (c.unreadCount > 0)
                    Badge(
                      label: Text('${c.unreadCount}'),
                      child: const Icon(Icons.chevron_right, size: 20),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
