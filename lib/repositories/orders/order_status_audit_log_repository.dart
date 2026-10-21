import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_status_audit_log_model.dart';

/// Interfejs repozitorijuma za čitanje revizorskih tragova promene statusa porudžbine.
abstract interface class OrderStatusAuditLogRepository {
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(String orderId);
}

/// Supabase implementacija [OrderStatusAuditLogRepository].
class SupabaseOrderStatusAuditLogRepository
    implements OrderStatusAuditLogRepository {
  final SupabaseClient? _customClient;

  SupabaseOrderStatusAuditLogRepository({SupabaseClient? client})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  @override
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
    String orderId,
  ) async {
    final list = await _client
        .from('order_status_audit_logs')
        .select()
        .eq('order_id', orderId)
        .order('changed_at', ascending: false);

    return (list as List)
        .map(
          (e) => OrderStatusAuditLogModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }
}
