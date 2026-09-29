import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bezbedno čuvanje Supabase sesije (access + refresh token) u
/// `flutter_secure_storage` umesto podrazumevanog `SharedPreferences`
/// (plaintext na mobilnim uređajima) ili `localStorage` (web).
///
/// - Android: Keystore-backed enkripcija
/// - iOS/macOS: Keychain
/// - Windows/Linux: libsecret
/// - Web: WebCrypto + localStorage (ograničena zaštita — vidi napomenu ispod)
///
/// Napomena o web-u: `flutter_secure_storage` na web-u i dalje koristi
/// `localStorage` kao backend (uz WebCrypto enkripciju), pa NE štiti od XSS-a
/// (napadač sa izvršavanjem JS-a može pročitati ključ i podatke). Za web je
/// jedina čvrsta zaštita sesije httpOnly cookie na serveru.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({this.persistSessionKey = 'supabase_session'});

  /// Ključ pod kojim se čuva serializovana sesija (ceo JSON: tokeni + user).
  final String persistSessionKey;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    // flutter_secure_storage se inicijalizuje lenjo pri prvom čitanju/pisanju,
    // pa ovde nema potrebe za eksplicitnom pripremom (za razliku od
    // SharedPreferences.getInstance()).
  }

  @override
  Future<bool> hasAccessToken() async {
    final value = await _storage.read(key: persistSessionKey);
    return value != null && value.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    return _storage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _storage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _storage.write(key: persistSessionKey, value: persistSessionString);
  }
}
