import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'logger_service.dart';

/// Broj poruka u jednoj stranici (najnovijih).
const _kMsgPageSize = 50;

class ChatService {
  final _client = Supabase.instance.client;

  // ─── Razgovori ─────────────────────────────────────────────────────────────

  /// Pronađi ili kreiraj razgovor između kupca i prodavca.
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? orderId,
  }) async {
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    if (existing != null) {
      final id = existing['id'] as String;
      if (orderId != null) {
        await _client
            .from('conversations')
            .update({'order_id': orderId}).eq('id', id);
      }
      return id;
    }
    final res = await _client
        .from('conversations')
        .insert({
          'buyer_id': buyerId,
          'seller_id': sellerId,
          if (orderId != null) 'order_id': orderId,
        })
        .select('id')
        .single();
    return res['id'] as String;
  }

  /// Učitava razgovore koristeći get_conversations_for_user RPC.
  /// Jedan round-trip umesto prethodnih 3N poziva
  /// (profil + poslednja poruka + nepročitane po razgovoru).
  Future<List<ConversationModel>> getConversations(String userId) async {
    final result = await _client.rpc(
      'get_conversations_for_user',
      params: {'p_user_id': userId},
    );
    final list = result as List? ?? [];
    return list
        .map((e) => ConversationModel.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Stream<List<ConversationModel>> watchConversations(
    String userId, {
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<List<ConversationModel>>.broadcast();
    StreamSubscription? refreshSub;
    RealtimeChannel? channel;
    List<String> lastConvIds = [];

    Future<void> refetch() async {
      try {
        final list = await getConversations(userId);
        if (!controller.isClosed) controller.add(list);

        final convIds = list.map((c) => c.id).toList();
        final idsChanged = lastConvIds.length != convIds.length ||
            !Set.of(lastConvIds).containsAll(convIds);
        if (idsChanged && channel != null) {
          lastConvIds = convIds;
          _client.removeChannel(channel!);
          channel = _subscribeConversations(userId, convIds, refetch);
          channel!.subscribe();
        } else {
          lastConvIds = convIds;
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch conversations', e, stackTrace: st);
      }
    }

    void initChannel() {
      refetch().then((_) {
        if (controller.isClosed) return;
        channel = _subscribeConversations(userId, lastConvIds, refetch);
        channel!.subscribe();
      });
    }

    initChannel();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      if (channel != null) _client.removeChannel(channel!);
    };

    return controller.stream;
  }

  RealtimeChannel _subscribeConversations(
    String userId,
    List<String> convIds,
    void Function() onEvent,
  ) {
    final ch = _client.channel('conversations-$userId');
    ch
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buyer_id',
            value: userId,
          ),
          callback: (_) => onEvent(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: userId,
          ),
          callback: (_) => onEvent(),
        );
    if (convIds.isNotEmpty) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.inFilter,
          column: 'conversation_id',
          value: convIds,
        ),
        callback: (_) => onEvent(),
      );
    }
    return ch;
  }

  // ─── Poruke ────────────────────────────────────────────────────────────────

  /// Učitava najnovijih [limit] poruka u razgovoru, sortirano uzlazno za prikaz.
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = _kMsgPageSize,
  }) async {
    final list = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);
    // Baza vraća DESC, UI prikazuje ASC (novije na dnu)
    return (list as List)
        .reversed
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Poruke starije od [before] — za paginaciju "učitaj starije".
  Future<List<MessageModel>> getOlderMessages(
    String conversationId, {
    required DateTime before,
    int limit = _kMsgPageSize,
  }) async {
    final list = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .lt('created_at', before.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (list as List)
        .reversed
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<MessageModel>> watchMessages(
    String conversationId, {
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<List<MessageModel>>.broadcast();
    StreamSubscription? refreshSub;

    Future<void> refetch() async {
      try {
        final list = await getMessages(conversationId);
        if (!controller.isClosed) controller.add(list);
      } catch (e, st) {
        LoggerService.error('Failed to watch messages', e,
            stackTrace: st, extra: {'conversationId': conversationId});
      }
    }

    refetch();

    final channel = _client.channel('messages-$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  // ─── Slanje i čitanje ──────────────────────────────────────────────────────

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String body,
  ) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
    });
  }

  Future<void> markAsRead(
    String conversationId,
    String currentUserId,
  ) async {
    await _client
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .isFilter('read_at', null);
  }

  // ─── Info o razgovoru ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getConversationInfo(
    String conversationId,
  ) async {
    return _client
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .maybeSingle();
  }

  /// Ime druge strane u razgovoru (samo za ChatScreen AppBar).
  Future<String> getOtherPartyName(
    String conversationId,
    String currentUserId,
  ) async {
    final c = await getConversationInfo(conversationId);
    if (c == null) return 'Korisnik';
    final otherId =
        (c['buyer_id'] == currentUserId) ? c['seller_id'] : c['buyer_id'];
    final p = await _client
        .from('profiles')
        .select('farm_name, display_name')
        .eq('id', otherId)
        .maybeSingle();
    if (p == null) return 'Korisnik';
    return (p['farm_name'] ?? p['display_name']) as String? ?? 'Korisnik';
  }
}
