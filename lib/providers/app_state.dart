import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, PostgresChangePayload;
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';
import '../services/media/image_cache_service.dart';
import 'unread_notifications_provider.dart';

/// Fasada preko novih izdvojenih providera — javni API ostaje nepromenjen.
///
/// Korak 1 split-a god-objecta:
/// - unread state + realtime kanal → [UnreadNotificationsProvider]
/// - auth / connectivity / sync ostaju ovde dok se ne izdvoje u koraku 2
///   (AuthSessionProvider, SyncProvider).
///
/// Svi postojeći pozivaoci (`context.watch<AppState>().user`,
/// `appState.syncManager`, `appState.incrementUnreadCount()`...) rade bez
/// izmena jer fasada delegira ka unutrašnjim instancama.
class AppState extends ChangeNotifier {
  final AuthService _auth;
  final ConnectivityService _connectivity = ConnectivityService();
  final OrderQueueService _orderQueue = OrderQueueService();
  final OrdersService _ordersService;
  late final SyncManager _syncManager;

  /// Izdvojeni unread provider — poseduje brojač, debounce i realtime kanal.
  late final UnreadNotificationsProvider unreadNotifications;

  StreamSubscription? _authSubscription;
  late final VoidCallback _connectivityListener;
  int _authEventVersion = 0;

  UserModel? _user;
  bool _authChecked = false;
  bool _loading = false;
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

  // Test-only pristup debounce timeru izdvojenog providera.
  // Namerno nije @visibleForTesting na strani potrošača jer se koristi
  // i u produkcijskom AppState getteru.
  Timer? get unreadDebounceTimer => unreadNotifications.debugDebounceTimer;

  @visibleForTesting
  void scheduleLoadUnreadCountForTesting([Duration delay = const Duration(milliseconds: 300)]) =>
      unreadNotifications.scheduleReloadForTesting(delay);

  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  AuthService get authService => _auth;
  ConnectivityService get connectivity => _connectivity;
  OrderQueueService get orderQueue => _orderQueue;
  SyncManager get syncManager => _syncManager;

  /// Delegirano ka [UnreadNotificationsProvider] — postojeći pozivaoci
  /// (`watch<AppState>().unreadNotificationCount`) rade bez izmena,
  /// ali više ne izazivaju rebuild celog AppState-a kada se pretplate
  /// direktno na [unreadNotifications].
  int get unreadNotificationCount => unreadNotifications.unreadCount;
  Stream<PostgresChangePayload> get notificationEvents =>
      unreadNotifications.events;

  AppState({
    required OrdersService ordersService,
    AuthService? authService,
    UnreadNotificationsProvider? unreadNotificationsProvider,
  })  : _auth = authService ?? AuthService(),
        _ordersService = ordersService {
    unreadNotifications =
        unreadNotificationsProvider ?? UnreadNotificationsProvider();
    // Fasada prosleđuje promene brojača svojim listener-ima radi
    // kompatibilnosti (badge u router-u sluša AppState).
    unreadNotifications.addListener(_forwardUnreadNotifications);
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
        unreadNotifications.unbind();
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
          unreadNotifications.bindUser(_user!.id);
          await PushService().registerToken(_user!.id);

          if (!_isCurrentAuthEvent(authVersion,
              expectedUserId: sessionUserId)) {
            return;
          }
        } else {
          await PushService.clearRegistrationState();
          if (!_isCurrentAuthEvent(authVersion,
              expectedUserId: sessionUserId)) {
            return;
          }
          unreadNotifications.unbind();
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

  void resetUnreadCount() => unreadNotifications.resetCount();

  void incrementUnreadCount() => unreadNotifications.incrementCount();

  void decrementUnreadCount() => unreadNotifications.decrementCount();

  void _forwardUnreadNotifications() {
    // Kompatibilnost: postojeći listener-i AppState (badge, main.dart sync)
    // i dalje dobijaju notify kada se brojač promeni u izdvojenom provideru.
    notifyListeners();
  }

  @override
  void dispose() {
    unreadNotifications.removeListener(_forwardUnreadNotifications);
    unreadNotifications.dispose();
    _authSubscription?.cancel();
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
