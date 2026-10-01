import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_error.dart';
import '../../../models/message_reaction_model.dart';
import '../../core/logger_service.dart';
import '../chat_room_manager.dart';

mixin ChatReactionsMixin {
  SupabaseClient get client;
  ChatRoomManager get roomManager;

  Future<List<MessageReactionModel>> getMessageReactions(
    String conversationId,
    String currentUserId,
  ) async {
    try {
      final rows = await client
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

    final room = roomManager.getOrCreateRoom(client, conversationId);
    room.refCount++;
    void onEvent(PostgresChangePayload _) => refetch();
    room.onReactionCallbacks.add(onEvent);

    controller.onCancel = () {
      room.onReactionCallbacks.remove(onEvent);
      roomManager.releaseRoom(client, conversationId);
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
      final existing = await client
          .from('message_reactions')
          .select('id, reaction')
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        await client.from('message_reactions').insert({
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
        await client.from('message_reactions').delete().eq('id', id);
      } else {
        await client
            .from('message_reactions')
            .update({'reaction': reaction}).eq('id', id);
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
