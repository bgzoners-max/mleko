import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logger_service.dart';

/// Deljena Realtime soba za jedan razgovor.
///
/// Više stream pretplata (poruke, tipkanje, reakcije) deli isti kanal; [refCount]
/// prati broj aktivnih pretplata kako bi se kanal oslobodio tek kada ga niko
/// više ne koristi.
class ConversationRoomSubscription {
  final RealtimeChannel channel;
  int refCount = 0;

  final Set<void Function(PostgresChangePayload payload)> onMessageCallbacks =
      {};
  final Set<void Function(PostgresChangePayload payload)> onTypingCallbacks =
      {};
  final Set<void Function(PostgresChangePayload payload)> onReactionCallbacks =
      {};

  ConversationRoomSubscription(this.channel);
}

/// Upravlja deljenim Realtime kanalima po razgovoru (ref-counted).
///
/// Izdvojeno iz [ChatService] kako servis ne bi bio pretrpan i radi lakšeg
/// nezavisnog testiranja logike soba.
class ChatRoomManager {
  final Map<String, ConversationRoomSubscription> _rooms = {};

  /// Broj trenutno aktivnih deljenih soba (za dijagnostiku i testove).
  int get activeRoomCount => _rooms.length;

  /// Vraća postojeću ili kreira novu sobu za [conversationId] i pokreće
  /// Realtime pretplatu na `messages`, `conversation_typing` i `message_reactions`.
  ConversationRoomSubscription getOrCreateRoom(
    SupabaseClient client,
    String conversationId,
  ) {
    var room = _rooms[conversationId];
    if (room != null) return room;

    final channel = client.channel('conversation-$conversationId');
    room = ConversationRoomSubscription(channel);
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

    _rooms[conversationId] = room;
    return room;
  }

  /// Smanjuje refCount sobe; kada padne na nulu, soba i kanal se oslobađaju.
  void releaseRoom(SupabaseClient client, String conversationId) {
    final room = _rooms[conversationId];
    if (room == null) return;
    room.refCount--;
    if (room.refCount > 0) return;

    _rooms.remove(conversationId);
    try {
      client.removeChannel(room.channel);
    } catch (e) {
      LoggerService.warning('Failed to remove conversation room channel',
          extra: {'conversationId': conversationId, 'error': e.toString()});
    }
  }
}
