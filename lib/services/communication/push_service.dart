import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notification_types.dart';
import '../core/logger_service.dart';

const _channelId = 'mleko_urgent';
const _channelName = 'Hitno';

const _ordersChannelId = 'orders_high';
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
}) {
  final isOrder = notificationTypeIsOrderRelated(type);
  final channelId = isOrder ? _ordersChannelId : _channelId;
  final channelName = isOrder ? _ordersChannelName : _channelName;
  final payload = jsonEncode({'type': type, 'order_id': orderId});

  // Jedinstveni ID baziran na payload + vreme za izbegavanje kolizija
  final notificationId = Object.hashAll(
    [type, orderId, DateTime.now().microsecondsSinceEpoch],
  ).remainder(2147483647).abs();

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

  _localNotifications.show(
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
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  ).catchError((e, st) {
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
  await Firebase.initializeApp();
  // Inicijalizuj local notifications samo ako nije već inicijalizovano
  if (!_isLocalNotificationsInitialized()) {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android),
    );
    _setLocalNotificationsInitialized();
  }

  final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_defaultChannel);
  await androidPlugin?.createNotificationChannel(_ordersChannel);

  // Preuzmi podatke - iz notifikacije ili iz data payload-a
  final data = message.data.isNotEmpty ? message.data : <String, dynamic>{};
  final title = message.notification?.title ?? data['title'] as String? ?? 'Obaveštenje';
  final body = message.notification?.body ?? data['body'] as String? ?? '';
  final type = data['type'] as String? ?? '';
  final orderId = data['order_id'] as String? ?? '';

  // Prikaži lokalnu notifikaciju sa pravilnim kanalom
  _showLocalNotification(
      title: title, body: body, type: type, orderId: orderId);
}

class PushService {
  final _client = Supabase.instance.client;

  // Ovi listener-i moraju imati životni ciklus, da ne dođe do duplih listen-ova
  // (npr. pri login/logout-u) i registracije tokena za pogrešan korisnika.
  static StreamSubscription<String>? _onTokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static void Function(RemoteMessage)? _foregroundHandler;
  static void Function(RemoteMessage)? _messageOpenedHandler;

  static bool _localNotificationsInitialized = false;

  static Future<void> _cancelSub<T>(StreamSubscription<T>? sub) async {
    await sub?.cancel();
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_localNotificationsInitialized) return;

    try {
      // Zajedničke postavke
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');

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
      LoggerService.debug('PushService: STARTING token registration', extra: {'user_id': userId});
      final granted = await ensureNotificationPermission();
      LoggerService.debug('PushService: Permission check', extra: {'granted': granted});
      if (!granted) {
        LoggerService.warning('PushService: Notification permission DENIED');
        return;
      }
      var token = await FirebaseMessaging.instance.getToken();
      final hasToken = token?.isNotEmpty ?? false;
      LoggerService.debug('PushService: Got initial token',
          extra: {'has_token': hasToken, 'token_preview': token?.substring(0, 20)});

      // Retry logika - ako je null, probaj do 3 puta
      int retries = 0;
      while ((token == null || token.isEmpty) && retries < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        token = await FirebaseMessaging.instance.getToken();
        retries++;
      }

      if (token == null || token.isEmpty) {
        LoggerService.warning(
          'PushService: getToken returned NULL/EMPTY after retries',
          extra: {'retries': retries, 'reason': 'Google Play Services unavailable or Firebase not initialized'},
        );
        return;
      }
      LoggerService.debug('PushService: Got valid token, uploading to database');

      final platform = Platform.isIOS ? 'ios' : 'android';
      await _client.from('user_push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id,token',
      );

      // Jedan aktivan refresh listener važi za aktuelnog korisnika.
      await _cancelSub(_onTokenRefreshSub);
      _onTokenRefreshSub =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await _client.from('user_push_tokens').upsert(
            {'user_id': userId, 'token': newToken, 'platform': platform},
            onConflict: 'user_id,token',
          );
        } catch (e, st) {
          LoggerService.error('Failed to update refreshed push token', e,
              stackTrace: st);
        }
      });
    } catch (e, st) {
      LoggerService.error('Failed to register push token', e, stackTrace: st);
    }
  }

  /// Ukloni token pri odjavi
  Future<void> unregisterToken(String userId) async {
    if (kIsWeb) return;
    try {
      // Prekini refresh upite pre brisanja tokena.
      await _cancelSub(_onTokenRefreshSub);
      _onTokenRefreshSub = null;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _client
            .from('user_push_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
    } catch (e, st) {
      LoggerService.error('Failed to unregister push token', e, stackTrace: st);
    }
  }

  /// Postavi callback za poruke kada je app u foregroundu
  void setForegroundHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    _foregroundHandler = handler;
    // Pričekaj da se prethodna pretplata prekine pre nego što kreiramo novu
    _cancelSub(_onMessageSub).then((_) {
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
        // Preuzmi podatke - iz notifikacije ili iz data payload-a
        final data = message.data.isNotEmpty ? message.data : <String, dynamic>{};
        final title = message.notification?.title ?? data['title'] as String? ?? 'Obaveštenje';
        final body = message.notification?.body ?? data['body'] as String? ?? '';
        final type = data['type'] as String? ?? '';
        final orderId = data['order_id'] as String? ?? '';

        // Prikaži lokalnu notifikaciju sa pratećim podatcima
        _showLocalNotification(
            title: title, body: body, type: type, orderId: orderId);

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
    _cancelSub(_onMessageOpenedSub).then((_) {
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
