import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_renderer.dart';

/// Upravlja FCM stream pretplatama (foreground poruke, tap na notifikaciju u pozadini,
/// initial deep link poruka) bez trkačkih uslova pri promeni handlera.
class PushRouter {
  PushRouter({LocalNotificationRenderer? renderer})
      : _renderer = renderer ?? LocalNotificationRenderer.instance;

  final LocalNotificationRenderer _renderer;

  // ignore: cancel_subscriptions
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  // ignore: cancel_subscriptions
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static void Function(RemoteMessage)? _foregroundHandler;
  static void Function(RemoteMessage)? _messageOpenedHandler;

  @visibleForTesting
  static bool get isListeningForeground => _onMessageSub != null;

  @visibleForTesting
  static bool get isListeningOpened => _onMessageOpenedSub != null;

  @visibleForTesting
  static bool get hasForegroundHandler => _foregroundHandler != null;

  @visibleForTesting
  static bool get hasMessageOpenedHandler => _messageOpenedHandler != null;

  /// Postavlja ili ažurira callback za poruke dok je aplikacija u prvom planu.
  /// 
  /// Eliminiše trkački uslov (race condition) prethodnog `cancel().then(listen)` koda:
  /// Stream pretplata se kreira jednom i trajno delegira na aktivni [_foregroundHandler],
  /// tako da uzastopni pozivi bezbedno i sinhrono ažuriraju callback bez kidanja pretplate.
  void setForegroundHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    _foregroundHandler = handler;
    _ensureForegroundSubscription();
  }

  void _ensureForegroundSubscription() {
    if (_onMessageSub != null) return;

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) {
      final shouldSkipLocalNotification =
          (Platform.isIOS || Platform.isAndroid) &&
              message.notification != null;

      if (message.notification == null && message.data.isEmpty) return;

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

      if (!shouldSkipLocalNotification) {
        _renderer.showNotification(
          title: title,
          body: body,
          type: type,
          orderId: orderId,
          conversationId: conversationId,
          payloadData: data,
        );
      }

      _foregroundHandler?.call(message);
    });
  }

  /// Postavlja ili ažurira callback za otvaranje aplikacije iz notifikacije (background tap).
  void setMessageOpenedHandler(void Function(RemoteMessage) handler) {
    if (kIsWeb) return;
    _messageOpenedHandler = handler;
    _ensureMessageOpenedSubscription();
  }

  void _ensureMessageOpenedSubscription() {
    if (_onMessageOpenedSub != null) return;

    _onMessageOpenedSub =
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _messageOpenedHandler?.call(message);
    });
  }

  /// Bezbedno i sekvencijalno prekida sve aktivne FCM poruke stream-ove uz `await`.
  static Future<void> cancelMessageSubscriptions() async {
    final oldMessage = _onMessageSub;
    _onMessageSub = null;
    await oldMessage?.cancel();

    final oldOpened = _onMessageOpenedSub;
    _onMessageOpenedSub = null;
    await oldOpened?.cancel();

    _foregroundHandler = null;
    _messageOpenedHandler = null;
  }

  /// Vraća poruku koja je pokrenula aplikaciju (cold start deep link).
  Future<RemoteMessage?> getInitialMessage() async {
    if (kIsWeb) return null;
    return FirebaseMessaging.instance.getInitialMessage();
  }

  /// Oslobađa sve resurse.
  static Future<void> dispose() async {
    await cancelMessageSubscriptions();
  }
}
