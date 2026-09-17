import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_error.dart';

class PushHealthDashboardModel {
  final DateTime? checkedAt;
  final String health;
  final bool edgeConfigOk;
  final String? functionsBaseUrl;
  final bool anonKeyPresent;
  final int totalTokens;
  final int usersWithTokens;
  final int tokensCreated24h;
  final int notifications24h;
  final int deliveries24h;
  final int successfulDeliveries24h;
  final int failedDeliveries24h;
  final double successRatePct;
  final DateTime? lastNotificationAt;
  final DateTime? lastDeliveryAt;
  final double deliveryBacklogMinutes;

  const PushHealthDashboardModel({
    required this.checkedAt,
    required this.health,
    required this.edgeConfigOk,
    required this.functionsBaseUrl,
    required this.anonKeyPresent,
    required this.totalTokens,
    required this.usersWithTokens,
    required this.tokensCreated24h,
    required this.notifications24h,
    required this.deliveries24h,
    required this.successfulDeliveries24h,
    required this.failedDeliveries24h,
    required this.successRatePct,
    required this.lastNotificationAt,
    required this.lastDeliveryAt,
    required this.deliveryBacklogMinutes,
  });

  factory PushHealthDashboardModel.fromJson(Map<String, dynamic> json) {
    return PushHealthDashboardModel(
      checkedAt: _parseDateTime(json['checked_at']),
      health: (json['health'] as String? ?? 'unknown').trim(),
      edgeConfigOk: json['edge_config_ok'] as bool? ?? false,
      functionsBaseUrl: json['functions_base_url'] as String?,
      anonKeyPresent: json['anon_key_present'] as bool? ?? false,
      totalTokens: _parseInt(json['total_tokens']),
      usersWithTokens: _parseInt(json['users_with_tokens']),
      tokensCreated24h: _parseInt(json['tokens_created_24h']),
      notifications24h: _parseInt(json['notifications_24h']),
      deliveries24h: _parseInt(json['deliveries_24h']),
      successfulDeliveries24h: _parseInt(json['successful_deliveries_24h']),
      failedDeliveries24h: _parseInt(json['failed_deliveries_24h']),
      successRatePct: _parseDouble(json['success_rate_pct']),
      lastNotificationAt: _parseDateTime(json['last_notification_at']),
      lastDeliveryAt: _parseDateTime(json['last_delivery_at']),
      deliveryBacklogMinutes: _parseDouble(json['delivery_backlog_minutes']),
    );
  }
}

class PushHealthUserIssueModel {
  final DateTime? checkedAt;
  final String userId;
  final String health;
  final int tokenCount;
  final DateTime? latestTokenAt;
  final int notifications7d;
  final DateTime? latestNotificationAt;
  final DateTime? latestDeliveryAt;
  final String? latestDeliveryStatus;
  final int latestDeliveryErrorCount;

  const PushHealthUserIssueModel({
    required this.checkedAt,
    required this.userId,
    required this.health,
    required this.tokenCount,
    required this.latestTokenAt,
    required this.notifications7d,
    required this.latestNotificationAt,
    required this.latestDeliveryAt,
    required this.latestDeliveryStatus,
    required this.latestDeliveryErrorCount,
  });

  factory PushHealthUserIssueModel.fromJson(Map<String, dynamic> json) {
    return PushHealthUserIssueModel(
      checkedAt: _parseDateTime(json['checked_at']),
      userId: (json['user_id'] as String? ?? '').trim(),
      health: (json['health'] as String? ?? 'unknown').trim(),
      tokenCount: _parseInt(json['token_count']),
      latestTokenAt: _parseDateTime(json['latest_token_at']),
      notifications7d: _parseInt(json['notifications_7d']),
      latestNotificationAt: _parseDateTime(json['latest_notification_at']),
      latestDeliveryAt: _parseDateTime(json['latest_delivery_at']),
      latestDeliveryStatus: json['latest_delivery_status'] as String?,
      latestDeliveryErrorCount: _parseInt(json['latest_delivery_error_count']),
    );
  }
}

class PushHealthService {
  final SupabaseClient _client;

  PushHealthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<PushHealthDashboardModel> fetchDashboard() async {
    try {
      final res = await _client.rpc('admin_get_push_health_dashboard');
      final List<dynamic> rows =
          res is List ? res : (res == null ? [] : [res]);
      if (rows.isEmpty) {
        throw AppError(
          message: 'Push health dashboard row missing',
          userMessage: 'Statistika notifikacija trenutno nije dostupna.',
          type: ErrorType.notFound,
        );
      }
      return PushHealthDashboardModel.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }

  Future<List<PushHealthUserIssueModel>> fetchUserIssues() async {
    try {
      final res = await _client.rpc('admin_get_push_health_user_issues');
      final List<dynamic> rows = res is List ? res : [];
      return rows
          .map<PushHealthUserIssueModel>((item) =>
              PushHealthUserIssueModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false);
    } catch (e, st) {
      throw AppError.from(e, stackTrace: st);
    }
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
