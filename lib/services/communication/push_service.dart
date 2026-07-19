import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/notification_types.dart';
import '../../firebase_options.dart';
import '../core/logger_service.dart';

const _channelId = 'mleko_urgent_v2';
const _channelName = 'Hitno';

const _ordersChannelId = 'orders_high_v2';
const _ordersChannelName = 'Porudžbine';

const _defaultChannel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: 'Push obaveštenja za poruke',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

const _ordersChannel = AndroidNotificationChannel(
  _ordersChannelId,
  _ordersChannelName,
  description: 'Notifikacije za nove porudžbine i status',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

bool _isLocalNotificationsInitialized() {
  return PushService._localNotificationsInitialized;
}

void _setLocalNotificationsInitialized() {
  PushService._localNotificationsInitialized = true;
}

void _showLocalNotification({
  required String title,
  required String body,
  required String type,
  required String orderId,
  required String conversationId,
  required Map<String, dynamic> payloadData,
}) {
  final isOrder = notificationTypeIsOrderRelated(type);
  final channelId = isOrder ? _ordersChannelId : _channelId;
  final channelName = isOrder ? _ordersChannelName : _channelName;
  // Pakujemo ceo payload da ne bismo izgubili 'route' ili 'conversation_id'
  final payload = jsonEncode({
    ...payloadData,
    'type': type,
    'order_id': orderId,
    'conversation_id': conversationId,
  });

  // Deterministički ID baziran na sadržaju (type, orderId, naslov i telo).
  // Ako ista notifikacija stigne više puta (npr. zbog više tokena ili FCM retry-a),
  // novi ID će biti identičan prethodnom, pa će OS samo ažurirati postojeću
  // notifikaciju u tray-u umesto da pravi vizuelni duplikat.
  final notificationId =
      Object.hash(type, orderId, title, body).remainder(2147483647).abs();

  LoggerService.debug(
    'Prikazi lokalnu notifikaciju',
    extra: {
      'title': title,
      'body': body,
      'type': type,
      'channelId': channelId,
      'channelName': channelName,
      'notificationId': notificationId,
    },
  );

  _localNotifications
      .show(
    id: notificationId,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: isOrder
            ? 'Notifikacije za nove porudžbine i status'
            : 'Push obaveštenja za poruke',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.message,
        ticker: 'Nova obaveštenja',
        styleInformation: const BigTextStyleInformation(''),
        icon: 'ic_notification',
        color: const Color(0xFF1B5E20),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  )
      .catchError((e, st) {
    LoggerService.error(
      'Greška pri prikazu notifikacije',
      e,
      stackTrace: st,
      extra: {'title': title, 'channelId': channelId},
    );
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ignorišemo prazne poruke koje se ponekad šalju kao keep-alive
  if (message.data.isEmpty && message.notification == null) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Inicijalizuj local notifications samo ako nije već inicijalizovano
  if (!_isLocalNotificationsInitialized()) {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
      ),
    );
    _setLocalNotificationsInitialized();
  }

  final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_defaultChannel);
  await androidPlugin?.createNotificationChannel(_ordersChannel);

  // Ako FCM poruka ima notification polje, Android sistem je već prikazao
  // obaveštenje automatski (koristeći android.notification.channel_id koji
  // smo postavili u Edge Function). Ne prikazujemo lokalnu notifikaciju
  // ponovo jer bi to rezultiralo duplikatom.
  // Lokalna notifikacija je potrebna samo za data-only poruke.
  if (message.notification != null) return;

  // Preuzmi podatke iz data payload-a (data-only poruke)
  final data = message.data.isNotEmpty ? message.data : <String, dynamic>{};
  final title =
      message.notification?.title ?? data['title'] as String? ?? 'Obaveštenje';
  final body = message.notification?.body ?? data['body'] as String? ?? '';
  final type = data['type'] as String? ?? '';
  final orderId = data['order_id'] as String? ?? '';
  final conversationId = data['conversation_id'] as String? ?? '';

  // Prikaži lokalnu notifikaciju sa pravilnim kanalom
  _showLocalNotification(
    title: title,
    body: body,
    type: type,
    orderId: orderId,
    conversationId: conversationId,
    payloadData: data,
  );
}

class PushService {
  final _client = Supabase.instance.client;
  static const _installationIdKey = 'mleko_push_installation_id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Uuid _uuid = Uuid();

  // Ovi listener-i moraju imati životni ciklus, da ne dođe do duplih listen-ova
  // (npr. pri login/logout-u) i registracije tokena za pogrešan korisnika.
  static StreamSubscription<String>? _onTokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  static int _registrationGeneration = 0;
  static String? _registeredUserId;

  static void Function(RemoteMessage)? _foregroundHandler;
  static void Function(RemoteMessage)? _messageOpenedHandler;

  static bool _localNotificationsInitialized = false;

  static Future<void> dispose() async {
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = null;
  }

