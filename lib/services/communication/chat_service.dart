import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/message_reaction_model.dart';
import '../core/logger_service.dart';

/// Broj poruka u jednoj stranici (najnovijih).
const _kMsgPageSize = 50;

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;
  ChatService._();

  final _client = Supabase.instance.client;

  static const typingStaleThreshold = Duration(seconds: 6);

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

  Future<void> setConversationUserPrefs(
    String conversationId, {
    bool? isFavorite,
    bool? hidden,
  }) async {
    await _client.rpc(
      'set_conversation_user_prefs',
      params: {
        'p_conversation_id': conversationId,
        'p_is_favorite': isFavorite,
        'p_hidden': hidden,
      },
    );
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
        if (!controller.isClosed) controller.addError(e, st);
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
        if (!controller.isClosed) controller.addError(e, st);
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

  Stream<Set<String>> watchTypingUsers(String conversationId) {
    final controller = StreamController<Set<String>>.broadcast();

    Future<void> refetch() async {
      try {
        final threshold =
            DateTime.now().subtract(typingStaleThreshold).toIso8601String();
        final rows = await _client
            .from('conversation_typing')
            .select('user_id, is_typing, updated_at')
            .eq('conversation_id', conversationId)
            .eq('is_typing', true)
            .gte('updated_at', threshold);

        final users = (rows as List)
            .map((r) => (r as Map<String, dynamic>)['user_id'] as String?)
            .whereType<String>()
            .toSet();
        if (!controller.isClosed) {
          controller.add(users);
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch typing users', e,
            stackTrace: st, extra: {'conversationId': conversationId});
      }
    }

    refetch();

    final channel = _client.channel('typing-$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversation_typing',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    await _client.from('conversation_typing').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<MessageReactionModel>> getMessageReactions(
    String conversationId,
    String currentUserId,
  ) async {
    final rows = await _client
        .from('message_reactions')
        .select('message_id, reaction, user_id')
        .eq('conversation_id', conversationId);

    final byMessageAndEmoji = <String, Map<String, Set<String>>>{};
    for (final row in (rows as List).cast<Map<String, dynamic>>()) {
      final messageId = row['message_id'] as String?;
      final reaction = row['reaction'] as String?;
      final userId = row['user_id'] as String?;
      if (messageId == null || reaction == null || userId == null) {
        continue;
      }

      final emojiMap = byMessageAndEmoji.putIfAbsent(messageId, () => {});
      emojiMap.putIfAbsent(reaction, () => <String>{}).add(userId);
    }

    final result = <MessageReactionModel>[];
    byMessageAndEmoji.forEach((messageId, emojiMap) {
      emojiMap.forEach((emoji, users) {
        result.add(
          MessageReactionModel(
            messageId: messageId,
            reaction: emoji,
            count: users.length,
            reactedByMe: users.contains(currentUserId),
          ),
        );
      });
    });

    return result;
  }

  Stream<List<MessageReactionModel>> watchMessageReactions(
    String conversationId,
    String currentUserId,
  ) {
    final controller = StreamController<List<MessageReactionModel>>.broadcast();

    Future<void> refetch() async {
      try {
        final list = await getMessageReactions(conversationId, currentUserId);
        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch message reactions', e,
            stackTrace: st, extra: {'conversationId': conversationId});
      }
    }

    refetch();

    final channel = _client.channel('reactions-$conversationId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (_) => refetch(),
        )
        .subscribe();

    controller.onCancel = () {
      _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<void> toggleMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    final existing = await _client
        .from('message_reactions')
        .select('id, reaction')
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('message_reactions').insert({
        'conversation_id': conversationId,
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
      });
      return;
    }

    final existingReaction = existing['reaction'] as String?;
    final id = existing['id'] as String;
    if (existingReaction == reaction) {
      await _client.from('message_reactions').delete().eq('id', id);
    } else {
      await _client
          .from('message_reactions')
          .update({'reaction': reaction}).eq('id', id);
    }
  }

  Future<SellerResponseStats> getSellerResponseStats(String sellerId) async {
    final result = await _client.rpc(
      'get_seller_response_time_stats',
      params: {'p_seller_id': sellerId},
    );

    if (result == null) {
      return const SellerResponseStats(
        sampleCount: 0,
        avgResponseMinutes: null,
        medianResponseMinutes: null,
        lastResponseMinutes: null,
      );
    }

    Map<String, dynamic>? json;
    if (result is List && result.isNotEmpty) {
      final first = result.first;
      if (first is Map<String, dynamic>) {
        json = first;
      } else if (first is Map) {
        json = Map<String, dynamic>.from(first);
      }
    } else if (result is Map<String, dynamic>) {
      json = result;
    } else if (result is Map) {
      json = Map<String, dynamic>.from(result);
    }

    if (json == null) {
      return const SellerResponseStats(
        sampleCount: 0,
        avgResponseMinutes: null,
        medianResponseMinutes: null,
        lastResponseMinutes: null,
      );
    }
    return SellerResponseStats.fromJson(json);
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

  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
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

  /// Dohvata kompletne informacije o razgovoru sa imenima učesnika (jednom RPC-om)
  Future<({
    String? id,
    String? buyerId,
    String? sellerId,
    String? orderId,
    String buyerName,
    String sellerName,
  })> getConversationInfoWithProfiles(String conversationId) async {
    try {
      final result = await _client.rpc(
        'get_conversation_info_with_profile',
        params: {'p_conversation_id': conversationId},
      );

      if (result == null) {
        return (id: null, buyerId: null, sellerId: null, orderId: null, buyerName: 'Korisnik', sellerName: 'Korisnik');
      }

      final row = (result as List).first as Map<String, dynamic>;
      return (
        id: row['id'] as String?,
        buyerId: row['buyer_id'] as String?,
        sellerId: row['seller_id'] as String?,
        orderId: row['order_id'] as String?,
        buyerName: (row['buyer_name'] as String?) ?? 'Kupac',
        sellerName: (row['seller_name'] as String?) ?? 'Prodavac',
      );
    } catch (e, st) {
      LoggerService.error('Failed to load conversation info with profiles', e, stackTrace: st);
      return (id: null, buyerId: null, sellerId: null, orderId: null, buyerName: 'Korisnik', sellerName: 'Korisnik');
    }
  }

  /// Ime druge strane u razgovoru (samo za ChatScreen AppBar).
  Future<String> getOtherPartyName(
    String conversationId,
    String currentUserId,
  ) async {
    final info = await getConversationInfoWithProfiles(conversationId);
    if (info.id == null) return 'Korisnik';

    final isBuyer = info.buyerId == currentUserId;
    return isBuyer ? info.sellerName : info.buyerName;
  }
}
