import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        PostgresChangeEvent,
        PostgresChangeFilter,
        PostgresChangeFilterType,
        PostgresChangePayload,
        RealtimeChannel,
        Supabase;
import 'package:mleko/services/services.dart';

/// Brojač nepročitanih notifikacija + realtime pretplata.
///
/// Izdvojeno iz `AppState` kao prvi korak split-a god-objecta:
/// ovaj provider poseduje isključivo unread state, debounce timer i
/// realtime kanal na tabeli `notifications`. Nema zavisnost ka auth-u —
/// vlasnik (AppState fasada) poziva [bindUser]/[unbind] pri promeni sesije.
class UnreadNotificationsProvider extends ChangeNotifier {
  UnreadNotificationsProvider({NotificationsService? notificationsService})
      : _notificationsService = notificationsService ?? NotificationsService();

  final NotificationsService _notificationsService;

  RealtimeChannel? _channel;
  Timer? _debounceTimer;
  final StreamController<PostgresChangePayload> _eventsController =
      StreamController<PostgresChangePayload>.broadcast();

  int _unreadCount = 0;
  String? _boundUserId;

  int get unreadCount => _unreadCount;
  String? get boundUserId => _boundUserId;

  /// Stream promena na tabeli notifications za vezanog korisnika.
  /// Omogućava ekranima (npr. NotificationsScreen) da reaguju na promene
  /// bez otvaranja dodatnih Realtime kanala ka serveru.
  Stream<PostgresChangePayload> get events => _eventsController.stream;

  // Test-only pristup debounce timeru (koristi i AppState fasada).
  Timer? get debugDebounceTimer => _debounceTimer;

  // Test-only okidač debounce reload-a (koristi i AppState fasada).
  void scheduleReloadForTesting([
    Duration delay = const Duration(milliseconds: 300),
  ]) =>
      _scheduleReload(delay);

  @visibleForTesting
  Timer? get debounceTimer => _debounceTimer;

  /// Veže provider za korisnika: učitava unread count i otvara realtime kanal.
  /// Idempotentno — ponovni poziv sa istim userId je no-op.
  void bindUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      unbind();
      return;
    }
    if (_boundUserId == userId) return;
    unbind();
    _boundUserId = userId;
    _scheduleReload();
    _subscribe(userId);
  }

  /// Odvezuje korisnika: gasi kanal, timer i resetuje brojač.
  void unbind() {
    _boundUserId = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_channel != null) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
    }
    _channel = null;
    if (_unreadCount != 0) {
      _unreadCount = 0;
      notifyListeners();
    }
  }

  void resetCount() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  void incrementCount() {
    _unreadCount++;
    notifyListeners();
  }

  void decrementCount() {
    if (_unreadCount == 0) return;
    _unreadCount--;
    notifyListeners();
  }

  Future<void> _reload() async {
    final userId = _boundUserId;
    if (userId == null || userId.isEmpty) return;
    _unreadCount = await _notificationsService.getUnreadCount(userId);
    notifyListeners();
  }

  void _scheduleReload([
    Duration delay = const Duration(milliseconds: 300),
  ]) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      final userId = _boundUserId;
      if (userId == null || userId.isEmpty) return;
      try {
        await _reload();
      } catch (e, st) {
        LoggerService.error(
          'Failed to load unread count in debounced notification callback',
          e,
          stackTrace: st,
          extra: {'user_id': userId},
        );
      }
    });
  }

  void _subscribe(String userId) {
    final client = Supabase.instance.client;
    try {
      LoggerService.debug('Subscribing to notifications',
          extra: {'user_id': userId});
      _channel = client
          .channel('notifications-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (!_eventsController.isClosed) {
                _eventsController.add(payload);
              }
              _scheduleReload();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (!_eventsController.isClosed) {
                _eventsController.add(payload);
              }
              _scheduleReload();
            },
          )
          .subscribe();
    } catch (e, st) {
      LoggerService.error(
        'Failed to subscribe to notifications',
        e,
        stackTrace: st,
        extra: {'user_id': userId},
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _eventsController.close();
    if (_channel != null) {
      try {
        Supabase.instance.client.removeChannel(_channel!);
      } catch (_) {}
    }
    super.dispose();
  }
}
