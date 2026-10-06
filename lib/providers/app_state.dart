import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangePayload;
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';
import 'auth_session_provider.dart';
import 'sync_provider.dart';
import 'unread_notifications_provider.dart';

/// Kompozitna fasada preko izdvojenih providera aplikacije:
/// - [AuthSessionProvider]: korisnička sesija, tokeni, profil, login/logout
/// - [SyncProvider]: offline status, sync manager, red čekanja porudžbina
/// - [UnreadNotificationsProvider]: brojač, debounce i realtime kanal notifikacija
///
/// Svi postojeći pozivaoci (`context.watch<AppState>().user`,
/// `appState.syncManager`, `appState.incrementUnreadCount()`...) rade bez
/// izmena jer fasada u potpunosti delegira ka unutrašnjim instancama.
class AppState extends ChangeNotifier {
  /// Izdvojeni provider za korisničku sesiju i auth.
  late final AuthSessionProvider authSession;

  /// Izdvojeni provider za offline sinhronizaciju i red čekanja.
  late final SyncProvider sync;

  /// Izdvojeni unread provider — poseduje brojač, debounce i realtime kanal.
  late final UnreadNotificationsProvider unreadNotifications;

  UserModel? get user => authSession.user;
  bool get authChecked => authSession.authChecked;
  bool get isLoading => authSession.isLoading;
  bool get justConfirmedEmail => authSession.justConfirmedEmail;
  AuthService get authService => authSession.authService;

  void markPendingEmailVerification() => authSession.markPendingEmailVerification();
  void clearJustConfirmedEmail() => authSession.clearJustConfirmedEmail();

  @visibleForTesting
  void setUserForTesting(UserModel? user) => authSession.setUserForTesting(user);

  @visibleForTesting
  int get authEventVersion => authSession.authEventVersion;

  @visibleForTesting
  bool isCurrentAuthEvent(int authVersion, {required String? expectedUserId}) =>
      authSession.isCurrentAuthEvent(authVersion, expectedUserId: expectedUserId);

  Timer? get unreadDebounceTimer => unreadNotifications.debugDebounceTimer;

  @visibleForTesting
  void scheduleLoadUnreadCountForTesting([Duration delay = const Duration(milliseconds: 300)]) =>
      unreadNotifications.scheduleReloadForTesting(delay);

  bool get isOnline => sync.isOnline;
  bool get isOffline => sync.isOffline;
  ConnectivityService get connectivity => sync.connectivity;
  OrderQueueService get orderQueue => sync.orderQueue;
  SyncManager get syncManager => sync.syncManager;

  int get unreadNotificationCount => unreadNotifications.unreadCount;
  Stream<PostgresChangePayload> get notificationEvents => unreadNotifications.events;

  AppState({
    required OrdersService ordersService,
    AuthService? authService,
    UnreadNotificationsProvider? unreadNotificationsProvider,
    AuthSessionProvider? authSessionProvider,
    SyncProvider? syncProvider,
    ConnectivityService? connectivityService,
    OrderQueueService? orderQueueService,
    SyncManager? syncManager,
  }) {
    unreadNotifications =
        unreadNotificationsProvider ?? UnreadNotificationsProvider();

    authSession = authSessionProvider ??
        AuthSessionProvider(
          authService: authService,
          unreadNotificationsProvider: unreadNotifications,
        );

    sync = syncProvider ??
        SyncProvider(
          ordersService: ordersService,
          connectivityService: connectivityService,
          orderQueueService: orderQueueService,
          syncManager: syncManager,
        );

    // Fasada prosleđuje notifikacije svojim listener-ima radi pune kompatibilnosti.
    unreadNotifications.addListener(_forwardChange);
    authSession.addListener(_forwardChange);
    sync.addListener(_forwardChange);
  }

  void _forwardChange() {
    notifyListeners();
  }

  void resetUnreadCount() => unreadNotifications.resetCount();
  void incrementUnreadCount() => unreadNotifications.incrementCount();
  void decrementUnreadCount() => unreadNotifications.decrementCount();

  void setLoading(bool v) => authSession.setLoading(v);
  Future<void> refreshUser() => authSession.refreshUser();

  @override
  void dispose() {
    unreadNotifications.removeListener(_forwardChange);
    authSession.removeListener(_forwardChange);
    sync.removeListener(_forwardChange);

    unreadNotifications.dispose();
    authSession.dispose();
    sync.dispose();
    super.dispose();
  }
}
