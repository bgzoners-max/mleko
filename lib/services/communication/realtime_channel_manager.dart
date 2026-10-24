import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger_service.dart';

/// Predstavlja aktivnu deljenu pretplatu na Realtime kanal sa praćenjem broja referenci.
class SharedChannelSubscription {
  final String name;
  final RealtimeChannel channel;
  int refCount = 0;
  final Set<void Function()> callbacks = {};

  SharedChannelSubscription({
    required this.name,
    required this.channel,
  });
}

/// Upravlja deljenim Realtime kanalima kako bi se izbeglo curenje resursa (leaks),
/// duplirani kanali i prevremeno gašenje kanala koji drugi ekrani/tabovi još koriste.
class RealtimeChannelManager {
  static final RealtimeChannelManager _instance = RealtimeChannelManager._();
  factory RealtimeChannelManager() => _instance;
  RealtimeChannelManager._();

  final Map<String, SharedChannelSubscription> _channels = {};

  /// Broj trenutno aktivnih deljenih kanala (za testove i telemetriju).
  int get activeChannelCount => _channels.length;

  /// Vraća broj referenci za dati kanal (za testove).
  int refCount(String channelName) => _channels[channelName]?.refCount ?? 0;

  /// Registruje slušaoca za [channelName].
  /// Ako kanal već postoji, dodaje callback i uvećava [refCount].
  /// Ako ne postoji, poziva [createChannel], pretplaćuje se i čuva kanal.
  /// Vraća funkciju za odjavu (release).
  void Function() acquire({
    required SupabaseClient client,
    required String channelName,
    required void Function() onEvent,
    required RealtimeChannel Function(
      SupabaseClient client,
      void Function() notifyAll,
    ) createChannel,
  }) {
    var entry = _channels[channelName];
    if (entry != null) {
      entry.refCount++;
      entry.callbacks.add(onEvent);
    } else {
      void notifyAll() {
        final current = _channels[channelName];
        if (current == null) return;
        for (final cb in List.of(current.callbacks)) {
          try {
            cb();
          } catch (e) {
            LoggerService.warning('Error in realtime channel callback',
                extra: {'channel': channelName, 'error': e.toString()});
          }
        }
      }

      final channel = createChannel(client, notifyAll)..subscribe();
      entry = SharedChannelSubscription(
        name: channelName,
        channel: channel,
      )
        ..refCount = 1
        ..callbacks.add(onEvent);
      _channels[channelName] = entry;
    }

    bool released = false;
    return () {
      if (released) return;
      released = true;
      release(client: client, channelName: channelName, onEvent: onEvent);
    };
  }

  /// Smanjuje refCount za kanal i uklanja ga iz Supabase klijenta kada padne na 0.
  void release({
    required SupabaseClient client,
    required String channelName,
    required void Function() onEvent,
  }) {
    final entry = _channels[channelName];
    if (entry == null) return;

    entry.callbacks.remove(onEvent);
    entry.refCount--;

    if (entry.refCount <= 0) {
      _channels.remove(channelName);
      try {
        unawaited(client.removeChannel(entry.channel));
      } catch (e) {
        LoggerService.warning('Failed to remove realtime channel',
            extra: {'channel': channelName, 'error': e.toString()});
      }
    }
  }

  /// Čisti sve kanale (korisno pri odjavi korisnika ili u testovima).
  Future<void> releaseAll(SupabaseClient client) async {
    final list = List.of(_channels.values);
    _channels.clear();
    for (final entry in list) {
      try {
        await client.removeChannel(entry.channel);
      } catch (_) {}
    }
  }
}
