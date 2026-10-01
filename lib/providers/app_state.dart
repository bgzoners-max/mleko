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
        PostgresChangePayload,
        RealtimeChannel;
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';
import '../services/media/image_cache_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _auth;
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

  @visibleForTesting
  void setUserForTesting(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  @visibleForTesting
  int get authEventVersion => _authEventVersion;

  @visibleForTesting
  bool isCurrentAuthEvent(int authVersion, {required String? expectedUserId}) =>
      _isCurrentAuthEvent(authVersion, expectedUserId: expectedUserId);

  @visibleForTesting
  Timer? get unreadDebounceTimer => _unreadDebounceTimer;

  @visibleForTesting
  void scheduleLoadUnreadCountForTesting([Duration delay = const Duration(milliseconds: 300)]) =>
      _scheduleLoadUnreadCount(delay);

  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  AuthService get authService => _auth;
  ConnectivityService get connectivity => _connectivity;
  OrderQueueService get orderQueue => _orderQueue;
  SyncManager get syncManager => _syncManager;
  int get unreadNotificationCount => _unreadNotificationCount;

  AppState({required OrdersService ordersService, AuthService? authService})
      : _auth = authService ?? AuthService(),
        _ordersService = ordersService {
    _syncManager = SyncManager(
      queueService: _orderQueue,
      ordersService: _ordersService,
      connectivity: _connectivity,
    );

    _initAuth();
    _initConnectivity();
  }

  void _initAuth() {
    final initialSupabaseUser = _auth.currentSupabaseUser;
    if (initialSupabaseUser != null && !initialSupabaseUser.isAnonymous) {
      _user = UserModel(
        id: initialSupabaseUser.id,
        email: initialSupabaseUser.email,
        displayName:
            initialSupabaseUser.userMetadata?['display_name'] as String?,
        isGuest: false,
      );
      _authChecked = true;
    }

    _authSubscription =
        _auth.authStateChanges.listen((AuthState authState) async {
      final authVersion = ++_authEventVersion;
      final sessionUserId = authState.session?.user.id;

      if (authState.session == null || authState.session?.user.isAnonymous == true) {
        await _auth.ensureCleanSession();
        await PushService.clearRegistrationState();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: null)) return;
        _user = null;
        _unreadNotificationCount = 0;
        _unreadDebounceTimer?.cancel();
        _unreadDebounceTimer = null;
        if (_notifChannel != null) {
          try { unawaited(Supabase.instance.client.removeChannel(_notifChannel!)); } catch (_) {}
        }
        _notifChannel = null;
        // Očisti image cache na logout (privatnost + memorija)
        await ImageCacheService().clearAllCaches();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: null)) return;
      } else {
        final isWebSignupCallback = kIsWeb &&
            (Uri.base.fragment.contains('type=signup') ||
                Uri.base.queryParameters['type'] == 'signup' ||
                Uri.base.fragment.contains('type=email_change') ||
                Uri.base.path.contains('/auth/confirmed'));

        if ((_pendingEmailVerification || isWebSignupCallback) &&
            authState.event == AuthChangeEvent.signedIn) {
          _justConfirmedEmail = true;
          _pendingEmailVerification = false;
        }

        UserModel? resolvedUser;
        try {
          resolvedUser = await _auth.getCurrentUser();
        } catch (e) {
          LoggerService.warning(
            'Failed to load full user profile on auth change',
            extra: {'error': e.toString()},
          );
          if (sessionUserId != null) {
            final sessionUser = authState.session?.user;
            resolvedUser = UserModel(
              id: sessionUserId,
              email: sessionUser?.email,
              displayName:
                  sessionUser?.userMetadata?['display_name'] as String?,
              isGuest: false,
            );
          }
        }

        if (!_isCurrentAuthEvent(authVersion, expectedUserId: sessionUserId)) {
          return;
        }

        _user = resolvedUser;
        if (_user != null && !_user!.isGuest) {
          _scheduleLoadUnreadCount();
          await PushService().registerToken(_user!.id);

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
          _unreadDebounceTimer?.cancel();
          _unreadDebounceTimer = null;
          if (_notifChannel != null) {
            try { unawaited(Supabase.instance.client.removeChannel(_notifChannel!)); } catch (_) {}
          }
          _notifChannel = null;
        }
      }
      _authChecked = true;
      notifyListeners();
    });
  }

  bool _isCurrentAuthEvent(int authVersion, {required String? expectedUserId}) {
    if (authVersion != _authEventVersion) return false;
    final currentUserId = _auth.currentSupabaseUser?.id;
    return currentUserId == expectedUserId;
  }

  void _initConnectivity() {
    _connectivityListener = () {
      notifyListeners();
    };
    _connectivity.addListener(_connectivityListener);
  }

  Timer? _unreadDebounceTimer;
  final StreamController<PostgresChangePayload> _notificationEventsController =
      StreamController<PostgresChangePayload>.broadcast();

  /// Stream promena na tabeli notifications za prijavljenog korisnika.
  /// Omogućava ekranima (poput NotificationsScreen) da reaguju na promene
  /// bez otvaranja dodatnih Realtime kanala ka serveru.
  Stream<PostgresChangePayload> get notificationEvents =>
      _notificationEventsController.stream;

  Future<void> _loadUnreadCount() async {
    if (_user == null || _user!.isGuest) return;
    _unreadNotificationCount =
        await NotificationsService().getUnreadCount(_user!.id);
    notifyListeners();
  }

  void _scheduleLoadUnreadCount([Duration delay = const Duration(milliseconds: 300)]) {
    _unreadDebounceTimer?.cancel();
    _unreadDebounceTimer = Timer(delay, () async {
      final currentUserId = _user?.id;
      if (_user == null || _user!.isGuest || currentUserId == null) return;
      try {
        await _loadUnreadCount();
      } catch (e, st) {
        LoggerService.error(
          'Failed to load unread count in debounced notification callback',
          e,
          stackTrace: st,
          extra: {'user_id': currentUserId},
        );
      }
    });
  }

  void _subscribeToNotifications() {
    // Prethodno unsubscribe ako je kanal već aktivan
    if (_notifChannel != null) {
      try { Supabase.instance.client.removeChannel(_notifChannel!); } catch (_) {}
    }
    _notifChannel = null;

    if (_user == null || _user!.isGuest) return;

    final client = Supabase.instance.client;
    final userId = _user!.id;

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
            callback: (payload) {
              if (!_notificationEventsController.isClosed) {
                _notificationEventsController.add(payload);
              }
              _scheduleLoadUnreadCount();
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
              if (!_notificationEventsController.isClosed) {
                _notificationEventsController.add(payload);
              }
              _scheduleLoadUnreadCount();
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
    _unreadDebounceTimer?.cancel();
    _unreadDebounceTimer = null;
    _notificationEventsController.close();
    _authSubscription?.cancel();
    if (_notifChannel != null) {
      try { Supabase.instance.client.removeChannel(_notifChannel!); } catch (_) {}
    }
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
