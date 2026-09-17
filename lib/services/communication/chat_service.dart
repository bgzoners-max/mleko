import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/message_reaction_model.dart';
import '../../models/app_error.dart';
import '../core/logger_service.dart';

/// Broj poruka u jednoj stranici (najnovijih).
const _kMsgPageSize = 50;

class ChatService {
  static final ChatService _instance = ChatService._();
  factory ChatService({SupabaseClient? client}) {
    if (client != null) return ChatService._(client: client);
    return _instance;
  }
  ChatService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  static const typingStaleThreshold = Duration(seconds: 6);

  Future<String?> _findConversationId(String buyerId, String sellerId) async {
    try {
      final existing = await _client
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .maybeSingle();
      return existing?['id'] as String?;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  // ─── Razgovori ─────────────────────────────────────────────────────────────

  /// Pronađi ili kreiraj razgovor između kupca i prodavca.
  ///
  /// Razgovor između kupca i prodavca je jedinstven (1-na-1 thread).
  /// Polje `orderId` predstavlja kontekst najrelevantnije/poslednje porudžbine
  /// koja se prikazuje u zaglavlju razgovora.
  /// - Ako je [orderId] prosleđen i [updateOrderIdIfPresent] je true, zaglavlje se
  ///   ažurira na novu porudžbinu.
  /// - Ako [orderId] nije prosleđen, postojeće vezivanje za porudžbinu u bazi se NE briše.
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) async {
    try {
      final shouldUpdateOrderId = orderId != null && updateOrderIdIfPresent;
      final res = await _client
          .from('conversations')
          .upsert(
            {
              'buyer_id': buyerId,
              'seller_id': sellerId,
              if (shouldUpdateOrderId) 'order_id': orderId,
            },
            onConflict: 'buyer_id,seller_id',
          )
          .select('id')
          .single();
      return res['id'] as String;
    } on PostgrestException catch (e, st) {
      LoggerService.warning(
        'Conversation upsert failed, retrying with fetch fallback',
        extra: {'error': e.toString()},
      );
      final existingId = await _findConversationId(buyerId, sellerId);
      if (existingId == null) {
        throw AppError.from(e, stackTrace: st);
      }
      if (orderId != null && updateOrderIdIfPresent) {
        await _client
            .from('conversations')
            .update({'order_id': orderId}).eq('id', existingId);
      }
      return existingId;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Učitava razgovore koristeći get_conversations_for_user RPC.
  Future<List<ConversationModel>> getConversations(String userId) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> setConversationUserPrefs(
    String conversationId, {
    bool? isFavorite,
    bool? hidden,
  }) async {
    try {
      await _client.rpc(
        'set_conversation_user_prefs',
        params: {
          'p_conversation_id': conversationId,
          'p_is_favorite': isFavorite,
          'p_hidden': hidden,
        },
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
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

    Timer? debounceTimer;
    void onEvent() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), refetch);
    }

    void initChannel() {
      refetch().then((_) {
        if (controller.isClosed) return;
        channel = _subscribeConversations(userId, lastConvIds, onEvent);
        channel!.subscribe();
      });
    }

    initChannel();

    refreshSub = refreshTrigger?.listen((_) => refetch());

    controller.onCancel = () {
      debounceTimer?.cancel();
      refreshSub?.cancel();
      if (channel != null) _client.removeChannel(channel!);
      if (!controller.isClosed) {
        controller.close();
      }
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
    try {
      final list = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (list as List)
          .reversed
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Poruke starije od [before] — za paginaciju "učitaj starije".
  /// Koristi keyset paginaciju (created_at, id) radi sprečavanja duplikata i preskakanja.
  Future<List<MessageModel>> getOlderMessages(
    String conversationId, {
    required DateTime before,
    String? beforeId,
    int limit = _kMsgPageSize,
  }) async {
    try {
      final beforeIso = before.toIso8601String();
      var query = _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId);

      if (beforeId != null && beforeId.isNotEmpty) {
        query = query.or(
          'created_at.lt.$beforeIso,and(created_at.eq.$beforeIso,id.lt.$beforeId)',
        );
      } else {
        query = query.lt('created_at', beforeIso);
      }

      final list = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      return (list as List)
          .reversed
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  final Map<String, _ConversationRoomSubscription> _conversationRooms = {};

  /// Broj trenutno aktivnih deljenih soba za razgovore (za dijagnostiku i testove)
  int get activeConversationRoomCount => _conversationRooms.length;

  _ConversationRoomSubscription _getOrCreateConversationRoom(String conversationId) {
    var room = _conversationRooms[conversationId];
    if (room == null) {
      final channel = _client.channel('conversation-$conversationId');
      room = _ConversationRoomSubscription(channel);
      final currentRoom = room;

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
            callback: (payload) {
              for (final cb in List.of(currentRoom.onMessageCallbacks)) {
                cb(payload);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversation_typing',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              for (final cb in List.of(currentRoom.onTypingCallbacks)) {
                cb(payload);
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'message_reactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              for (final cb in List.of(currentRoom.onReactionCallbacks)) {
                cb(payload);
              }
            },
          )
          .subscribe();

      _conversationRooms[conversationId] = room;
    }
    return room;
  }

  void _releaseConversationRoom(String conversationId) {
    final room = _conversationRooms[conversationId];
    if (room == null) return;
    room.refCount--;
    if (room.refCount <= 0) {
      _conversationRooms.remove(conversationId);
      try {
        _client.removeChannel(room.channel);
      } catch (e) {
        LoggerService.warning('Failed to remove conversation room channel',
            extra: {'conversationId': conversationId, 'error': e.toString()});
      }
    }
  }

  /// Prati poruke u razgovoru inkrementalno:
  /// - Pri otvaranju / retry-u radi pun fetch najnovijih poruka.
  /// - Na realtime insert dodaje poruku uz deduplikaciju po ID-u bez ponovnog učitavanja svih 50 poruka.
  /// - Na realtime update / delete inkrementalno ažurira lokalnu listu.
  Stream<List<MessageModel>> watchMessages(
    String conversationId, {
    Stream<void>? refreshTrigger,
  }) {
    final controller = StreamController<List<MessageModel>>.broadcast();
    StreamSubscription? refreshSub;
    final List<MessageModel> currentMessages = [];

    Future<void> fullFetch() async {
      try {
        final list = await getMessages(conversationId);
        currentMessages
          ..clear()
          ..addAll(list);
        if (!controller.isClosed) {
          controller.add(List.unmodifiable(currentMessages));
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch messages', e,
            stackTrace: st, extra: {'conversationId': conversationId});
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    void onMessageEvent(PostgresChangePayload payload) {
      try {
        if (payload.eventType == PostgresChangeEvent.insert) {
          final raw = payload.newRecord;
          if (raw.isNotEmpty) {
            final newMsg = MessageModel.fromJson(raw);
            final exists = currentMessages.any((m) => m.id == newMsg.id);
            if (!exists) {
              currentMessages.add(newMsg);
              currentMessages.sort((a, b) {
                final cmp = a.createdAt.compareTo(b.createdAt);
                if (cmp != 0) return cmp;
                return a.id.compareTo(b.id);
              });
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(currentMessages));
              }
              return;
            }
          }
        } else if (payload.eventType == PostgresChangeEvent.update) {
          final raw = payload.newRecord;
          if (raw.isNotEmpty) {
            final updatedMsg = MessageModel.fromJson(raw);
            final idx = currentMessages.indexWhere((m) => m.id == updatedMsg.id);
            if (idx != -1) {
              currentMessages[idx] = updatedMsg;
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(currentMessages));
              }
              return;
            }
          }
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          final id = (payload.oldRecord['id'] ?? payload.newRecord['id']) as String?;
          if (id != null) {
            currentMessages.removeWhere((m) => m.id == id);
            if (!controller.isClosed) {
              controller.add(List.unmodifiable(currentMessages));
            }
            return;
          }
        }
        // Sigurnosni fallback na pun fetch ako je payload neuobičajen
        fullFetch();
      } catch (_) {
        fullFetch();
      }
    }

    fullFetch();

    final room = _getOrCreateConversationRoom(conversationId);
    room.refCount++;
    room.onMessageCallbacks.add(onMessageEvent);

    refreshSub = refreshTrigger?.listen((_) => fullFetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      room.onMessageCallbacks.remove(onMessageEvent);
      _releaseConversationRoom(conversationId);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  /// Prati korisnike koji kuckaju inkrementalno (payload is_typing).
  Stream<Set<String>> watchTypingUsers(String conversationId) {
    final controller = StreamController<Set<String>>.broadcast();
    final Set<String> typingUsers = {};
    Timer? cleanupTimer;

    Future<void> fullFetch() async {
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
        typingUsers
          ..clear()
          ..addAll(users);
        if (!controller.isClosed) {
          controller.add(Set.unmodifiable(typingUsers));
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch typing users', e,
            stackTrace: st, extra: {'conversationId': conversationId});
      }
    }

    void onTypingEvent(PostgresChangePayload payload) {
      try {
        final record = payload.newRecord;
        final userId = record['user_id'] as String?;
        final isTyping = record['is_typing'] as bool? ?? false;
        if (userId != null) {
          if (isTyping) {
            typingUsers.add(userId);
          } else {
            typingUsers.remove(userId);
          }
          if (!controller.isClosed) {
            controller.add(Set.unmodifiable(typingUsers));
          }
        }
      } catch (_) {
        fullFetch();
      }
    }

    fullFetch();

    final room = _getOrCreateConversationRoom(conversationId);
    room.refCount++;
    room.onTypingCallbacks.add(onTypingEvent);

    cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (typingUsers.isNotEmpty) {
        fullFetch();
      }
    });

    controller.onCancel = () {
      cleanupTimer?.cancel();
      room.onTypingCallbacks.remove(onTypingEvent);
      _releaseConversationRoom(conversationId);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _client.from('conversation_typing').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<MessageReactionModel>> getMessageReactions(
    String conversationId,
    String currentUserId,
  ) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
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

    final room = _getOrCreateConversationRoom(conversationId);
    room.refCount++;
    void onEvent(PostgresChangePayload _) => refetch();
    room.onReactionCallbacks.add(onEvent);

    controller.onCancel = () {
      room.onReactionCallbacks.remove(onEvent);
      _releaseConversationRoom(conversationId);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  Future<void> toggleMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<SellerResponseStats> getSellerResponseStats(String sellerId) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  // ─── Slanje i čitanje ──────────────────────────────────────────────────────

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String body, {
    String? imageUrl,
  }) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'body': body,
        if (imageUrl != null) 'image_url': imageUrl,
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Otprema sliku u namenski chat-images bucket i vraća public URL.
  Future<String> uploadMessageImage(
    String conversationId,
    String userId,
    List<int> bytes,
  ) async {
    try {
      final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$conversationId/$name';

      await _client.storage.from('chat-images').uploadBinary(
            path,
            bytes as dynamic,
            fileOptions:
                const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return _client.storage.from('chat-images').getPublicUrl(path);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      // Security: Proveri da je trenutni korisnik pošiljalac poruke pre brisanja
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AppError(
          message: 'Unauthorized: no authenticated user',
          userMessage: 'Morate biti prijavljeni da biste obrisali poruku.',
          type: ErrorType.unauthorized,
        );
      }
      
      final message = await _client
          .from('messages')
          .select('sender_id')
          .eq('id', messageId)
          .maybeSingle();
      
      if (message == null) {
        throw AppError(
          message: 'Message not found: $messageId',
          userMessage: 'Poruka nije pronađena.',
          type: ErrorType.notFound,
        );
      }
      
      final senderId = message['sender_id'] as String?;
      if (senderId != currentUserId) {
        throw AppError(
          message: 'Unauthorized: only sender can delete their message',
          userMessage: 'Možete obrisati samo svoje poruke.',
          type: ErrorType.forbidden,
        );
      }
      
      await _client.from('messages').delete().eq('id', messageId).eq('sender_id', currentUserId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> markAsRead(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      // Security: Proveri da je korisnik član konverzacije pre označavanja kao pročitano
      final conversation = await _client
          .from('conversations')
          .select('buyer_id, seller_id')
          .eq('id', conversationId)
          .maybeSingle();
      
      if (conversation == null) {
        throw AppError(
          message: 'Conversation not found',
          userMessage: 'Razgovor nije pronađen.',
          type: ErrorType.notFound,
        );
      }
      
      final buyerId = conversation['buyer_id'] as String?;
      final sellerId = conversation['seller_id'] as String?;
      
      if (currentUserId != buyerId && currentUserId != sellerId) {
        throw AppError(
          message: 'Unauthorized: user is not a member of this conversation',
          userMessage: 'Nemate pristup ovom razgovoru.',
          type: ErrorType.forbidden,
        );
      }
      
      await _client
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .isFilter('read_at', null);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  // ─── Info o razgovoru ──────────────────────────────────────────────────────

  /// Dohvata kompletne informacije o razgovoru sa imenima učesnika.
  Future<
      ({
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
        return (
          id: null,
          buyerId: null,
          sellerId: null,
          orderId: null,
          buyerName: 'Korisnik',
          sellerName: 'Korisnik'
        );
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
      throw AppError.from(e, stackTrace: st);
    }
  }

  /// Ime druge strane u razgovoru (samo za ChatScreen AppBar).
  Future<String> getOtherPartyName(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      final info = await getConversationInfoWithProfiles(conversationId);
      if (info.id == null) return 'Korisnik';

      final isBuyer = info.buyerId == currentUserId;
      return isBuyer ? info.sellerName : info.buyerName;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}

class _ConversationRoomSubscription {
  final RealtimeChannel channel;
  int refCount = 0;
  final Set<void Function(PostgresChangePayload payload)> onMessageCallbacks = {};
  final Set<void Function(PostgresChangePayload payload)> onTypingCallbacks = {};
  final Set<void Function(PostgresChangePayload payload)> onReactionCallbacks = {};

  _ConversationRoomSubscription(this.channel);
}
