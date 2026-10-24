import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_error.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../models/message_reaction_model.dart';
import '../../repositories/chat/chat_repository.dart';
import '../core/logger_service.dart';
import 'chat_room_manager.dart';
import 'realtime_channel_manager.dart';
import 'handlers/chat_media_handler.dart';
import 'handlers/chat_reactions_handler.dart';
import 'handlers/chat_stats_handler.dart';
import 'handlers/chat_typing_handler.dart';

export '../../repositories/chat/chat_repository.dart';
export 'handlers/chat_media_handler.dart';
export 'handlers/chat_reactions_handler.dart';
export 'handlers/chat_stats_handler.dart';
export 'handlers/chat_typing_handler.dart';
export 'mixins/chat_media_mixin.dart';
export 'mixins/chat_reactions_mixin.dart';
export 'mixins/chat_stats_mixin.dart';
export 'mixins/chat_typing_mixin.dart';

/// Broj poruka u jednoj stranici (najnovijih).
const _kMsgPageSize = 50;

/// Servis za ćaskanje baziran na čistoj kompoziciji zavisnosti (Composition over Inheritance).
class ChatService {
  static final ChatService _instance = ChatService._();

  factory ChatService({
    ChatRepository? repository,
    ChatRoomManager? roomManager,
    ChatReactionsHandler? reactionsHandler,
    ChatTypingHandler? typingHandler,
    ChatMediaHandler? mediaHandler,
    ChatStatsHandler? statsHandler,
    SupabaseClient? client,
  }) {
    if (repository != null ||
        roomManager != null ||
        reactionsHandler != null ||
        typingHandler != null ||
        mediaHandler != null ||
        statsHandler != null ||
        client != null) {
      return ChatService._(
        repository: repository,
        roomManager: roomManager,
        reactionsHandler: reactionsHandler,
        typingHandler: typingHandler,
        mediaHandler: mediaHandler,
        statsHandler: statsHandler,
        client: client,
      );
    }
    return _instance;
  }

  ChatService._({
    ChatRepository? repository,
    ChatRoomManager? roomManager,
    ChatReactionsHandler? reactionsHandler,
    ChatTypingHandler? typingHandler,
    ChatMediaHandler? mediaHandler,
    ChatStatsHandler? statsHandler,
    SupabaseClient? client,
  })  : _customClient = client,
        _roomManager = roomManager ?? ChatRoomManager(),
        _repository = repository ?? SupabaseChatRepository(client: client),
        _reactions = reactionsHandler ??
            ChatReactionsHandler(
              client: client,
              roomManager: roomManager ?? ChatRoomManager(),
            ),
        _typing = typingHandler ??
            ChatTypingHandler(
              client: client,
              roomManager: roomManager ?? ChatRoomManager(),
            ),
        _media = mediaHandler ?? ChatMediaHandler(client: client),
        _stats = statsHandler ?? ChatStatsHandler(client: client);

  /// Konstruktor namenjen isključivo jediničnom testiranju uz mockovanje repozitorijuma i hendlera.
  @visibleForTesting
  ChatService.forTesting({
    required ChatRepository repository,
    ChatRoomManager? roomManager,
    ChatReactionsHandler? reactionsHandler,
    ChatTypingHandler? typingHandler,
    ChatMediaHandler? mediaHandler,
    ChatStatsHandler? statsHandler,
    SupabaseClient? client,
  })  : _customClient = client,
        _roomManager = roomManager ?? ChatRoomManager(),
        _repository = repository,
        _reactions = reactionsHandler ??
            ChatReactionsHandler(
              client: client,
              roomManager: roomManager ?? ChatRoomManager(),
            ),
        _typing = typingHandler ??
            ChatTypingHandler(
              client: client,
              roomManager: roomManager ?? ChatRoomManager(),
            ),
        _media = mediaHandler ?? ChatMediaHandler(client: client),
        _stats = statsHandler ?? ChatStatsHandler(client: client);

  final SupabaseClient? _customClient;
  final ChatRoomManager _roomManager;
  final ChatRepository _repository;
  final ChatReactionsHandler _reactions;
  final ChatTypingHandler _typing;
  final ChatMediaHandler _media;
  final ChatStatsHandler _stats;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;
  SupabaseClient get client => _client;

  ChatRoomManager get roomManager => _roomManager;
  ChatRepository get repository => _repository;
  ChatReactionsHandler get reactions => _reactions;
  ChatTypingHandler get typing => _typing;
  ChatMediaHandler get media => _media;
  ChatStatsHandler get stats => _stats;

  static const typingStaleThreshold = ChatTypingHandler.typingStaleThreshold;

  static void clearSignedUrlCache() => ChatMediaHandler.clearSignedUrlCache();

  static String? extractChatImagePath(String pathOrUrl) =>
      ChatMediaHandler.extractChatImagePath(pathOrUrl);

  // ─── Razgovori ─────────────────────────────────────────────────────────────

