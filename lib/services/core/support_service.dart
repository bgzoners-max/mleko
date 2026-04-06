import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';

enum SupportCategory {
  bug('bug', 'Greška / bug'),
  pitanje('pitanje', 'Pitanje'),
  sugestija('sugestija', 'Sugestija'),
  ostalo('ostalo', 'Ostalo');

  final String value;
  final String label;
  const SupportCategory(this.value, this.label);

  static SupportCategory fromValue(String v) => SupportCategory.values
      .firstWhere((e) => e.value == v, orElse: () => SupportCategory.ostalo);
}

enum TicketStatus {
  otvoren('otvoren', 'Otvoren'),
  uObradi('u_obradi', 'U obradi'),
  zatvoren('zatvoren', 'Zatvoren');

  final String value;
  final String label;
  const TicketStatus(this.value, this.label);

  static TicketStatus fromValue(String v) => TicketStatus.values
      .firstWhere((e) => e.value == v, orElse: () => TicketStatus.otvoren);
}

class SupportTicketResult {
  final String ticketNumber;
  final String id;
  SupportTicketResult({required this.ticketNumber, required this.id});
}

class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String? userId;
  final String? userEmail;
  final String? userName;
  final SupportCategory category;
  final String subject;
  final String body;
  final TicketStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.ticketNumber,
    this.userId,
    this.userEmail,
    this.userName,
    required this.category,
    required this.subject,
    required this.body,
    required this.status,
    this.adminNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final legacyBody = json['message'] as String?;
    final resolvedBody = json['body'] as String? ?? legacyBody ?? '';
    final rawTicketNumber = json['ticket_number'] as String?;
    final fallbackTicketNumber = json['id'] == null
        ? 'TKT-NEPOZNAT'
        : 'TKT-${(json['id'] as String).substring(0, 8).toUpperCase()}';

    return SupportTicketModel(
      id: json['id'] as String,
      ticketNumber: rawTicketNumber ?? fallbackTicketNumber,
      userId: json['user_id'] as String?,
      userEmail: json['user_email'] as String? ?? json['email'] as String?,
      userName: json['user_name'] as String?,
      category:
          SupportCategory.fromValue(json['category'] as String? ?? 'ostalo'),
      subject: json['subject'] as String,
      body: resolvedBody,
      status: TicketStatus.fromValue(
        json['status'] as String? ?? TicketStatus.otvoren.value,
      ),
      adminNote:
          json['admin_note'] as String? ?? json['admin_reply'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class TicketMessageModel {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  bool get isAdmin => senderRole == 'admin';

  const TicketMessageModel({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) =>
      TicketMessageModel(
        id: json['id'] as String,
        ticketId: json['ticket_id'] as String,
        senderId: json['sender_id'] as String,
        senderRole: json['sender_role'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class SupportService {
  final _client = Supabase.instance.client;

  bool _isSupportSchemaMismatch(Object error) {
    if (error is! PostgrestException) return false;
    final msg = error.message.toLowerCase();
    return error.code == 'PGRST204' ||
        msg.contains("support_tickets") &&
            (msg.contains("body") ||
                msg.contains("user_email") ||
                msg.contains("user_name") ||
                msg.contains("ticket_number") ||
                msg.contains("category") ||
                msg.contains("admin_note"));
  }

  Future<SupportTicketResult> _submitLegacyCompatibleTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required SupportCategory category,
    required String subject,
    required String body,
    required String ticketNumber,
  }) async {
    final legacySubject = '[$ticketNumber] ${subject.trim()}';
    final legacyMessage = [
      'Kategorija: ${category.label}',
      if (userName.trim().isNotEmpty) 'Ime: ${userName.trim()}',
      '',
      body.trim(),
    ].join('\n');

    final data = await _client
        .from('support_tickets')
        .insert({
          'user_id': userId,
          'email': userEmail,
          'subject': legacySubject,
          'message': legacyMessage,
          'status': TicketStatus.otvoren.value,
        })
        .select('id')
        .single();

    return SupportTicketResult(
      ticketNumber: ticketNumber,
      id: data['id'] as String,
    );
  }

  String _generateTicketNumber() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'TKT-$suffix';
  }

  Future<SupportTicketResult> submitTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required SupportCategory category,
    required String subject,
    required String body,
  }) async {
    final ticketNumber = _generateTicketNumber();
    final trimmedSubject = subject.trim();
    final trimmedBody = body.trim();
    final legacyMessage = [
      'Kategorija: ${category.label}',
      if (userName.trim().isNotEmpty) 'Ime: ${userName.trim()}',
      '',
      trimmedBody,
    ].join('\n');

    try {
      final data = await _client
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'email': userEmail,
            'user_email': userEmail,
            'user_name': userName,
            'category': category.value,
            'subject': trimmedSubject,
            'body': trimmedBody,
            'message': legacyMessage,
            'ticket_number': ticketNumber,
            'status': TicketStatus.otvoren.value,
          })
          .select('id, ticket_number')
          .single();

      return SupportTicketResult(
        ticketNumber: (data['ticket_number'] as String?) ?? ticketNumber,
        id: data['id'] as String,
      );
    } on PostgrestException catch (error) {
      if (!_isSupportSchemaMismatch(error)) rethrow;
      return _submitLegacyCompatibleTicket(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        category: category,
        subject: trimmedSubject,
        body: trimmedBody,
        ticketNumber: ticketNumber,
      );
    }
  }

  /// Korisnik: lista vlastitih tiketa
  Future<List<SupportTicketModel>> fetchMyTickets() async {
    final data = await _client
        .from('support_tickets')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => SupportTicketModel.fromJson(e)).toList();
  }

  /// Admin: lista svih tiketa, opcionalni filter po statusu
  Future<List<SupportTicketModel>> fetchAllTickets({String? status}) async {
    var query = _client
        .from('support_tickets')
        .select()
        .order('created_at', ascending: false);
    if (status != null) {
      query = _client
          .from('support_tickets')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);
    }
    final data = await query;
    return (data as List).map((e) => SupportTicketModel.fromJson(e)).toList();
  }

  /// Admin: ažuriraj tiket (status i/ili admin_note)
  Future<SupportTicketModel> updateTicket(
    String id, {
    String? status,
    String? adminNote,
  }) async {
    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (adminNote != null) updates['admin_note'] = adminNote;

    final data = await _client
        .from('support_tickets')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return SupportTicketModel.fromJson(data);
  }

  // ── Ticket chat ─────────────────────────────────────────────────────────────

  Future<List<TicketMessageModel>> getTicketMessages(String ticketId) async {
    final data = await _client
        .from('support_ticket_messages')
        .select()
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => TicketMessageModel.fromJson(e)).toList();
  }

  Future<void> sendTicketMessage(
    String ticketId,
    String body, {
    required bool asAdmin,
  }) async {
    await _client.from('support_ticket_messages').insert({
      'ticket_id': ticketId,
      'sender_id': _client.auth.currentUser!.id,
      'sender_role': asAdmin ? 'admin' : 'user',
      'body': body.trim(),
    });
  }

  Stream<List<TicketMessageModel>> watchTicketMessages(String ticketId) {
    final controller = StreamController<List<TicketMessageModel>>.broadcast();

    getTicketMessages(ticketId).then((msgs) {
      if (!controller.isClosed) controller.add(msgs);
    });

    final channel = _client
        .channel('ticket_msgs_$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_ticket_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'ticket_id',
            value: ticketId,
          ),
          callback: (_) {
            getTicketMessages(ticketId).then((msgs) {
              if (!controller.isClosed) controller.add(msgs);
            });
          },
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