  static Future<String> _getInstallationId() async {
    try {
      final secureValue = await _secureStorage.read(key: _installationIdKey);
      if (secureValue != null && secureValue.isNotEmpty) {
        return secureValue;
      }
    } catch (_) {
      // Fallback below.
    }

    final prefs = await SharedPreferences.getInstance();
    final prefsValue = prefs.getString(_installationIdKey);
    if (prefsValue != null && prefsValue.isNotEmpty) {
      try {
        await _secureStorage.write(key: _installationIdKey, value: prefsValue);
        await prefs.remove(_installationIdKey);
      } catch (_) {
        // Keep the fallback copy if secure storage write fails.
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

  Future<void> _removeOtherUsersForInstallation(
    String installationId,
    String userId,
  ) async {
    await _client
        .from('user_push_tokens')
        .delete()
        .eq('installation_id', installationId)
        .neq('user_id', userId);
  }

  static bool _isCurrentRegistration(int generation, String userId) {
    return generation == _registrationGeneration && _registeredUserId == userId;
  }

  static Future<void> _cancelAllMessageSubscriptions() async {
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onMessageOpenedSub?.cancel();
    _onMessageOpenedSub = null;
  }

  static Future<void> clearRegistrationState() async {
    _registrationGeneration++;
    _registeredUserId = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
    await _cancelAllMessageSubscriptions();
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_localNotificationsInitialized) return;

    try {
      // Zajedničke postavke
      const android =
          AndroidInitializationSettings('@drawable/ic_notification');

      if (Platform.isAndroid) {
        await _localNotifications.initialize(
          settings: const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(_defaultChannel);
        await androidPlugin?.createNotificationChannel(_ordersChannel);

        // Zatraži Android notifikacijske dozvole
        final status = await Permission.notification.status;
        if (status.isDenied || status.isRestricted) {
          await Permission.notification.request();
        }
      } else if (Platform.isIOS) {
        // iOS notifikacijske dozvole i inicijalizacija
        const darwin = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        await _localNotifications.initialize(
          settings: const InitializationSettings(iOS: darwin),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        // Zatraži Firebase notifikacijske dozvole
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else {
        // Fallback za ostatale platforme
        await _localNotifications.initialize(
          settings: const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      }

      // Postavi background handler za primanje notifikacija kada je app u backgroundu
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      _localNotificationsInitialized = true;
      LoggerService.debug('Push service initialized successfully');
    } catch (e, st) {
      LoggerService.error('Push service initialization failed', e,
          stackTrace: st);
    }
  }

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

  /// Za Xiaomi, Huawei, Samsung itd. – isključi optimizaciju baterije
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    await Permission.ignoreBatteryOptimizations.request();
    return (await Permission.ignoreBatteryOptimizations.status).isGranted;
  }

  static void Function(Map<String, dynamic>)? _onNotificationTappedCallback;

  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _onNotificationTappedCallback?.call(data);
    } catch (e, st) {
      final payload = response.payload!;
      LoggerService.error(
        'Failed to parse notification payload',
        e,
        stackTrace: st,
        // Ne loguj ceo payload (može sadržati PII/metadata).
        extra: {
          'payload_len': payload.length,
          'payload_sample':
              payload.length > 200 ? payload.substring(0, 200) : payload,
        },
      );
    }
  }

  static void setOnNotificationTapped(void Function(Map<String, dynamic>) cb) {
    _onNotificationTappedCallback = cb;
  }

  /// Registruj FCM token za trenutnog korisnika
  Future<void> registerToken(String userId) async {
    if (kIsWeb) return;
    try {
      final generation = ++_registrationGeneration;
      _registeredUserId = userId;
      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = null;
      final installationId = await _getInstallationId();
      if (!_isCurrentRegistration(generation, userId)) return;

      LoggerService.debug('PushService: STARTING token registration',
          extra: {'user_id': userId});
      final granted = await ensureNotificationPermission();
      if (!_isCurrentRegistration(generation, userId)) return;
      LoggerService.debug('PushService: Permission check',
          extra: {'granted': granted});
      if (!granted) {
        LoggerService.warning('PushService: Notification permission DENIED');
        return;
      }
      var token = await _safeGetToken();
      if (!_isCurrentRegistration(generation, userId)) return;
      final hasToken = token?.isNotEmpty ?? false;
      LoggerService.debug('PushService: Got initial token', extra: {
        'has_token': hasToken,
      });

      // Retry logika sa progresivnim čekanjem
      int retries = 0;
      while ((token == null || token.isEmpty) && retries < 3) {
        await Future.delayed(
            Duration(milliseconds: 500 * pow(2, retries).toInt()));
        token = await _safeGetToken();
        retries++;
        if (!_isCurrentRegistration(generation, userId)) return;
      }

      if (token == null || token.isEmpty) {
        LoggerService.warning(
          'PushService: getToken returned NULL/EMPTY after retries',
          extra: {
            'retries': retries,
            'reason':
                'Google Play Services unavailable or Firebase not initialized'
          },
        );
        return;
      }
      LoggerService.debug(
          'PushService: Got valid token, uploading to database');

      final platform = Platform.isIOS ? 'ios' : 'android';

      // Prvo očisti stare zapise, pa uradi inicijalni upsert
      await _removeOtherUsersForInstallation(installationId, userId);
      if (!_isCurrentRegistration(generation, userId)) return;
      await _upsertTokenToDatabase(userId, installationId, token, platform);

      // Jedan aktivan refresh listener važi za aktuelnog korisnika.
      _onTokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (!_isCurrentRegistration(generation, userId)) return;
        await _upsertTokenToDatabase(
            userId, installationId, newToken, platform);
      });
    } catch (e, st) {
      LoggerService.error('Failed to register push token', e, stackTrace: st);
    }
  }

  /// Pomoćna metoda za siguran upis tokena u bazu
  Future<void> _upsertTokenToDatabase(String userId, String installationId,
      String token, String platform) async {
    const maxRetries = 3;
    for (int i = 0; i < maxRetries; i++) {
      try {
        await _client.from('user_push_tokens').upsert(
          {
            'user_id': userId,
            'installation_id': installationId,
            'token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,installation_id',
        );
        // Ako je uspešno, izađi iz petlje
        return;
      } catch (e, st) {
        LoggerService.error(
          'PushService: Failed to upsert token to database (attempt ${i + 1}/$maxRetries)',
          e,
          stackTrace: st,
          extra: {
            'userId': userId,
            'platform': platform,
            'retry_attempt': i + 1
          },
        );
        if (i < maxRetries - 1) {
          // Eksponencijalni backoff
          await Future.delayed(
              Duration(milliseconds: 1000 * pow(2, i).toInt()));
        }
      }
    }
  }

  Future<String?> _safeGetToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      LoggerService.warning('PushService: Failed to fetch token',
          extra: {'error': e.toString()});
      return null;
    }
  }

