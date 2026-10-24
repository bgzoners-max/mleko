import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../firebase_options.dart';
import '../core/logger_service.dart';
import 'local_notification_renderer.dart';
import 'push_router.dart';
import 'push_token_registrar.dart';
import 'push_token_repository.dart';

export 'local_notification_renderer.dart';
export 'push_notification_channels.dart';
export 'push_router.dart';
export 'push_token_registrar.dart';
export 'push_token_repository.dart';

/// Background poruka handler koji se pokreće u odvojenom background isolate-u.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data.isEmpty && message.notification == null) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalNotificationRenderer.instance.initializeBackground();

  // Ako FCM poruka već sadrži 'notification' objekat, sistem ga je prikazao
  if (message.notification != null) return;

  final data = message.data.isNotEmpty ? message.data : <String, dynamic>{};
  final title =
      message.notification?.title ?? data['title'] as String? ?? 'Obaveštenje';
  final body = message.notification?.body ?? data['body'] as String? ?? '';
  final type = data['type'] as String? ?? '';
  final orderId = data['order_id'] as String? ?? '';
  final conversationId = data['conversation_id'] as String? ?? '';

  await LocalNotificationRenderer.instance.showNotification(
    title: title,
    body: body,
    type: type,
    orderId: orderId,
    conversationId: conversationId,
    payloadData: data,
  );
}

/// Glavna ulazna fasada (facade) za push servise u aplikaciji.
/// Delegira logiku na:
/// - [PushTokenRegistrar]: registracija tokena, dozvole, generation counter
/// - [LocalNotificationRenderer]: lokalni prikaz, kanali i računanje ID-ja
/// - [PushRouter]: FCM stream pretplate i ruting
class PushService {
  static final PushService _instance = PushService._();

  factory PushService({
    SupabaseClient? client,
    PushTokenRegistrar? tokenRegistrar,
    LocalNotificationRenderer? notificationRenderer,
    PushRouter? router,
  }) {
    if (client != null ||
        tokenRegistrar != null ||
        notificationRenderer != null ||
        router != null) {
      return PushService._(
        client: client,
        tokenRegistrar: tokenRegistrar,
        notificationRenderer: notificationRenderer,
        router: router,
      );
    }
    return _instance;
  }

  PushService._({
    SupabaseClient? client,
    PushTokenRegistrar? tokenRegistrar,
    LocalNotificationRenderer? notificationRenderer,
    PushRouter? router,
  })  : _customClient = client,
        _tokenRegistrar = tokenRegistrar ??
            PushTokenRegistrar(
              repository: PushTokenRepository(client: client),
            ),
        _notificationRenderer =
            notificationRenderer ?? LocalNotificationRenderer.instance,
        _router = router ??
            PushRouter(
              renderer:
                  notificationRenderer ?? LocalNotificationRenderer.instance,
            );

  /// Konstruktor namenjen isključivo jediničnom testiranju uz injektovane mock komponente.
  @visibleForTesting
  PushService.forTesting({
    required PushTokenRegistrar tokenRegistrar,
    required PushRouter router,
    LocalNotificationRenderer? notificationRenderer,
    SupabaseClient? client,
  })  : _customClient = client,
        _tokenRegistrar = tokenRegistrar,
        _notificationRenderer =
            notificationRenderer ?? LocalNotificationRenderer.instance,
        _router = router;

  final SupabaseClient? _customClient;
  final PushTokenRegistrar _tokenRegistrar;
  final LocalNotificationRenderer _notificationRenderer;
  final PushRouter _router;

  @visibleForTesting
  LocalNotificationRenderer get notificationRenderer => _notificationRenderer;

  @visibleForTesting
  SupabaseClient get debugClient =>
      _customClient ?? Supabase.instance.client;

  @visibleForTesting
  static int get registrationGeneration =>
      PushTokenRegistrar.registrationGeneration;

  @visibleForTesting
  static String? get registeredUserId => PushTokenRegistrar.registeredUserId;

  @visibleForTesting
  static bool isCurrentRegistration(int generation, String userId) =>
      PushTokenRegistrar.isCurrentRegistration(generation, userId);

  @visibleForTesting
  Future<void> removeOtherUsersForInstallation(
    String installationId,
    String userId,
  ) =>
      _tokenRegistrar.removeOtherUsersForInstallation(installationId, userId);

  /// Deterministički ID za lokalna obaveštenja sa podrškom za razdvajanje uzastopnih poruka.
  static int computeNotificationId({
    required String type,
    required String orderId,
    required String title,
    required String body,
    String? notificationId,
    String? conversationId,
    String? createdAt,
  }) =>
      LocalNotificationRenderer.computeNotificationId(
        type: type,
        orderId: orderId,
        title: title,
        body: body,
        notificationId: notificationId,
        conversationId: conversationId,
        createdAt: createdAt,
      );

  /// Jedinstveni identifikator instalacije na uređaju
  static Future<String> getInstallationId() =>
      PushTokenRegistrar.getInstallationId();

  /// Resetuje generaciju registracije i prekida pretplate.
  static Future<void> clearRegistrationState() async {
    await PushTokenRegistrar.clearRegistrationState();
    await PushRouter.cancelMessageSubscriptions();
  }

  /// Oslobađa sve resurse.
  static Future<void> dispose() async {
    await PushTokenRegistrar.dispose();
    await PushRouter.dispose();
  }

  /// Inicijalizacija push kanala i background handlera.
  static Future<void> initialize() async {
    if (kIsWeb) {
      LoggerService.debug('Push service: initialized for Web with in-app & foreground fallback');
      return;
    }
    try {
      await LocalNotificationRenderer.instance.initialize();
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
      LoggerService.debug('Push service initialized successfully');
    } catch (e, st) {
      LoggerService.error('Push service initialization failed', e,
          stackTrace: st);
    }
  }

  /// Provera i zahtev za notifikacijske dozvole.
  static Future<bool> ensureNotificationPermission() =>
      PushTokenRegistrar.ensureNotificationPermission();

  /// Zahtev za isključivanje optimizacije baterije na Androidu.
  static Future<bool> requestIgnoreBatteryOptimizations() =>
      PushTokenRegistrar.requestIgnoreBatteryOptimizations();

  /// Callback za tap na lokalnu notifikaciju.
  static void setOnNotificationTapped(void Function(Map<String, dynamic>) cb) {
    LocalNotificationRenderer.instance.setOnNotificationTapped(cb);
  }

  /// Registruje FCM token za korisnika.
  Future<void> registerToken(String userId) =>
      _tokenRegistrar.registerToken(userId);

  /// Uklanja FCM token korisnika pri odjavi.
  Future<void> unregisterToken(String userId) =>
      _tokenRegistrar.unregisterToken(userId);

  /// Postavlja handler za poruke kada je app u prvom planu (foreground).
  void setForegroundHandler(void Function(RemoteMessage) handler) =>
      _router.setForegroundHandler(handler);

  /// Postavlja handler za otvaranje poruke iz pozadine (background click).
  void setMessageOpenedHandler(void Function(RemoteMessage) handler) =>
      _router.setMessageOpenedHandler(handler);

  /// Preuzima eventualnu poruku koja je pokrenula aplikaciju.
  Future<RemoteMessage?> getInitialMessage() => _router.getInitialMessage();
}
