import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/message_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_error_retry.dart';

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

  // Stream se čuva kao polje — sprečava re-kreiranje kanala na svakom buildu.
  late final Stream<List<MessageModel>> _messagesStream = ChatService()
      .watchMessages(widget.conversationId,
          refreshTrigger: _refreshController.stream);
  late final Stream<Set<String>> _typingStream =
      ChatService().watchTypingUsers(widget.conversationId);

  // Starije poruke učitane paginacijom ("Učitaj starije poruke")
  final List<MessageModel> _olderMessages = [];
  bool _hasOlderMessages = true;
  bool _loadingOlder = false;

  // Typing indicator
  bool _isTyping = false;
  Timer? _typingTimer;

  bool _sending = false;
  String? _otherPartyName;
  String? _otherPartyId;
  OrderModel? _order;
  bool _isBuyer = true;
  List<String> _sellerCustomReplies = const [];

  // Debounce: markAsRead se poziva samo kada stigne nova poruka,
  // ne na svakom rebuildu widgeta.
  int _lastMarkedReadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadConversationInfo();
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _typingTimer?.cancel();
    // Obavesti server da korisnik više ne kuca
    final userId = context.read<AppState>().user?.id;
    if (userId != null && _isTyping) {
      ChatService().setTyping(
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
      ChatService().setTyping(
          conversationId: widget.conversationId,
          userId: userId,
          isTyping: true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(ChatService.typingStaleThreshold, () {
      if (_isTyping) {
        _isTyping = false;
        ChatService().setTyping(
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
      final older = await ChatService().getOlderMessages(
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}.${dt.month}.';
  }

  Future<void> _loadConversationInfo() async {
    final user = context.read<AppState>().user;
    if (user == null) return;
    final results = await Future.wait<dynamic>([
      ChatService().getOtherPartyName(widget.conversationId, user.id),
      ChatService().getConversationInfo(widget.conversationId),
    ]);
    final name = results[0] as String?;
    final info = results[1] as Map<String, dynamic>?;
    OrderModel? order;
    if (info != null && info['order_id'] != null) {
      order = await OrdersService().getOrderById(info['order_id'] as String);
    }
    final buyerId = info?['buyer_id'] as String?;
    final sellerId = info?['seller_id'] as String?;
    final isBuyer = buyerId != null && buyerId == user.id;
    final otherPartyId = isBuyer ? sellerId : buyerId;
    final customReplies = !isBuyer ? user.sellerQuickReplies : const <String>[];
    if (mounted) {
      setState(() {
        _otherPartyName = name;
        _otherPartyId = otherPartyId;
        _order = order;
        _isBuyer = isBuyer;
        _sellerCustomReplies = customReplies.length > 5
            ? customReplies.take(5).toList()
            : customReplies;
      });
    }
  }

  Future<void> _send([String? textOverride]) async {
    final text = (textOverride ?? _messageController.text).trim();
    if (text.isEmpty) return;
    if (textOverride != null) _messageController.clear();
    final user = context.read<AppState>().user;
    if (user == null) return;

    if (textOverride == null) _messageController.clear();
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      ChatService().setTyping(
          conversationId: widget.conversationId,
          userId: user.id,
          isTyping: false);
    }
    setState(() => _sending = true);
    try {
      await ChatService().sendMessage(widget.conversationId, user.id, text);
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
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
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
      body: Column(
        children: [
          if (_order != null) _OrderContextCard(order: _order!),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
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
                  return const Center(child: CircularProgressIndicator());
                }
                final recent = snap.data ?? [];
                final messages = [..._olderMessages, ...recent];

                // markAsRead samo kada se promeni broj poruka (nova poruka stigla),
                // ne na svakom rebuildu (npr. rebuild zbog setState).
                if (messages.length != _lastMarkedReadCount) {
                  _lastMarkedReadCount = messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ChatService().markAsRead(widget.conversationId, user.id);
                  });
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Nema poruka.\nPošaljite prvu poruku.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  // +1 za "Učitaj starije poruke" tile na vrhu
                  itemCount: messages.length + (_hasOlderMessages ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == 0 && _hasOlderMessages) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Center(
                          child: _loadingOlder
                              ? const CircularProgressIndicator()
                              : TextButton.icon(
                                  icon: const Icon(Icons.expand_less, size: 18),
                                  label: const Text('Učitaj starije poruke'),
                                  onPressed: () => _loadOlderMessages(recent),
                                ),
                        ),
                      );
                    }
                    final m = messages[_hasOlderMessages ? i - 1 : i];
                    final isMe = m.senderId == user.id;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            if (isMe)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatTime(m.createdAt),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
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
                                              .withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
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
                              onPressed: _sending ? null : () => _send(reply),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Poruka...',
                            border: OutlineInputBorder(),
                            isDense: true,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
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
    );
  }
}

class _OrderContextCard extends StatelessWidget {
  final OrderModel order;

  const _OrderContextCard({required this.order});

  @override
  Widget build(BuildContext context) {
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
}

/// Tri animovane tačke koje pokazuju da sagovornik kuca.
class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final offset = ((_controller.value * 3) - i).clamp(0.0, 1.0);
            final opacity = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
            return Opacity(
              opacity: opacity.clamp(0.2, 1.0),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
