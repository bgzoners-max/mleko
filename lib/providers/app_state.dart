import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType, RealtimeChannel;
import '../models/user_model.dart';
import 'package:mleko/services/services.dart';


class AppState extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ConnectivityService _connectivity = ConnectivityService();
  final OrderQueueService _orderQueue = OrderQueueService();
  final OrdersService _ordersService = OrdersService();
  late final SyncManager _syncManager;

  StreamSubscription? _authSubscription;
  late final VoidCallback _connectivityListener;
  RealtimeChannel? _notifChannel;

  UserModel? _user;
  bool _authChecked = false;
  bool _loading = false;
  int _unreadNotificationCount = 0;

  UserModel? get user => _user;
  bool get authChecked => _authChecked;
  bool get isLoading => _loading;
  bool get isOnline => _connectivity.isOnline;
  bool get isOffline => _connectivity.isOffline;
  AuthService get authService => _auth;
  ConnectivityService get connectivity => _connectivity;
  OrderQueueService get orderQueue => _orderQueue;
  SyncManager get syncManager => _syncManager;
  int get unreadNotificationCount => _unreadNotificationCount;

  AppState() {
    _syncManager = SyncManager(
      queueService: _orderQueue,
      ordersService: _ordersService,
      connectivity: _connectivity,
    );

    _initAuth();
    _initConnectivity();
  }

  void _initAuth() {
    _authSubscription = _auth.authStateChanges.listen((authState) async {
      if (authState.session == null) {
        _user = null;
        _unreadNotificationCount = 0;
        _notifChannel?.unsubscribe();
      } else {
        _user = await _auth.getCurrentUser();
        if (_user != null && !_user!.isGuest) {
          await PushService().registerToken(_user!.id);
          await _loadUnreadCount();
          _subscribeToNotifications();
        }
      }
      _authChecked = true;
      notifyListeners();
    });
  }

  void _initConnectivity() {
    _connectivityListener = () {
      notifyListeners();
    };
    _connectivity.addListener(_connectivityListener);
  }

  Future<void> _loadUnreadCount() async {
    if (_user == null || _user!.isGuest) return;
    _unreadNotificationCount = await NotificationsService().getUnreadCount(_user!.id);
    notifyListeners();
  }

  void _subscribeToNotifications() {
    _notifChannel?.unsubscribe();
    if (_user == null || _user!.isGuest) return;
    final client = Supabase.instance.client;
    _notifChannel = client
        .channel('notifications-${_user!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _user!.id,
          ),
          callback: (_) async {
            await _loadUnreadCount();
          },
        )
        .subscribe();
  }

  void resetUnreadCount() {
    _unreadNotificationCount = 0;
    notifyListeners();
  }

  void incrementUnreadCount() {
    _unreadNotificationCount++;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notifChannel?.unsubscribe();
    _connectivity.removeListener(_connectivityListener);
    _connectivity.dispose();
    _syncManager.dispose();
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

