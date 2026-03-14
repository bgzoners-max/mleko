import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../communication/push_service.dart';
import 'users_service.dart';

class AuthService {
  final UsersService _users = UsersService();

  User? get currentSupabaseUser => Supabase.instance.client.auth.currentUser;
  Stream<AuthState> get authStateChanges => Supabase.instance.client.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUser() async {
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return null;

    final profile = await _users.getUser(u.id);
    if (profile != null) return profile;

    return UserModel(
      id: u.id,
      email: u.email,
      isGuest: u.isAnonymous,
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
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
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
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
    // Profil se kreira automatski triggerom handle_new_user u Supabase
    // (čita podatke iz user_metadata) - nema RLS problema
  }

  Future<void> signInAsGuest() async {
    await Supabase.instance.client.auth.signInAnonymously();
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      await _users.upsertProfile(u.id, role: 'buyer', isGuest: true);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    final userId = currentSupabaseUser?.id;
    if (userId != null) {
      await PushService().unregisterToken(userId);
    }
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> updateProfile(UserModel user) async {
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
  }

  Future<void> switchToSeller({
    required String farmName,
    required String location,
    required String phone,
  }) async {
    final u = currentSupabaseUser;
    if (u == null) throw Exception('Niste prijavljeni.');
    await _users.upsertProfile(
      u.id,
      role: 'seller',
      farmName: farmName,
      location: location,
      phone: phone,
      isGuest: false,
    );
  }
}