  Future<String?> findConversationId(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
  }) =>
      _repository.findConversationId(
        buyerId,
        sellerId,
        productId: productId,
        adId: adId,
        orderId: orderId,
      );


  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) =>
      _repository.getOrCreateConversation(
        buyerId,
        sellerId,
        productId: productId,
        adId: adId,
        orderId: orderId,
        updateOrderIdIfPresent: updateOrderIdIfPresent,
      );

  Future<List<ConversationModel>> getConversations(String userId) =>
      _repository.getConversations(userId);

  Future<void> setConversationUserPrefs(
    String conversationId, {
    bool? isFavorite,
    bool? hidden,
  }) =>
      _repository.setConversationUserPrefs(
        conversationId,
        isFavorite: isFavorite,
        hidden: hidden,
      );

  Stream<List<ConversationModel>> watchConversations(
    String userId, {
    Stream<void>? refreshTrigger,
  }) =>
      _repository.watchConversations(
        userId,
        refreshTrigger: refreshTrigger,
      );

  // ─── Poruke ────────────────────────────────────────────────────────────────

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = _kMsgPageSize,
  }) =>
      _repository.getMessages(conversationId, limit: limit);

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

  int get activeConversationRoomCount => _roomManager.activeRoomCount;

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
              currentMessages
                ..add(newMsg)
                ..sort((a, b) {
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
            final idx =
                currentMessages.indexWhere((m) => m.id == updatedMsg.id);
            if (idx != -1) {
              currentMessages[idx] = updatedMsg;
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(currentMessages));
              }
              return;
            }
          }
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          final id =
              (payload.oldRecord['id'] ?? payload.newRecord['id']) as String?;
          if (id != null) {
            currentMessages.removeWhere((m) => m.id == id);
            if (!controller.isClosed) {
              controller.add(List.unmodifiable(currentMessages));
            }
            return;
          }
        }
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

  Future<void> sendMessage(
    String conversationId,
    String senderId,
    String body, {
    String? imageUrl,
  }) =>
      _repository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        body: body,
        imageUrl: imageUrl,
      );

  Future<void> deleteMessage(String messageId) async {
    try {
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

      await _client
          .from('messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUserId);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> markAsRead(
    String conversationId,
    String currentUserId, {
    int limit = 200,
  }) async {
    try {
      try {
        await _client.rpc(
          'mark_conversation_read',
          params: {
            'p_conversation_id': conversationId,
            'p_limit': limit,
          },
        );
        return;
      } on PostgrestException catch (e) {
        if (e.code != '42883') rethrow;
      }

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

      final unreadRows = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .isFilter('read_at', null)
          .order('created_at', ascending: false)
          .limit(limit);

      final unreadIds = (unreadRows as List)
          .map((r) => r['id'] as String?)
          .whereType<String>()
          .toList();

      if (unreadIds.isNotEmpty) {
        await _client
            .from('messages')
            .update({'read_at': DateTime.now().toIso8601String()})
            .inFilter('id', unreadIds);
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  // ─── Komponovane reakcije, kuckanje, mediji i statistika ──────────────────

  Future<List<MessageReactionModel>> getMessageReactions(
    String conversationId,
    String currentUserId,
  ) =>
      _reactions.getMessageReactions(conversationId, currentUserId);

  Stream<List<MessageReactionModel>> watchMessageReactions(
    String conversationId,
    String currentUserId,
  ) =>
      _reactions.watchMessageReactions(conversationId, currentUserId);

  Future<void> toggleMessageReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String reaction,
  }) =>
      _reactions.toggleMessageReaction(
        conversationId: conversationId,
        messageId: messageId,
        userId: userId,
        reaction: reaction,
      );

  Stream<Set<String>> watchTypingUsers(String conversationId) =>
      _typing.watchTypingUsers(conversationId);

  Future<void> setTyping({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) =>
      _typing.setTyping(
        conversationId: conversationId,
        userId: userId,
        isTyping: isTyping,
      );

  Future<String> getSignedChatImageUrl(String pathOrUrl) =>
      _media.getSignedChatImageUrl(pathOrUrl);

  Future<String> uploadMessageImage(
    String conversationId,
    String userId,
    List<int> bytes,
  ) =>
      _media.uploadMessageImage(conversationId, userId, bytes);

  Future<SellerResponseStats> getSellerResponseStats(String sellerId) =>
      _stats.getSellerResponseStats(sellerId);

  // ─── Info o razgovoru ──────────────────────────────────────────────────────

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

  /// Odjavljuje sve aktivne sobe i čisti Realtime kanale (npr. pri odjavi korisnika ili gašenju aplikacije).
  Future<void> cleanUp() async {
    try {
      await _roomManager.releaseAll(_client);
      await RealtimeChannelManager().releaseAll(_client);
    } catch (e) {
      LoggerService.warning(
        'Failed to clean up chat realtime channels',
        extra: {'error': e.toString()},
      );
    }
  }

  /// Alias za [cleanUp] u skladu sa standardnim lifecycle obrascem.
  Future<void> dispose() => cleanUp();
}
