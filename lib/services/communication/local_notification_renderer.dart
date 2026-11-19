import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/notification_types.dart';
import '../core/logger_service.dart';
import 'push_notification_channels.dart';

/// Enkapsulira lokalno prikazivanje notifikacija (FlutterLocalNotificationsPlugin),
/// konfiguraciju Android/iOS kanala i računanje determinističkog notification ID-ja.
class LocalNotificationRenderer {
  static final LocalNotificationRenderer instance = LocalNotificationRenderer();

  LocalNotificationRenderer({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;
  void Function(Map<String, dynamic>)? _onNotificationTappedCallback;

  bool get isInitialized => _isInitialized;

  @visibleForTesting
  set isInitializedForTesting(bool val) => _isInitialized = val;

  /// Postavlja callback funkciju koja se poziva kada korisnik klikne na lokalnu notifikaciju.
  void setOnNotificationTapped(void Function(Map<String, dynamic>) cb) {
    _onNotificationTappedCallback = cb;
  }

  void _onNotificationTapped(NotificationResponse response) {
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
        extra: {
          'payload_len': payload.length,
          'payload_sample':
              payload.length > 200 ? payload.substring(0, 200) : payload,
        },
      );
    }
  }

  /// Inicijalizacija u foreground kontekstu.
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;

    try {
      const android = AndroidInitializationSettings('@drawable/ic_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      if (Platform.isAndroid) {
        await _plugin.initialize(
          settings: const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(defaultPushChannel);
        await androidPlugin?.createNotificationChannel(ordersPushChannel);
      } else if (Platform.isIOS) {
        await _plugin.initialize(
          settings: const InitializationSettings(iOS: darwin),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      } else {
        await _plugin.initialize(
          settings: const InitializationSettings(android: android),
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      }

      _isInitialized = true;
      LoggerService.debug('LocalNotificationRenderer initialized successfully');
    } catch (e, st) {
      LoggerService.error('LocalNotificationRenderer initialization failed', e,
          stackTrace: st);
    }
  }

  /// Inicijalizacija za background isolate.
  Future<void> initializeBackground() async {
    if (kIsWeb || _isInitialized) return;

    try {
      const android = AndroidInitializationSettings('@drawable/ic_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(defaultPushChannel);
      await androidPlugin?.createNotificationChannel(ordersPushChannel);

      _isInitialized = true;
    } catch (e, st) {
      LoggerService.error('LocalNotificationRenderer background init failed', e,
          stackTrace: st);
    }
  }

  /// Deterministički 31-bitni FNV-1a heš preko UTF-8 bajtova.
  ///
  /// Za razliku od `Object.hash(...)`, identičan je u svim Dart izolatima
  /// (foreground i FCM background handler), pa deduplikacija radi pouzdano.
  static int _fnv1a31(String input) {
    const int fnvOffsetBasis = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    var hash = fnvOffsetBasis;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return (hash & 0x7FFFFFFF) % 2147483647;
  }

  /// Deterministički ID za lokalna obaveštenja:
  /// - Ako postoji [notificationId] (iz DB zapisa), garantuje dedup za isti retry event,
  ///   dok različite poruke dobijaju različite ID-eve.
  /// - Ako [notificationId] nije prosleđen, koristi kombinaciju [type], [orderId],
  ///   [conversationId], [createdAt], [title] i [body] da se uzastopne poruke
  ///   istog pošiljaoca ("Nova poruka") ne bi stapale u jednu u Android tray-u.
  static int computeNotificationId({
    required String type,
    required String orderId,
    required String title,
    required String body,
    String? notificationId,
    String? conversationId,
    String? createdAt,
  }) {
    if (notificationId != null && notificationId.isNotEmpty) {
      return _fnv1a31('db_notif\x00$notificationId');
    }
    return _fnv1a31(
      '$type\x00$orderId\x00${conversationId ?? ''}\x00${createdAt ?? ''}\x00$title\x00$body',
    );
  }

  /// Prikazuje lokalno obaveštenje u sistemskom tray-u.
  Future<void> showNotification({
    required String title,
    required String body,
    required String type,
    required String orderId,
    required String conversationId,
    required Map<String, dynamic> payloadData,
  }) async {
    final isOrder = notificationTypeIsOrderRelated(type);
    final channel = isOrder ? ordersPushChannel : defaultPushChannel;

    final payload = jsonEncode({
      ...payloadData,
      'type': type,
      'order_id': orderId,
      'conversation_id': conversationId,
    });

    final notificationId = computeNotificationId(
      type: type,
      orderId: orderId,
      title: title,
      body: body,
      notificationId: payloadData['notification_id'] as String?,
      conversationId: conversationId.isNotEmpty
          ? conversationId
          : payloadData['conversation_id'] as String?,
      createdAt: payloadData['created_at'] as String?,
    );

    LoggerService.debug(
      'Prikazi lokalnu notifikaciju',
      extra: {
        'title': title,
        'body': body,
        'type': type,
        'channelId': channel.id,
        'channelName': channel.name,
        'notificationId': notificationId,
      },
    );

    try {
      await _plugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
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
            styleInformation: BigTextStyleInformation(body),
            icon: 'ic_notification',
            color: const Color(0xFF245938),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e, st) {
      LoggerService.error(
        'Greška pri prikazu notifikacije',
        e,
        stackTrace: st,
        extra: {'title': title, 'channelId': channel.id},
      );
    }
  }
}
