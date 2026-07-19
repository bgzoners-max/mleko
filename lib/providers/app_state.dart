import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        AuthChangeEvent,
        AuthState,
        Supabase,
        PostgresChangeEvent,
        PostgresChangeFilter,
        PostgresChangeFilterType,
        RealtimeChannel;
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';
import '../services/media/image_cache_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ConnectivityService _connectivity = ConnectivityService();
  final OrderQueueService _orderQueue = OrderQueueService();
  final OrdersService _ordersService;
  late final SyncManager _syncManager;

  StreamSubscription? _authSubscription;
  late final VoidCallback _connectivityListener;
  RealtimeChannel? _notifChannel;
  int _authEventVersion = 0;

  UserModel? _user;
  bool _authChecked = false;
  bool _loading = false;
  int _unreadNotificationCount = 0;
  bool _pendingEmailVerification = false;
  bool _justConfirmedEmail = false;

  UserModel? get user => _user;
  bool get authChecked => _authChecked;
  bool get isLoading => _loading;
  bool get justConfirmedEmail => _justConfirmedEmail;

  void markPendingEmailVerification() {
    _pendingEmailVerification = true;
  }

  void clearJustConfirmedEmail() {
    _justConfirmedEmail = false;
    notifyListeners();
  }

  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  AuthService get authService => _auth;
  ConnectivityService get connectivity => _connectivity;
  OrderQueueService get orderQueue => _orderQueue;
  SyncManager get syncManager => _syncManager;
  int get unreadNotificationCount => _unreadNotificationCount;

  AppState({required OrdersService ordersService})
      : _ordersService = ordersService {
    _syncManager = SyncManager(
      queueService: _orderQueue,
      ordersService: _ordersService,
      connectivity: _connectivity,
    );

    _initAuth();
    _initConnectivity();
  }

  void _initAuth() {
    _authSubscription =
        _auth.authStateChanges.listen((AuthState authState) async {
      final authVersion = ++_authEventVersion;
      final sessionUserId = authState.session?.user.id;

      if (authState.session == null) {
        await PushService.clearRegistrationState();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: null)) return;
        _user = null;
        _unreadNotificationCount = 0;
        _notifChannel?.unsubscribe();
        _notifChannel = null;
        // Očisti image cache na logout (privatnost + memorija)
        await ImageCacheService().clearAllCaches();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: null)) return;
      } else {
        if (_pendingEmailVerification &&
            authState.event == AuthChangeEvent.signedIn) {
          _justConfirmedEmail = true;
          _pendingEmailVerification = false;
        }

        final resolvedUser = await _auth.getCurrentUser();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: sessionUserId)) {
          return;
        }

        _user = resolvedUser;
        if (_user != null && !_user!.isGuest) {
          // Pokreni registraciju tokena i učitavanje unread count-a paralelno
          await Future.wait([
            PushService().registerToken(_user!.id),
            _loadUnreadCount(),
          ]);

          if (!_isCurrentAuthEvent(authVersion,
              expectedUserId: sessionUserId)) {
            return;
          }
          _subscribeToNotifications();
        } else {
          await PushService.clearRegistrationState();
          if (!_isCurrentAuthEvent(authVersion,
              expectedUserId: sessionUserId)) {
            return;
          }
          _unreadNotificationCount = 0;
          _notifChannel?.unsubscribe();
          _notifChannel = null;
        }
      }
      _authChecked = true;
      notifyListeners();
    });
  }

  bool _isCurrentAuthEvent(int authVersion, {required String? expectedUserId}) {
    if (authVersion != _authEventVersion) return false;
    final currentUserId = Supabase.instance.client.auth.currentSession?.user.id;
    return currentUserId == expectedUserId;
  }

  void _initConnectivity() {
    _connectivityListener = () {
      notifyListeners();
    };
    _connectivity.addListener(_connectivityListener);
  }

  Future<void> _loadUnreadCount() async {
    if (_user == null || _user!.isGuest) return;
    _unreadNotificationCount =
        await NotificationsService().getUnreadCount(_user!.id);
    notifyListeners();
  }

  void _subscribeToNotifications() {
    // Prethodno unsubscribe ako je kanal već aktivan
    _notifChannel?.unsubscribe();
    _notifChannel = null;

    if (_user == null || _user!.isGuest) return;

    final client = Supabase.instance.client;
    final userId = _user!.id;

    // Wrapped callback sa error handling i logging
    Future<void> safeLoadUnreadCount() async {
      try {
        await _loadUnreadCount();
      } catch (e, st) {
        LoggerService.error(
          'Failed to load unread count in notification callback',
          e,
          stackTrace: st,
          extra: {'user_id': userId},
        );
      }
    }

    try {
      LoggerService.debug('Subscribing to notifications',
          extra: {'user_id': userId});
      _notifChannel = client
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
            callback: (_) => safeLoadUnreadCount(),
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
            callback: (_) => safeLoadUnreadCount(),
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

  void resetUnreadCount() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _unreadNotificationCount++;
    notifyListeners();
  }

  void decrementUnreadCount() {
    if (_unreadNotificationCount > 0) {
      _unreadNotificationCount--;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notifChannel?.unsubscribe();
    _connectivity.removeListener(_connectivityListener);
    _connectivity.dispose();
    _syncManager.dispose();
    unawaited(PushService.dispose());
    super.dispose();
  }

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _user = await _auth.getCurrentUser();
    notifyListeners();
  }
}
