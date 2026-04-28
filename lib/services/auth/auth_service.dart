import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../models/app_error.dart';
import '../communication/push_service.dart';
import 'users_service.dart';

class AuthService {
  final UsersService _users = UsersService();

  String get _authRedirectTo =>
      kIsWeb ? Uri.base.origin : 'io.naseselo.app://auth-callback';

  User? get currentSupabaseUser => Supabase.instance.client.auth.currentUser;
  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUser() async {
    try {
      final u = Supabase.instance.client.auth.currentUser;
      if (u == null) return null;

      final profile = await _users.getUser(u.id);
      if (profile != null) return profile;

      return UserModel(
        id: u.id,
        email: u.email,
        isGuest: u.isAnonymous,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await Supabase.instance.client.auth
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
      await Supabase.instance.client.auth.signUp(
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
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: _authRedirectTo,
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final result = await Supabase.instance.client.rpc('check_email_exists',
          params: {'p_email': email.trim().toLowerCase()});
      return result as bool;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final trimmed = phone.trim();
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('phone', trimmed)
          .maybeSingle();
      return res != null;
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> signInAsGuest() async {
    try {
      await Supabase.instance.client.auth.signInAnonymously();
      final u = Supabase.instance.client.auth.currentUser;
      if (u != null) {
        await _users.upsertProfile(u.id, role: 'buyer', isGuest: true);
      }
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirectTo,
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
      await Supabase.instance.client.auth.signOut();
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