  /// Ukloni token pri odjavi
  Future<void> unregisterToken(String userId) async {
    if (kIsWeb) return;
    try {
      final generation = ++_registrationGeneration;
      _registeredUserId = null;
      final installationId = await _getInstallationId();

      // Prekini refresh upite pre brisanja tokena.
      await _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = null;
      await _cancelAllMessageSubscriptions();

      if (generation != _registrationGeneration) return;
      await _client
          .from('user_push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('installation_id', installationId);
    } catch (e, st) {
      LoggerService.error('Failed to unregister push token', e, stackTrace: st);
    }
  }

  /// Postavi callback za poruke kada je app u foregroundu
  void setForegroundHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    _foregroundHandler = handler;
    // Pričekaj da se prethodna pretplata prekine pre nego što kreiramo novu
    final cancelFuture = _onMessageSub?.cancel() ?? Future<void>.value();
    cancelFuture.then((_) {
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        final shouldSkipLocalNotification =
            (Platform.isIOS || Platform.isAndroid) &&
                message.notification != null;

        // Na Androidu, ako poruka sadrži 'notification' objekat, sistem će je
        // automatski prikazati ako je app u backgroundu. Ako je u foregroundu,
        // mi je prikazujemo lokalno, ali samo ako već nije obrađena.
        if (message.notification == null && message.data.isEmpty) return;

        // Preuzmi podatke - iz notifikacije ili iz data payload-a
        final data =
            message.data.isNotEmpty ? message.data : <String, dynamic>{};
        final title = message.notification?.title ??
            data['title'] as String? ??
            'Obaveštenje';
        final body =
            message.notification?.body ?? data['body'] as String? ?? '';
        final type = data['type'] as String? ?? '';
        final orderId = data['order_id'] as String? ?? '';
        final conversationId = data['conversation_id'] as String? ?? '';

        // Na iOS-u sistem već može prikazati foreground obaveštenje kada
        // poruka sadrži notification payload, pa preskačemo lokalni duplikat.
        if (!shouldSkipLocalNotification) {
          _showLocalNotification(
            title: title,
            body: body,
            type: type,
            orderId: orderId,
            conversationId: conversationId,
            payloadData: data,
          );
        }

        // Pozovi callback
        _foregroundHandler?.call(message);
      });
    });
  }

  /// Postavi callback za tap na notifikaciju (app u backgroundu)
  void setMessageOpenedHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    _messageOpenedHandler = handler;
    // Pričekaj da se prethodna pretplata prekine pre nego što kreiramo novu
    final cancelFuture = _onMessageOpenedSub?.cancel() ?? Future<void>.value();
    cancelFuture.then((_) {
      _onMessageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _messageOpenedHandler?.call(message);
      });
    });
  }

  /// Proveri da li je app pokrenut iz notifikacije
  Future<RemoteMessage?> getInitialMessage() async {
    if (kIsWeb) return null;
    return FirebaseMessaging.instance.getInitialMessage();
  }
}
