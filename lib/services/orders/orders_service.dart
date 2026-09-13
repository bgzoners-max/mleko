import 'package:supabase_flutter/supabase_flutter.dart';
import 'mixins/order_query_mixin.dart';
import 'mixins/order_management_mixin.dart';

export 'mixins/order_query_mixin.dart';
export 'mixins/order_management_mixin.dart';

class OrdersService with OrderQueryMixin, OrderManagementMixin {
  static final OrdersService _instance = OrdersService._();
  factory OrdersService({SupabaseClient? client}) {
    if (client != null) return OrdersService._(client: client);
    return _instance;
  }
  OrdersService._({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;

  @override
  SupabaseClient get client => _customClient ?? Supabase.instance.client;

  /// Vrednost statusFilter za listu „aktivnih” porudžbina: sve osim kupčeve ručne arhive (`arhivirano`).
  static const String statusFilterActiveNonArchived = 'active';
}
