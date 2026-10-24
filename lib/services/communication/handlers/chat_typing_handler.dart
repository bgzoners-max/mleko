import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/app_error.dart';
import '../../core/logger_service.dart';
import '../chat_room_manager.dart';

/// Handler za typing indikatore izdvojen iz mixina radi čiste kompozicije.
class ChatTypingHandler {
  final SupabaseClient? _customClient;
  final ChatRoomManager _roomManager;

  ChatTypingHandler({
    SupabaseClient? client,
    ChatRoomManager? roomManager,
  })  : _customClient = client,
        _roomManager = roomManager ?? ChatRoomManager();

  static const typingStaleThreshold = Duration(seconds: 6);

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;
  ChatRoomManager get roomManager => _roomManager;

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
      } catch (e, st) {
        LoggerService.error('Error handling typing payload', e, stackTrace: st);
      }
    }

    fullFetch();

    final room = roomManager.getOrCreateRoom(_client, conversationId);
    room.refCount++;
    room.onTypingCallbacks.add(onTypingEvent);

    cleanupTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (typingUsers.isNotEmpty) fullFetch();
    });

    controller.onCancel = () {
      cleanupTimer?.cancel();
      room.onTypingCallbacks.remove(onTypingEvent);
      roomManager.releaseRoom(_client, conversationId);
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
      }, onConflict: 'conversation_id,user_id');
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
