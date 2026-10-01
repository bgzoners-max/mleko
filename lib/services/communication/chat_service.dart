import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/app_error.dart';
import '../core/logger_service.dart';
import 'chat_room_manager.dart';
import 'mixins/chat_media_mixin.dart';
import 'mixins/chat_reactions_mixin.dart';
import 'mixins/chat_stats_mixin.dart';
import 'mixins/chat_typing_mixin.dart';

/// Broj poruka u jednoj stranici (najnovijih).
const _kMsgPageSize = 50;

class ChatService
    with ChatReactionsMixin, ChatTypingMixin, ChatMediaMixin, ChatStatsMixin {
  static final ChatService _instance = ChatService._();
  factory ChatService({SupabaseClient? client}) {
    if (client != null) return ChatService._(client: client);
    return _instance;
  }
  ChatService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  SupabaseClient get client => _client;

  @override
  ChatRoomManager get roomManager => _roomManager;

  static const typingStaleThreshold = ChatTypingMixin.typingStaleThreshold;

  static void clearSignedUrlCache() => ChatMediaMixin.clearSignedUrlCache();

  static String? extractChatImagePath(String pathOrUrl) =>
      ChatMediaMixin.extractChatImagePath(pathOrUrl);

  Future<String?> _findConversationId(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
  }) async {
    try {
      var query = _client
          .from('conversations')
          .select('id')
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId);

      if (productId != null) {
        query = query.eq('product_id', productId);
      } else if (adId != null) {
        query = query.eq('ad_id', adId);
      } else {
        query = query.isFilter('product_id', null).isFilter('ad_id', null);
      }

      final existing = await query.maybeSingle();
      return existing?['id'] as String?;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  // ─── Razgovori ─────────────────────────────────────────────────────────────

  /// Pronađi ili kreiraj razgovor između kupca i prodavca vezan za konkretan
  /// proizvod ([productId]) ili oglas ([adId]).
  ///
  /// Svaki proizvod/predmet ima svoj zaseban razgovor.
  /// Polje `orderId` predstavlja kontekst najrelevantnije/poslednje porudžbine
  /// koja se prikazuje u zaglavlju razgovora.
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) async {
    try {
      final shouldUpdateOrderId = orderId != null && updateOrderIdIfPresent;
      final payload = <String, dynamic>{
        'buyer_id': buyerId,
        'seller_id': sellerId,
        if (productId != null) 'product_id': productId,
        if (adId != null) 'ad_id': adId,
        if (shouldUpdateOrderId) 'order_id': orderId,
      };

      final onConflict = productId != null
          ? 'buyer_id,seller_id,product_id'
          : adId != null
              ? 'buyer_id,seller_id,ad_id'
              : 'buyer_id,seller_id';

      final res = await _client
          .from('conversations')
          .upsert(payload, onConflict: onConflict)
          .select('id')
          .single();
      return res['id'] as String;
    } on PostgrestException catch (e, st) {
      LoggerService.warning(
        'Conversation upsert failed, retrying with fetch fallback',
        extra: {'error': e.toString()},
      );
      final existingId = await _findConversationId(
        buyerId,
        sellerId,
        productId: productId,
        adId: adId,
      );
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
          unawaited(_client.removeChannel(channel!));
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

  final ChatRoomManager _roomManager = ChatRoomManager();

  /// Broj trenutno aktivnih deljenih soba za razgovore (za dijagnostiku i testove)
  int get activeConversationRoomCount => _roomManager.activeRoomCount;

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

    final room = _roomManager.getOrCreateRoom(_client, conversationId);
    room.refCount++;
    room.onMessageCallbacks.add(onMessageEvent);

    refreshSub = refreshTrigger?.listen((_) => fullFetch());

    controller.onCancel = () {
      refreshSub?.cancel();
      room.onMessageCallbacks.remove(onMessageEvent);
      _roomManager.releaseRoom(_client, conversationId);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
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

  /// Dohvata kompletne informacije o razgovoru sa imenima učesnika i podacima o predmetu/proizvodu.
  Future<
      ({
        String? id,
        String? buyerId,
        String? sellerId,
        String? orderId,
        String? productId,
        String? adId,
        String? itemTitle,
        String? itemImageUrl,
        double? itemPrice,
        String? itemUnit,
        String? itemType,
        String buyerName,
        String sellerName,
      })> getConversationInfoWithProfiles(String conversationId) async {
    try {
      final result = await _client.rpc(
        'get_conversation_info_with_profile',
        params: {'p_conversation_id': conversationId},
      );

      if (result == null || (result as List).isEmpty) {
        return (
          id: null,
          buyerId: null,
          sellerId: null,
          orderId: null,
          productId: null,
          adId: null,
          itemTitle: null,
          itemImageUrl: null,
          itemPrice: null,
          itemUnit: null,
          itemType: null,
          buyerName: 'Korisnik',
          sellerName: 'Korisnik'
        );
      }

      final first = result.first;
      final row = first is Map<String, dynamic>
          ? first
          : Map<String, dynamic>.from(first as Map);
      return (
        id: row['id'] as String?,
        buyerId: row['buyer_id'] as String?,
        sellerId: row['seller_id'] as String?,
        orderId: row['order_id'] as String?,
        productId: row['product_id'] as String?,
        adId: row['ad_id'] as String?,
        itemTitle: row['item_title'] as String?,
        itemImageUrl: row['item_image_url'] as String?,
        itemPrice: (row['item_price'] as num?)?.toDouble(),
        itemUnit: row['item_unit'] as String?,
        itemType: row['item_type'] as String?,
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
