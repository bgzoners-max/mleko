// import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // unused

// final FlutterLocalNotificationsPlugin _localNotifications =
//     FlutterLocalNotificationsPlugin(); // unused

class PushService {
  static Future<void> initialize() async {}

  static Future<bool> ensureNotificationPermission() async {
    return false;
  }
}
