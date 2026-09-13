import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notification_model.dart';

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService({SupabaseClient? client}) {
    if (client != null) return NotificationsService._(client);
    return _instance;
  }
  NotificationsService._([SupabaseClient? client]) : _customClient = client;
  NotificationsService._internal() : _customClient = null;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  Future<List<NotificationModel>> getNotifications(String userId) async {
    final list = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return (list as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    // Lean upit: samo 1 red (Range 0-0) + tačan count preko parcijalnog indeksa
    // (user_id) WHERE read_at IS NULL — bez preuzimanja svih nepročitanih redova.
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null)
        .range(0, 0)
        .count(CountOption.exact);
    return response.count;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client.from('notifications').update({
      'read_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId).isFilter('read_at', null);
  }

  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  Future<void> deleteAllNotifications(String userId) async {
    await _client.from('notifications').delete().eq('user_id', userId);
  }
}
