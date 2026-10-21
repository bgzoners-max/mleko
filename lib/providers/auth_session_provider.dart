import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;
import '../models/user_model.dart';
import '../services/auth/auth_service.dart';
import '../services/communication/push_service.dart';
import '../services/core/logger_service.dart';
import '../services/media/image_cache_service.dart';
import 'unread_notifications_provider.dart';

/// Izdvojeni provider za korisničku sesiju, autentifikaciju i stanje prijave.
class AuthSessionProvider extends ChangeNotifier {
  final AuthService _auth;
  final UnreadNotificationsProvider? _unreadNotifications;

  StreamSubscription? _authSubscription;
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
  AuthService get authService => _auth;

  void markPendingEmailVerification() {
    _pendingEmailVerification = true;
  }

  void clearJustConfirmedEmail() {
    _justConfirmedEmail = false;
    notifyListeners();
  }

  void setUserForTesting(UserModel? user) {
    _user = user;
    notifyListeners();
  }

  int get authEventVersion => _authEventVersion;

  bool isCurrentAuthEvent(int authVersion, {required String? expectedUserId}) =>
      _isCurrentAuthEvent(authVersion, expectedUserId: expectedUserId);

  AuthSessionProvider({
    AuthService? authService,
    UnreadNotificationsProvider? unreadNotificationsProvider,
  })  : _auth = authService ?? AuthService(),
        _unreadNotifications = unreadNotificationsProvider {
    _initAuth();
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
        _unreadNotifications?.unbind();
        // Očisti image cache na logout (privatnost + memorija)
        await ImageCacheService().clearAllCaches();
        if (!_isCurrentAuthEvent(authVersion, expectedUserId: null)) return;
      } else {
        final isWebSignupCallback = kIsWeb &&
            (Uri.base.fragment.contains('type=signup') ||
                Uri.base.fragment.contains('type=email') ||
                Uri.base.queryParameters['type'] == 'signup' ||
                Uri.base.queryParameters['type'] == 'email' ||
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
              displayName: (sessionUser?.userMetadata?['display_name'] ??
                      sessionUser?.userMetadata?['full_name'] ??
                      sessionUser?.userMetadata?['name']) as String?,
              profileImageUrl: (sessionUser?.userMetadata?['avatar_url'] ??
                      sessionUser?.userMetadata?['picture']) as String?,
              isGuest: false,
            );
          }
        }

        if (!_isCurrentAuthEvent(authVersion, expectedUserId: sessionUserId)) {
          return;
        }

        _user = resolvedUser;
        if (_user != null && !_user!.isGuest) {
          _unreadNotifications?.bindUser(_user!.id);
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
          _unreadNotifications?.unbind();
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

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _user = await _auth.getCurrentUser();
    notifyListeners();
  }

  /// Ponovo inicijalizuje autentifikacioni prikaz stanja — korisno nakon greške
  /// ili kada se želi prisilno ponovo učitati korisnički profil iz sesije.
  /// Resetuje `_authChecked` i `_user`, a zatim ponovo proverava Supabase sesiju.
  Future<void> reload() async {
    _authChecked = false;
    _user = null;
    _loading = false;
    notifyListeners();
    _initAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(PushService.dispose());
    super.dispose();
  }
}
