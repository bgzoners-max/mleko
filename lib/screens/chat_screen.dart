import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../models/message_model.dart';
import '../models/message_reaction_model.dart';
import '../models/order_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/emoji_text.dart';
import '../widgets/skeleton.dart';

import '../widgets/chat/chat_order_context_card.dart';
import '../widgets/chat/chat_seller_stats_card.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_typing_indicator.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_input_area.dart';

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
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUserId = context.read<AppState>().user?.id;
  }

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
    final userId = _currentUserId;
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
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
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
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
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
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
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
              if (_order != null) ChatOrderContextCard(order: _order!),
              if (_sellerStats != null)
                ChatSellerStatsCard(stats: _sellerStats!),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Možeš odmah poslati brzi odgovor, priložiti sliku ili koristiti opcije za kopiranje i brisanje poruke.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.4,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                          return const AppEmptyState(
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
                              return ChatDateSeparator(date: item.date);
                            }
                            final m = (item as _MessageChatItem).message;
                            final isMe = m.senderId == user.id;
                            final msgReactions = reactionsByMsg[m.id] ?? [];
                            return ChatMessageBubble(
                              message: m,
                              isMe: isMe,
                              reactions: msgReactions,
                              onShowMenu: (tapPosition) => _showMessageMenu(
                                  context, m, isMe,
                                  tapPosition: tapPosition),
                              onToggleReaction: (emoji) =>
                                  _toggleReaction(m, emoji),
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
                        const SizedBox(
                          width: 24,
                          height: 16,
                          child: ChatTypingIndicator(),
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
              ChatInputArea(
                messageController: _messageController,
                isUploadingImage: _uploadingImage,
                isSending: _sending,
                onPickImage: _pickAndSendImage,
                onSend: _send,
                quickReplies: _isBuyer
                    ? _quickRepliesBuyer
                    : (_sellerCustomReplies.isNotEmpty
                        ? _sellerCustomReplies
                        : _quickRepliesSeller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class _ChatItem {}

class _MessageChatItem extends _ChatItem {
  final MessageModel message;
  _MessageChatItem(this.message);
}

class _DateSeparatorItem extends _ChatItem {
  final DateTime date;
  _DateSeparatorItem(this.date);
}
