import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

void _showLocalNotification({
  required String title,
  required String body,
  required String type,
  required String orderId,
}) {
  final isOrder = type == 'new_order' || type == 'order_status';
  final channelId = isOrder ? _ordersChannelId : _channelId;
  final channelName = isOrder ? _ordersChannelName : _channelName;
  final payload = jsonEncode({'type': type, 'order_id': orderId});
  _localNotifications.show(
    DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title,
    body,
    NotificationDetails(
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
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: payload,
  );
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) return;
  await Firebase.initializeApp();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotifications.initialize(
    const InitializationSettings(android: android),
  );
  final androidPlugin =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(_defaultChannel);
  await androidPlugin?.createNotificationChannel(_ordersChannel);
  final data = message.data;
  final title = data['title'] as String? ?? 'Obaveštenje';
  final body = data['body'] as String? ?? '';
  final type = data['type'] as String? ?? '';
  final orderId = data['order_id'] as String? ?? '';
  _showLocalNotification(
      title: title, body: body, type: type, orderId: orderId);
}

class PushService {
  final _client = Supabase.instance.client;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid) {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await _localNotifications.initialize(
          const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(_defaultChannel);
        await androidPlugin?.createNotificationChannel(_ordersChannel);
      } else if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        const darwin = DarwinInitializationSettings();
        await _localNotifications.initialize(
          const InitializationSettings(iOS: darwin),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } else {
        const android = AndroidInitializationSettings('@mipmap/ic_launcher');
        await _localNotifications.initialize(
          const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      }

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
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
      LoggerService.error('Failed to parse notification payload', e,
          stackTrace: st, extra: {'payload': response.payload});
    }
  }

  static void setOnNotificationTapped(void Function(Map<String, dynamic>) cb) {
    _onNotificationTappedCallback = cb;
  }

  /// Registruj FCM token za trenutnog korisnika
  Future<void> registerToken(String userId) async {
    if (kIsWeb) return;
    try {
      final granted = await ensureNotificationPermission();
      if (!granted) {
        debugPrint('PushService: notification permission denied');
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('PushService: getToken returned null/empty');
        return;
      }

      final platform = Platform.isIOS ? 'ios' : 'android';
      await _client.from('user_push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id,token',
      );

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _client.from('user_push_tokens').upsert(
          {'user_id': userId, 'token': newToken, 'platform': platform},
          onConflict: 'user_id,token',
        );
      });
    } catch (e, st) {
      LoggerService.error('Failed to register push token', e, stackTrace: st);
    }
  }

  /// Ukloni token pri odjavi
  Future<void> unregisterToken(String userId) async {
    if (kIsWeb) return;
    try {
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
    FirebaseMessaging.onMessage.listen((message) {
      final data = message.data;
      final title = data['title'] as String? ?? 'Obaveštenje';
      final body = data['body'] as String? ?? '';
      final type = data['type'] as String? ?? '';
      final orderId = data['order_id'] as String? ?? '';
      _showLocalNotification(
          title: title, body: body, type: type, orderId: orderId);
      handler(message);
    });
  }

  /// Postavi callback za tap na notifikaciju (app u backgroundu)
  void setMessageOpenedHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    FirebaseMessaging.onMessageOpenedApp.listen(handler);
  }

  /// Proveri da li je app pokrenut iz notifikacije
  Future<RemoteMessage?> getInitialMessage() async {
    if (kIsWeb) return null;
    return FirebaseMessaging.instance.getInitialMessage();
  }
}
