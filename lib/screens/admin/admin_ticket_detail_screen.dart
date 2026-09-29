import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/responsive.dart';
import '../../core/utils/error_messages.dart';
import '../../services/services.dart';
import '../../widgets/app_back_button.dart';

const int _kMaxMessages = 5;

class AdminTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const AdminTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<AdminTicketDetailScreen> createState() =>
      _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  final _service = SupportService();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  SupportTicketModel? _ticket;
  List<TicketMessageModel> _messages = [];
  StreamSubscription<List<TicketMessageModel>>? _sub;
  bool _loading = true;
  bool _sending = false;
  bool _savingStatus = false;
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
      final tickets = await _service.fetchAllTickets();
      final ticket = tickets.firstWhere((t) => t.id == widget.ticketId);
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

  Future<void> _changeStatus(String newStatus) async {
    final ticket = _ticket;
    if (ticket == null) return;
    setState(() => _savingStatus = true);
    try {
      final updated = await _service.updateTicket(ticket.id, status: newStatus);
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status: ${updated.status.label}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  int get _adminMessageCount => _messages.where((m) => m.isAdmin).length;

  bool get _canSend {
    final ticket = _ticket;
    if (ticket == null) return false;
    if (ticket.status == TicketStatus.zatvoren) return false;
    if (_adminMessageCount >= _kMaxMessages) return false;
    return true;
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || !_canSend) return;
    setState(() => _sending = true);
    try {
      await _service.sendTicketMessage(widget.ticketId, text, asAdmin: true);
      _inputCtrl.clear();
      // Auto-set status to u_obradi if still otvoren
      if (_ticket?.status == TicketStatus.otvoren) {
        await _changeStatus(TicketStatus.uObradi.value);
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

  Color _statusColor(TicketStatus status) => switch (status) {
        TicketStatus.otvoren => Colors.orange,
        TicketStatus.uObradi => Colors.blue,
        TicketStatus.zatvoren => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/admin/tickets'),
        title: Text(_ticket?.ticketNumber ?? 'Detalji tiketa'),
        actions: [
          if (_savingStatus)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_ticket != null)
            PopupMenuButton<String>(
              tooltip: 'Promeni status',
              icon: const Icon(Icons.more_vert),
              onSelected: _changeStatus,
              itemBuilder: (_) => TicketStatus.values
                  .map((s) => PopupMenuItem(
                        value: s.value,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _statusColor(s),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(s.label),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          const AppHomeButton(),
        ],
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
    final statusColor = _statusColor(ticket.status);

    return Column(
      children: [
        // Ticket info header
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Breakpoints.formContentWidth(context),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          ticket.status.label,
                          style: TextStyle(
                              color: statusColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                          label: Text(ticket.category.label),
                          visualDensity: VisualDensity.compact),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ticket.subject,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _infoRow(Icons.person_outline,
                      ticket.userName ?? ticket.userEmail ?? 'Anonimno'),
                  if (ticket.userEmail != null)
                    _infoRow(Icons.email_outlined, ticket.userEmail!),
                  _infoRow(Icons.schedule_outlined,
                      _formatDateTime(ticket.createdAt)),
                  const SizedBox(height: 12),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),

        // Chat messages
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
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Original user message
                  _AdminOriginalBubble(body: ticket.body),
                  const SizedBox(height: 4),

                  // Chat messages
                  ..._messages.map((msg) => _AdminMessageBubble(
                        message: msg,
                        statusColor: statusColor,
                      )),

                  if (_messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Još nema odgovora. Pošaljite prvu poruku korisniku.',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Input
        _buildInput(ticket),
      ],
    );
  }

  Widget _buildInput(SupportTicketModel ticket) {
    final isClosed = ticket.status == TicketStatus.zatvoren;
    final limitReached = _adminMessageCount >= _kMaxMessages;

    String hint;
    if (isClosed) {
      hint = 'Tiket je zatvoren';
    } else if (limitReached) {
      hint = 'Dostignut maksimum od $_kMaxMessages poruka';
    } else {
      hint = 'Odgovorite korisniku...';
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Admin poruke: $_adminMessageCount/$_kMaxMessages',
                      style: TextStyle(
                          fontSize: 11,
                          color: limitReached
                              ? Colors.red
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      'Korisnik: ${_messages.where((m) => !m.isAdmin).length}/$_kMaxMessages',
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
                      tooltip: 'Pošalji odgovor',
                    ),
                  ],
                ),
                if (!isClosed) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Zatvori tiket'),
                      onPressed: _savingStatus
                          ? null
                          : () => _changeStatus(TicketStatus.zatvoren.value),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AdminOriginalBubble extends StatelessWidget {
  final String body;
  const _AdminOriginalBubble({required this.body});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poruka korisnika',
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _AdminMessageBubble extends StatelessWidget {
  final TicketMessageModel message;
  final Color statusColor;

  const _AdminMessageBubble({required this.message, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final isAdmin = message.isAdmin;
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor =
        isAdmin ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isAdmin ? colorScheme.onPrimary : colorScheme.onSurface;
    final labelColor = isAdmin
        ? colorScheme.onPrimary.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    final time = message.createdAt.toLocal();
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isAdmin ? 48 : 0,
          right: isAdmin ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isAdmin ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isAdmin ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isAdmin ? 'Administrator' : 'Korisnik',
              style: TextStyle(fontSize: 10, color: labelColor),
            ),
            const SizedBox(height: 4),
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
