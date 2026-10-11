import 'dart:async';
import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/utils/error_messages.dart';
import '../services/services.dart';
import '../widgets/app_back_button.dart';

const int _kMaxMessages = 5;

class SupportTicketChatScreen extends StatefulWidget {
  final String ticketId;
  const SupportTicketChatScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketChatScreen> createState() =>
      _SupportTicketChatScreenState();
}

class _SupportTicketChatScreenState extends State<SupportTicketChatScreen> {
  final _service = SupportService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  SupportTicketModel? _ticket;
  List<TicketMessageModel> _messages = [];
  StreamSubscription<List<TicketMessageModel>>? _sub;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket = await _service.fetchTicketById(widget.ticketId);
      if (ticket == null) {
        if (!mounted) return;
        setState(() => _error = 'Tiket nije pronađen.');
        return;
      }
      if (!mounted) return;
      setState(() => _ticket = ticket);
      _sub = _service.watchTicketMessages(widget.ticketId).listen((msgs) {
        if (!mounted) return;
        setState(() => _messages = msgs);
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int get _userMessageCount => _messages.where((m) => !m.isAdmin).length;

  bool get _canSend {
    final ticket = _ticket;
    if (ticket == null) return false;
    if (ticket.status == TicketStatus.zatvoren) return false;
    if (_userMessageCount >= _kMaxMessages) return false;
    return true;
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_canSend) return;
    setState(() => _sending = true);
    try {
      await _service.sendTicketMessage(widget.ticketId, text, asAdmin: false);
      _inputCtrl.clear();
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

  Color _statusColor(TicketStatus status) => switch (status) {
        TicketStatus.otvoren => Colors.orange,
        TicketStatus.uObradi => Colors.blue,
        TicketStatus.zatvoren => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/support'),
        title: Text(_ticket?.subject ?? 'Razgovor sa podrškom'),
        actions: const [
          AppHomeButton(),
        ],
        bottom: _ticket != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(_ticket!.status)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _ticket!.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              color: _statusColor(_ticket!.status),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _ticket!.ticketNumber,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Greška: $_error'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final ticket = _ticket!;

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Breakpoints.formContentWidth(context),
              ),
              child: ListView(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Originalna poruka tiketa
                  _OriginalMessageBubble(body: ticket.body),
                  const SizedBox(height: 4),

                  // Chat poruke
                  ..._messages.map((msg) => _MessageBubble(
                        message: msg,
                        isMe: !msg.isAdmin,
                      )),

                  if (_messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Čekamo odgovor administratora...',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),

        // Counter + input
        _buildInput(ticket),
      ],
    );
  }

  Widget _buildInput(SupportTicketModel ticket) {
    final isClosed = ticket.status == TicketStatus.zatvoren;
    final limitReached = _userMessageCount >= _kMaxMessages;

    String hint;
    if (isClosed) {
      hint = 'Tiket je zatvoren';
    } else if (limitReached) {
      hint = 'Dostignut maksimum od $_kMaxMessages poruka';
    } else {
      hint = 'Odgovorite administratoru...';
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress counter
                Row(
                  children: [
                    Text(
                      'Vaše poruke: $_userMessageCount/$_kMaxMessages',
                      style: TextStyle(
                          fontSize: 11,
                          color: limitReached
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    if (_messages.isNotEmpty)
                      Text(
                        'Admin: ${_messages.where((m) => m.isAdmin).length}/$_kMaxMessages',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        enabled: _canSend && !_sending,
                        decoration: InputDecoration(
                          hintText: hint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      onPressed: _canSend && !_sending ? _send : null,
                      tooltip: 'Pošalji',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _OriginalMessageBubble extends StatelessWidget {
  final String body;
  const _OriginalMessageBubble({required this.body});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Vaša prijava',
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary
                      .withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Text(body,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = message.isAdmin;

    final bgColor =
        isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;
    final labelColor = isMe
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    final time = message.createdAt.toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isAdmin)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent, size: 12, color: labelColor),
                  const SizedBox(width: 4),
                  Text('Administrator',
                      style: TextStyle(fontSize: 10, color: labelColor)),
                ],
              ),
            if (isAdmin) const SizedBox(height: 4),
            Text(message.body,
                style: TextStyle(color: textColor, fontSize: 14)),
            const SizedBox(height: 2),
            Text(timeStr, style: TextStyle(fontSize: 10, color: labelColor)),
          ],
        ),
      ),
    );
  }
}
