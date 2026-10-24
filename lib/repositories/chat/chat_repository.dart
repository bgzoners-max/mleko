import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_error.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../services/core/logger_service.dart';

/// Interfejs za perzistenciju i upite nad razgovorima i porukama.
abstract interface class ChatRepository {
  Future<String?> findConversationId(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
  });

  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  });

  Future<List<ConversationModel>> getConversations(String userId);

  Stream<List<ConversationModel>> watchConversations(
    String userId, {
    Stream<void>? refreshTrigger,
  });

  Future<void> setConversationUserPrefs(
    String conversationId, {
    bool? isFavorite,
    bool? hidden,
  });

  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
  });

  Future<List<MessageModel>> fetchOlderMessages(
    String conversationId, {
    required DateTime before,
    int limit = 50,
  });

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    String? imageUrl,
  });


  Future<void> markAsRead(String conversationId, String currentUserId);
}

/// Supabase implementacija [ChatRepository].
class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient? _customClient;

  SupabaseChatRepository({SupabaseClient? client}) : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<String?> findConversationId(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
  }) async {
    try {
      if (orderId != null) {
        final existingByOrder = await _client
            .from('conversations')
            .select('id')
            .eq('order_id', orderId)
            .maybeSingle();
        if (existingByOrder != null) {
          return existingByOrder['id'] as String?;
        }
      }

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

  @override
  Future<String> getOrCreateConversation(
    String buyerId,
    String sellerId, {
    String? productId,
    String? adId,
    String? orderId,
    bool updateOrderIdIfPresent = true,
  }) async {
    if (buyerId == sellerId) {
      throw AppError(
        message: 'Buyer and seller cannot be the same user',
        userMessage: 'Ne možete započeti razgovor sa samim sobom.',
        type: ErrorType.validation,
      );
    }

    try {
      try {
        final rpcRes = await _client.rpc('get_or_create_conversation', params: {
          'p_buyer_id': buyerId,
          'p_seller_id': sellerId,
          if (productId != null) 'p_product_id': productId,
          if (adId != null) 'p_ad_id': adId,
          if (orderId != null) 'p_order_id': orderId,
          'p_update_order_id': updateOrderIdIfPresent,
        });
        if (rpcRes != null) {
          return rpcRes.toString();
        }
      } on PostgrestException catch (e) {
        if (e.code != '42883' && e.message != 'Not Found') {
          LoggerService.warning(
            'get_or_create_conversation RPC failed, falling back to direct upsert',
            extra: {'error': e.toString(), 'code': e.code},
          );
        }
      }

      final shouldUpdateOrderId = orderId != null && updateOrderIdIfPresent;
      final payload = <String, dynamic>{
        'buyer_id': buyerId,
        'seller_id': sellerId,
        if (productId != null) 'product_id': productId,
        if (adId != null) 'ad_id': adId,
        if (shouldUpdateOrderId) 'order_id': orderId,
      };

      final onConflict = orderId != null
          ? 'order_id'
          : productId != null
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
      final existingId = await findConversationId(
        buyerId,
        sellerId,
        productId: productId,
        adId: adId,
        orderId: orderId,
      );
      if (existingId == null) {
        throw AppError.from(e, stackTrace: st);
      }
      if (orderId != null && updateOrderIdIfPresent) {
        final existingConv = await _client
            .from('conversations')
            .select('order_id')
            .eq('id', existingId)
            .maybeSingle();
        final currentOrderId = existingConv?['order_id'] as String?;
        if (currentOrderId == null) {
          await _client
              .from('conversations')
              .update({'order_id': orderId}).eq('id', existingId);
        }
      }
      return existingId;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  @override
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

  @override
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

  @override
  Stream<List<ConversationModel>> watchConversations(
    String userId, {
    Stream<void>? refreshTrigger,
  }) {
    StreamSubscription? refreshSub;
    RealtimeChannel? channel;
    List<String> lastConvIds = [];
    Timer? debounceTimer;

    late final StreamController<List<ConversationModel>> controller;

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
          channel = _subscribeConversations(userId, convIds, () {
            debounceTimer?.cancel();
            debounceTimer = Timer(const Duration(milliseconds: 300), refetch);
          });
          channel!.subscribe();
        } else {
          lastConvIds = convIds;
        }
      } catch (e, st) {
        LoggerService.error('Failed to watch conversations', e, stackTrace: st);
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    void onEvent() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), refetch);
    }

    controller = StreamController<List<ConversationModel>>.broadcast(
      onListen: () {
        refetch().then((_) {
          if (controller.isClosed) return;
          channel = _subscribeConversations(userId, lastConvIds, onEvent);
          channel!.subscribe();
        });

        refreshSub = refreshTrigger?.listen((_) => refetch());
      },
      onCancel: () {
        debounceTimer?.cancel();
        refreshSub?.cancel();
        if (channel != null) {
          unawaited(_client.removeChannel(channel!));
          channel = null;
        }
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

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

  @override
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
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

  @override
  Future<List<MessageModel>> fetchOlderMessages(
    String conversationId, {
    required DateTime before,
    int limit = 50,
  }) async {
    try {
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
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String body,
    String? imageUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': senderId,
        'body': body,
      };
      if (imageUrl != null) {
        payload['image_url'] = imageUrl;
      }
      await _client.from('messages').insert(payload);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }

  }

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
