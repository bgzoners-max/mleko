import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger_service.dart';

import '../../models/user_model.dart';
import '../../models/app_error.dart';
import '../communication/push_service.dart';
import 'users_service.dart';

class AuthService {
  AuthService({SupabaseClient? client, UsersService? usersService})
      : _customClient = client,
        _users = usersService ?? UsersService(client: client);

  final SupabaseClient? _customClient;
  final UsersService _users;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  String get _authRedirectTo =>
      kIsWeb ? '${Uri.base.origin}/auth/confirmed' : 'io.naseselo.app://auth-callback';

  User? get currentSupabaseUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<AuthState> get authStateChanges {
    try {
      return _client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Proverava trenutnu sesiju i bezbedno odjavljuje zaostale anonimne naloge.
  Future<void> ensureCleanSession() async {
    try {
      final user = _client.auth.currentUser;
      if (user != null && user.isAnonymous) {
        await _client.auth.signOut();
      }
    } catch (e) {
      LoggerService.warning('ensureCleanSession failed', extra: {'error': e.toString()});
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final u = _client.auth.currentUser;
      if (u == null) return null;
      if (u.isAnonymous) {
        // Nalog gosta ne treba da postoji — odjavljujemo zaostalu anonimnu sesiju
        try {
          await _client.auth.signOut();
        } catch (e) {
          LoggerService.warning('signOut anonymous failed', extra: {'error': e.toString()});
        }
        return null;
      }

      final profile = await _users.getUser(u.id);
      if (profile != null) return profile;

      return UserModel(
        id: u.id,
        email: u.email,
        isGuest: false,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _client.auth
          .signInWithPassword(email: email, password: password);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> registerWithEmail(
    String email,
    String password, {
    String? displayName,
    String? phone,
    String? city,
    bool isSeller = false,
    String? farmName,
    String? location,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _authRedirectTo,
        data: {
          'email': email,
          'display_name': displayName,
          'phone': phone,
          'city': city,
          'role': isSeller ? 'seller' : 'buyer',
          'farm_name': farmName,
          'location': location,
        },
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: _authRedirectTo,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.length < 5 || !trimmed.contains('@')) return false;
    try {
      final result = await _client.rpc('check_email_exists',
          params: {'p_email': trimmed});
      return result as bool;
    } catch (e, st) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('prekoračen') ||
          errStr.contains('p0001') ||
          errStr.contains('rate limit')) {
        // Ako je dostignut rate limit, registracija ne treba da bude blokirana;
        // submit korak (signUp) će proveriti jedinstvenost.
        return false;
      }
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final trimmed = phone.trim();
      if (trimmed.length < 6) return false;
      final res = await _client
          .rpc('check_phone_exists', params: {'p_phone': trimmed});
      return res == true;
    } catch (e, st) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('prekoračen') ||
          errStr.contains('p0001') ||
          errStr.contains('rate limit')) {
        return false;
      }
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> signInAsGuest() async {
    // Nalog gosta ne treba da postoji. Ako je zaostao anonimni korisnik, odjavi ga.
    if (_client.auth.currentUser?.isAnonymous == true) {
      try {
        await _client.auth.signOut();
      } catch (e) {
        LoggerService.warning('signOut leftover guest failed', extra: {'error': e.toString()});
      }
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo:
            kIsWeb ? '${Uri.base.origin}/login' : _authRedirectTo,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> signOut() async {
    try {
      final userId = currentSupabaseUser?.id;
      if (userId != null) {
        await PushService().unregisterToken(userId);
      }
    } finally {
      await PushService.clearRegistrationState();
      await _client.auth.signOut();
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _users.upsertProfile(
        user.id,
        displayName: user.displayName,
        phone: user.phone,
        city: user.city,
        role: user.role == UserRole.seller ? 'seller' : 'buyer',
        farmName: user.farmName,
        location: user.location,
        profileImageUrl: user.profileImageUrl,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> switchToSeller({
    required String farmName,
    required String location,
    required String phone,
  }) async {
    try {
      final u = currentSupabaseUser;
      if (u == null) {
        throw AppError(
          message: 'User not logged in',
          userMessage: 'Niste prijavljeni.',
          type: ErrorType.unauthorized,
        );
      }
      await _users.upsertProfile(
        u.id,
        role: 'seller',
        farmName: farmName,
        location: location,
        phone: phone,
        isGuest: false,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}
