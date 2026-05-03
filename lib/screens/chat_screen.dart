import 'dart:async';
import 'dart:math' show min, sin, pi;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/message_model.dart';
import '../models/message_reaction_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/emoji_text.dart';
import '../widgets/skeleton.dart';

const _kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

/// Brzi odgovori – različiti za kupca i prodavca
const _quickRepliesBuyer = [
  'Da li je još uvek dostupno?',
  'Kada mogu da preuzmem?',
  'Da li možete da dostavite?',
  'Hvala, čekam potvrdu.',
];

const _quickRepliesSeller = [
  'Prihvatam porudžbinu.',
  'Dostupno sutra.',
  'Pozovite me na telefon.',
  'Nažalost, trenutno nemam na stanju.',
];

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _refreshController = StreamController<void>.broadcast();
  late ChatService _chatService;
  final _imagePicker = ImagePicker();
  bool _uploadingImage = false;

  late final Stream<List<MessageModel>> _messagesStream =
      _chatService.watchMessages(widget.conversationId,
          refreshTrigger: _refreshController.stream);
  late final Stream<Set<String>> _typingStream =
      _chatService.watchTypingUsers(widget.conversationId);
  Stream<List<MessageReactionModel>>? _reactionsStream;

  final List<MessageModel> _olderMessages = [];
  bool _hasOlderMessages = true;
  bool _loadingOlder = false;

  bool _isTyping = false;
  Timer? _typingTimer;

  bool _sending = false;
  String? _otherPartyName;
  String? _otherPartyId;
  OrderModel? _order;
  bool _isBuyer = true;
  List<String> _sellerCustomReplies = const [];
  SellerResponseStats? _sellerStats;

  int _lastMarkedReadCount = 0;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _loadConversationInfo();
    _messageController.addListener(_onTypingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AppState>().user?.id;
      if (userId != null && mounted) {
        setState(() {
          _reactionsStream =
              _chatService.watchMessageReactions(widget.conversationId, userId);
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _typingTimer?.cancel();
    final userId = context.read<AppState>().user?.id;
    if (userId != null && _isTyping) {
      _chatService.setTyping(
          conversationId: widget.conversationId,
          userId: userId,
          isTyping: false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    _refreshController.close();
    super.dispose();
  }

  void _onTypingChanged() {
    final userId = context.read<AppState>().user?.id;
    if (userId == null) return;
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _chatService.setTyping(
          conversationId: widget.conversationId,
          userId: userId,
          isTyping: true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(ChatService.typingStaleThreshold, () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.setTyping(
            conversationId: widget.conversationId,
            userId: userId,
            isTyping: false);
      }
    });
  }

  Future<void> _loadOlderMessages(List<MessageModel> current) async {
    if (_loadingOlder || !_hasOlderMessages) return;
    final oldest = _olderMessages.isNotEmpty
        ? _olderMessages.first.createdAt
        : current.isNotEmpty
            ? current.first.createdAt
            : DateTime.now();
    setState(() => _loadingOlder = true);
    try {
      final older = await _chatService.getOlderMessages(
        widget.conversationId,
        before: oldest,
      );
      if (mounted) {
        setState(() {
          _olderMessages.insertAll(0, older);
          if (older.length < 50) _hasOlderMessages = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  List<_ChatItem> _buildChatItems(List<MessageModel> messages) {
    final items = <_ChatItem>[];
    DateTime? lastDay;
    for (final m in messages) {
      final day =
          DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDay == null || day != lastDay) {
        items.add(_DateSeparatorItem(day));
        lastDay = day;
      }
      items.add(_MessageChatItem(m));
    }
    return items;
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month}.';
  }

  Future<void> _loadConversationInfo() async {
    final ordersService = context.read<OrdersService>();
    final user = context.read<AppState>().user;
    if (user == null) return;
    final info = await _chatService
        .getConversationInfoWithProfiles(widget.conversationId);

    OrderModel? order;
    if (info.orderId != null) {
      order = await ordersService.getOrderById(info.orderId!);
    }

    final isBuyer = info.buyerId == user.id;
    final otherPartyId = isBuyer ? info.sellerId : info.buyerId;
    final otherPartyName = isBuyer ? info.sellerName : info.buyerName;
    final customReplies = !isBuyer ? user.sellerQuickReplies : const <String>[];

    if (mounted) {
      setState(() {
        _otherPartyName = otherPartyName;
        _otherPartyId = otherPartyId;
        _order = order;
        _isBuyer = isBuyer;
        _sellerCustomReplies = customReplies.length > 5
            ? customReplies.take(5).toList()
            : customReplies;
      });
    }

    if (isBuyer && otherPartyId != null) {
      final stats = await _chatService.getSellerResponseStats(otherPartyId);
      if (mounted && stats.hasData) {
        setState(() => _sellerStats = stats);
      }
    }
  }

  Future<void> _deleteMessage(MessageModel m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Obriši poruku'),
        content:
            const Text('Da li ste sigurni? Ova radnja se ne može poništiti.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Odustani')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _chatService.deleteMessage(m.id);
      _refreshController.add(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_uploadingImage) return;
    final user = context.read<AppState>().user;
    if (user == null) return;

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (file == null) return;

      setState(() => _uploadingImage = true);
      final bytes = await file.readAsBytes();

      final url = await _chatService.uploadMessageImage(
        widget.conversationId,
        user.id,
        bytes,
      );

      await _chatService.sendMessage(
        widget.conversationId,
        user.id,
        '',
        imageUrl: url,
      );
      _refreshController.add(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri slanju slike: ${friendlyError(e)}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _toggleReaction(MessageModel m, String emoji) async {
    final user = context.read<AppState>().user;
    if (user == null) return;
    try {
      await _chatService.toggleMessageReaction(
        conversationId: widget.conversationId,
        messageId: m.id,
        userId: user.id,
        reaction: emoji,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool get _isDesktop =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _showMessageMenu(BuildContext context, MessageModel m, bool isMe,
      {Offset? tapPosition}) {
    if (_isDesktop && tapPosition != null) {
      _showDesktopContextMenu(context, m, isMe, tapPosition);
    } else {
      _showMobileBottomSheet(context, m, isMe);
    }
  }

  Future<void> _showDesktopContextMenu(
      BuildContext context, MessageModel m, bool isMe, Offset position) async {
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
            children: _kReactionEmojis.map((emoji) {
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

    if (result == null || !mounted) return;
    if (result.startsWith('reaction:')) {
      _toggleReaction(m, result.substring(9));
    } else if (result == 'copy') {
      await Clipboard.setData(ClipboardData(text: m.body));
      if (mounted) {
        messenger
            .showSnackBar(const SnackBar(content: Text('Poruka kopirana')));
      }
    } else if (result == 'delete') {
      _deleteMessage(m);
    }
  }

  void _showMobileBottomSheet(BuildContext context, MessageModel m, bool isMe) {
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
                children: _kReactionEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _toggleReaction(m, emoji);
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
                Clipboard.setData(ClipboardData(text: m.body));
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
                  _deleteMessage(m);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _send([String? textOverride]) async {
    final text = (textOverride ?? _messageController.text).trim();
    if (text.isEmpty && textOverride == null) return;
    final user = context.read<AppState>().user;
    if (user == null) return;

    if (textOverride == null) _messageController.clear();
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      _chatService.setTyping(
          conversationId: widget.conversationId,
          userId: user.id,
          isTyping: false);
    }
    setState(() => _sending = true);
    try {
      await _chatService.sendMessage(widget.conversationId, user.id, text);
      _refreshController.add(null);
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Razgovor')),
        body: const Center(child: Text('Prijavite se.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherPartyName ?? 'Razgovor'),
        actions: [
          if (_otherPartyId != null)
            IconButton(
              tooltip: _isBuyer ? 'Profil prodavca' : 'Profil kupca',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => context.push(
                _isBuyer ? '/seller/$_otherPartyId' : '/buyer/$_otherPartyId',
              ),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: Column(
            children: [
              if (_order != null) _OrderContextCard(order: _order!),
              if (_sellerStats != null) _SellerStatsCard(stats: _sellerStats!),
              Expanded(
                child: StreamBuilder<List<MessageReactionModel>>(
                  stream: _reactionsStream,
                  builder: (context, reactionsSnap) {
                    final reactionsByMsg =
                        <String, List<MessageReactionModel>>{};
                    for (final r in reactionsSnap.data ?? []) {
                      reactionsByMsg.putIfAbsent(r.messageId, () => []).add(r);
                    }
                    return StreamBuilder<List<MessageModel>>(
                      stream: _messagesStream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return AppErrorRetry(
                            message: 'Greška pri učitavanju poruka.',
                            detail: snap.error?.toString(),
                            onRetry: () => _refreshController.add(null),
                          );
                        }
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const ChatMessagesSkeleton();
                        }
                        final recent = snap.data ?? [];
                        final messages = [..._olderMessages, ...recent];

                        if (messages.length != _lastMarkedReadCount) {
                          _lastMarkedReadCount = messages.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _chatService.markAsRead(
                                widget.conversationId, user.id);
                          });
                        }

                        if (messages.isEmpty) {
                          return AppEmptyState(
                            icon: Icons.chat_bubble_outline,
                            title: 'Nema poruka',
                            subtitle: 'Započnite razgovor sa prodavcem.',
                          );
                        }

                        final items = _buildChatItems(messages);
                        final totalCount =
                            items.length + (_hasOlderMessages ? 1 : 0);

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: totalCount,
                          itemBuilder: (_, i) {
                            if (i == 0 && _hasOlderMessages) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Center(
                                  child: _loadingOlder
                                      ? const CircularProgressIndicator()
                                      : TextButton.icon(
                                          icon: const Icon(Icons.expand_less,
                                              size: 18),
                                          label: const Text(
                                              'Učitaj starije poruke'),
                                          onPressed: () =>
                                              _loadOlderMessages(recent),
                                        ),
                                ),
                              );
                            }
                            final item = items[_hasOlderMessages ? i - 1 : i];
                            if (item is _DateSeparatorItem) {
                              return _DateSeparator(date: item.date);
                            }
                            final m = (item as _MessageChatItem).message;
                            final isMe = m.senderId == user.id;
                            final msgReactions = reactionsByMsg[m.id] ?? [];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: GestureDetector(
                                    onSecondaryTapUp: (details) =>
                                        _showMessageMenu(context, m, isMe,
                                            tapPosition:
                                                details.globalPosition),
                                    onLongPress: () =>
                                        _showMessageMenu(context, m, isMe),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      constraints: BoxConstraints(
                                          maxWidth: min(
                                              MediaQuery.sizeOf(context).width *
                                                  0.75,
                                              500)),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (m.imageUrl != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: CachedNetworkImage(
                                                  imageUrl: m.imageUrl!,
                                                  width: 200,
                                                  fit: BoxFit.cover,
                                                  placeholder: (_, __) =>
                                                      Container(
                                                    width: 200,
                                                    height: 150,
                                                    color: Colors.black12,
                                                    child: const Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                  ),
                                                  errorWidget: (_, __, ___) =>
                                                      const Icon(Icons.error),
                                                ),
                                              ),
                                            ),
                                          if (m.body.isNotEmpty)
                                            Text(
                                              m.body,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                    : Colors.black87,
                                              ),
                                            ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatTime(m.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMe
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                            .withValues(
                                                                alpha: 0.7)
                                                        : Colors.black38,
                                                  ),
                                                ),
                                                if (isMe) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    m.readAt != null
                                                        ? Icons.done_all
                                                        : Icons.done,
                                                    size: 14,
                                                    color: m.readAt != null
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .onPrimaryContainer
                                                            .withValues(
                                                                alpha: 0.7),
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
                                if (msgReactions.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isMe ? 0 : 8,
                                      right: isMe ? 8 : 0,
                                      bottom: 8,
                                    ),
                                    child: Wrap(
                                      spacing: 4,
                                      children: msgReactions
                                          .map((r) => _ReactionChip(
                                                reaction: r,
                                                onTap: () => _toggleReaction(
                                                    m, r.reaction),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<Set<String>>(
                stream: _typingStream,
                builder: (context, snap) {
                  final typingUsers = snap.data ?? {};
                  final othersTyping = typingUsers
                      .where((id) => id != context.read<AppState>().user?.id)
                      .toList();
                  if (othersTyping.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 16,
                          child: _TypingDots(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'kuca...',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration:
                    BoxDecoration(color: Theme.of(context).colorScheme.surface),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (_isBuyer
                                ? _quickRepliesBuyer
                                : (_sellerCustomReplies.isNotEmpty
                                    ? _sellerCustomReplies
                                    : _quickRepliesSeller))
                            .map((reply) => ActionChip(
                                  label: Text(reply,
                                      style: const TextStyle(fontSize: 12)),
                                  onPressed:
                                      _sending ? null : () => _send(reply),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Poruka...',
                                border: const OutlineInputBorder(),
                                isDense: true,
                                prefixIcon: IconButton(
                                  icon: _uploadingImage
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.image_outlined),
                                  onPressed: _pickAndSendImage,
                                ),
                              ),
                              maxLines: 3,
                              minLines: 1,
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderContextCard extends StatelessWidget {
  final OrderModel order;

  const _OrderContextCard({required this.order});

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () => context.go('/orders'),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.shopping_bag,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      order.productName ??
                          (order.hasMultipleItems
                              ? 'Više proizvoda'
                              : 'Porudžbina'),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                      order.hasMultipleItems
                          ? order.statusLabel
                          : '${ProductModel.formatQuantityWithUnit(order.quantityKg ?? 0, order.unitType ?? ProductModel.unitKg)} · ${order.statusLabel}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(BuildContext context) {
    if (order.status != OrderStatus.sent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleAction(context, OrderStatus.rejected),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Odbij'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _handleAction(context, OrderStatus.accepted),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Prihvati'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, OrderStatus status) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == OrderStatus.accepted
            ? 'Prihvati porudžbinu?'
            : 'Odbij porudžbinu?'),
        content: Text(status == OrderStatus.accepted
            ? 'Da li ste sigurni da želite da prihvatite ovu porudžbinu?'
            : 'Da li ste sigurni da želite da odbijete ovu porudžbinu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Odustani')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: status == OrderStatus.accepted
                  ? null
                  : Theme.of(context).colorScheme.error,
            ),
            child: Text(status == OrderStatus.accepted ? 'Prihvati' : 'Odbij'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    try {
      await context.read<OrdersService>().updateOrderStatus(order.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == OrderStatus.accepted
                ? 'Porudžbina prihvaćena.'
                : 'Porudžbina odbijena.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isSeller = user?.id == order.sellerId;

    return Column(
      children: [
        _buildCard(context),
        if (isSeller) _buildOrderActions(context),
      ],
    );
  }
}

// ─── Chat item types ─────────────────────────────────────────────────────────

abstract class _ChatItem {}

class _MessageChatItem extends _ChatItem {
  final MessageModel message;
  _MessageChatItem(this.message);
}

class _DateSeparatorItem extends _ChatItem {
  final DateTime date;
  _DateSeparatorItem(this.date);
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${date.day}.${date.month}.${date.year}.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final MessageReactionModel reaction;
  final VoidCallback onTap;

  const _ReactionChip({required this.reaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: reaction.reactedByMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: reaction.reactedByMe
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
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

class _SellerStatsCard extends StatelessWidget {
  final SellerResponseStats stats;
  const _SellerStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Obično odgovara za ${stats.medianLabel}',
            style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) {
            final val = sin((_controller.value * 2 * pi) - (i * pi / 3));
            return Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400
                    .withValues(alpha: 0.3 + (val + 1) / 2 * 0.7),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
