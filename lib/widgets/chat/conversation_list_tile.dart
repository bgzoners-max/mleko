import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_system.dart';
import '../../models/conversation_model.dart';
import '../app_network_image.dart';

String formatConvTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
  if (diff.inDays == 1) return 'juče';
  if (diff.inDays < 7) return DateFormat('EEE', 'sr').format(dt);
  if (dt.year == now.year) return DateFormat('d. MMM', 'sr').format(dt);
  return DateFormat('d.M.yy', 'sr').format(dt);
}

class ConversationListTile extends StatefulWidget {
  final ConversationModel conv;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(Offset) onSecondaryTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onHide;

  const ConversationListTile({
    super.key,
    required this.conv,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
    required this.onToggleFavorite,
    required this.onHide,
  });

  @override
  State<ConversationListTile> createState() => _ConversationListTileState();
}

class _ConversationListTileState extends State<ConversationListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final conv = widget.conv;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onSecondaryTapUp: (d) => widget.onSecondaryTap(d.globalPosition),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  conv.otherPartyImageUrl != null &&
                          conv.otherPartyImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: AppNetworkImage.profileSmall(
                            imageUrl: conv.otherPartyImageUrl!,
                            width: 44,
                            height: 44,
                          ),
                        )
                      : CircleAvatar(
                          radius: 22,
                          backgroundColor: isDark
                              ? AmazonColors.darkBorder
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            color: isDark
                                ? AmazonColors.darkTextSecondary
                                : Colors.grey.shade600,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (conv.isFavorite)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.star,
                                    size: 14, color: Colors.amber.shade700),
                              ),
                            Expanded(
                              child: Text(
                                conv.otherPartyName ?? 'Korisnik',
                                style: TextStyle(
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (conv.itemTitle != null && conv.itemTitle!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  conv.itemType == 'ad'
                                      ? Icons.campaign_outlined
                                      : Icons.shopping_bag_outlined,
                                  size: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    conv.itemTitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          conv.lastMessageBody ?? 'Nema poruka',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conv.unreadCount > 0
                                ? (isDark
                                    ? AmazonColors.darkTextPrimary
                                    : Colors.black87)
                                : (isDark
                                    ? AmazonColors.darkTextSecondary
                                    : Colors.grey.shade600),
                            fontWeight: conv.unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_hovered)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: conv.isFavorite
                              ? 'Ukloni iz omiljenih'
                              : 'Dodaj u omiljene',
                          icon: Icon(
                            conv.isFavorite ? Icons.star : Icons.star_border,
                            color: conv.isFavorite ? Colors.amber : null,
                          ),
                          onPressed: widget.onToggleFavorite,
                        ),
                        IconButton(
                          tooltip: 'Sakrij razgovor',
                          icon: const Icon(Icons.visibility_off_outlined),
                          onPressed: widget.onHide,
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatConvTime(conv.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: conv.unreadCount > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (conv.unreadCount > 0)
                          Badge(
                            label: Text('${conv.unreadCount}'),
                            child: const SizedBox(width: 8),
                          )
                        else
                          const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
