import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notification_model.dart';

class NotificationsService {
  final _client = Supabase.instance.client;

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
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null);
    return (response as List).length;
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
