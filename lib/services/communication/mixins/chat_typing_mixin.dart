import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/app_error.dart';
import '../../core/logger_service.dart';
import '../chat_room_manager.dart';

mixin ChatTypingMixin {
  SupabaseClient get client;
  ChatRoomManager get roomManager;

  static const typingStaleThreshold = Duration(seconds: 6);

  /// Prati korisnike koji kuckaju inkrementalno (payload is_typing).
  Stream<Set<String>> watchTypingUsers(String conversationId) {
    final controller = StreamController<Set<String>>.broadcast();
    final Set<String> typingUsers = {};
    Timer? cleanupTimer;

    Future<void> fullFetch() async {
      try {
        final threshold =
            DateTime.now().subtract(typingStaleThreshold).toIso8601String();
        final rows = await client
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

    final room = roomManager.getOrCreateRoom(client, conversationId);
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
      roomManager.releaseRoom(client, conversationId);
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
      await client.from('conversation_typing').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
