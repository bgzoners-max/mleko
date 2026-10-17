import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/logger_service.dart';
import 'push_token_repository.dart';

/// Odgovoran za životni ciklus FCM tokena (preuzimanje, osvežavanje,
/// verifikaciju dozvola, generaciju registracije i sinhronizaciju sa Supabase bazom).
class PushTokenRegistrar {
  PushTokenRegistrar({PushTokenRepository? repository, SupabaseClient? client})
      : _repository = repository ?? PushTokenRepository(client: client);

  final PushTokenRepository _repository;

  static const _installationIdKey = 'mleko_push_installation_id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Uuid _uuid = Uuid();

  static int _registrationGeneration = 0;
  static String? _registeredUserId;
  static StreamSubscription<String>? _onTokenRefreshSub;

  static int get registrationGeneration => _registrationGeneration;
  static String? get registeredUserId => _registeredUserId;

  static bool isCurrentRegistration(int generation, String userId) {
    return generation == _registrationGeneration && _registeredUserId == userId;
  }

  /// Resetuje stanje registracije i prekida refresh pretplate.
  static Future<void> clearRegistrationState() async {
    _registrationGeneration++;
    _registeredUserId = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
  }

  /// Oslobađa resurse.
  static Future<void> dispose() async {
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
  }

  /// Jedinstveni identifikator instalacije na uređaju (koristi se za deduplikaciju i sesije).
  static Future<String> getInstallationId() async {
    try {
      final secureValue = await _secureStorage.read(key: _installationIdKey);
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
    } catch (_) {
      // Fallback na SharedPreferences u slučaju greške secure storage-a
    }

    final prefs = await SharedPreferences.getInstance();
    final prefsValue = prefs.getString(_installationIdKey);
    if (prefsValue != null && prefsValue.isNotEmpty) {
      try {
        await _secureStorage.write(key: _installationIdKey, value: prefsValue);
        await prefs.remove(_installationIdKey);
      } catch (_) {
        // Zadrži prefs ako upis u secure storage ne uspe
      }
      return prefsValue;
    }

    final installationId = _uuid.v4();
    try {
      await _secureStorage.write(
        key: _installationIdKey,
        value: installationId,
      );
    } catch (_) {
      await prefs.setString(_installationIdKey, installationId);
    }
    return installationId;
  }

  /// Proverava i po potrebi zahteva notifikacijske dozvole.
  static Future<bool> ensureNotificationPermission() async {
    if (kIsWeb) return false;
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) return false;
      await Permission.notification.request();
      final newStatus = await Permission.notification.status;
      if (newStatus.isGranted) {
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (e) {
          LoggerService.warning('Firebase permission request failed',
              extra: {'error': e.toString()});
        }
        return true;
      }
      return false;
    }
    return true;
  }

  /// Zahtev za ignorisanje optimizacije baterije (Xiaomi, Huawei, Samsung itd.).
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    await Permission.ignoreBatteryOptimizations.request();
    return (await Permission.ignoreBatteryOptimizations.status).isGranted;
  }

  /// Briše tokene drugih korisnika za istu fizičku instalaciju uređaja.
  Future<void> removeOtherUsersForInstallation(
    String installationId,
    String userId,
  ) =>
      _repository.removeOtherUsersForInstallation(installationId, userId);

  /// Registruje FCM token za korisnika u bazi podataka uz verifikaciju generacije.
  Future<void> registerToken(String userId) async {
    if (kIsWeb) return;
    try {
      final generation = ++_registrationGeneration;
      _registeredUserId = userId;
      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = null;

      final installationId = await getInstallationId();
      if (!isCurrentRegistration(generation, userId)) return;

      LoggerService.debug('PushTokenRegistrar: STARTING token registration',
          extra: {'user_id': userId});

      final granted = await ensureNotificationPermission();
      if (!isCurrentRegistration(generation, userId)) return;
      LoggerService.debug('PushTokenRegistrar: Permission check',
          extra: {'granted': granted});
      if (!granted) {
        LoggerService.warning('PushTokenRegistrar: Notification permission DENIED');
        return;
      }

      var token = await _safeGetToken();
      if (!isCurrentRegistration(generation, userId)) return;
      final hasToken = token?.isNotEmpty ?? false;
      LoggerService.debug('PushTokenRegistrar: Got initial token', extra: {
        'has_token': hasToken,
      });

      // Retry logika sa progresivnim čekanjem
      int retries = 0;
      while ((token == null || token.isEmpty) && retries < 3) {
        await Future.delayed(
            Duration(milliseconds: 500 * pow(2, retries).toInt()));
        token = await _safeGetToken();
        retries++;
        if (!isCurrentRegistration(generation, userId)) return;
      }

      if (token == null || token.isEmpty) {
        LoggerService.warning(
          'PushTokenRegistrar: getToken returned NULL/EMPTY after retries',
          extra: {
            'retries': retries,
            'reason':
                'Google Play Services unavailable or Firebase not initialized'
          },
        );
        return;
      }

      LoggerService.debug(
          'PushTokenRegistrar: Got valid token, uploading to database');

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Prvo očisti stare zapise drugih naloga za ovu instalaciju
      await removeOtherUsersForInstallation(installationId, userId);
      if (!isCurrentRegistration(generation, userId)) return;

      // Inicijalni upsert
      await _upsertTokenToDatabase(userId, installationId, token, platform);

      // Slušalac za automatsko osvežavanje tokena
      _onTokenRefreshSub =
          // ignore: deprecated_member_use
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (!isCurrentRegistration(generation, userId)) return;
        await _upsertTokenToDatabase(
            userId, installationId, newToken, platform);
      });
    } catch (e, st) {
      LoggerService.error('PushTokenRegistrar: Failed to register push token', e,
          stackTrace: st);
    }
  }

  /// Uklanja FCM token korisnika pri odjavi sa uređaja.
  Future<void> unregisterToken(String userId) async {
    if (kIsWeb) return;
    try {
      final generation = ++_registrationGeneration;
      _registeredUserId = null;
      final installationId = await getInstallationId();

      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = null;

      if (generation != _registrationGeneration) return;
      await _repository.deleteUserInstallationTokens(
        userId: userId,
        installationId: installationId,
      );
    } catch (e, st) {
      LoggerService.error('PushTokenRegistrar: Failed to unregister push token', e,
          stackTrace: st);
    }
  }

  Future<void> _upsertTokenToDatabase(String userId, String installationId,
      String token, String platform) async {
    const maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        await _repository.upsertToken(
          userId: userId,
          installationId: installationId,
          token: token,
          platform: platform,
        );
        return;
      } catch (e, st) {
        LoggerService.error(
          'PushTokenRegistrar: Failed to upsert token (attempt ${i + 1}/$maxRetries)',
          e,
          stackTrace: st,
          extra: {
            'userId': userId,
            'platform': platform,
            'retry_attempt': i + 1,
          },
        );
        if (i < maxRetries - 1) {
          await Future.delayed(
              Duration(milliseconds: 1000 * pow(2, i).toInt()));
        }
      }
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int apnsRetries = 0;
        while (apnsToken == null && apnsRetries < 5) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          apnsRetries++;
        }
      }
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      LoggerService.warning('PushTokenRegistrar: Failed to fetch token',
          extra: {'error': e.toString()});
      return null;
    }
  }
}
