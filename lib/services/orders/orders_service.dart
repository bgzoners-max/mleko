import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/order_item_model.dart';
import '../../models/order_model.dart';
import '../../models/order_status_audit_log_model.dart';
import '../../models/product_model.dart';
import '../../models/seller_delivery_models.dart';
import '../../utils/quantity_engine.dart';
import '../core/logger_service.dart';
import 'mixins/order_query_mixin.dart';
import 'mixins/order_management_mixin.dart';

export 'mixins/order_query_mixin.dart';
export 'mixins/order_management_mixin.dart';

class OrdersService with OrderQueryMixin, OrderManagementMixin {
  static final OrdersService _instance = OrdersService._();
  factory OrdersService() => _instance;
  OrdersService._();

  @override
  final client = Supabase.instance.client;

  /// Vrednost statusFilter za listu „aktivnih” porudžbina: sve osim kupčeve ručne arhive (`arhivirano`).
  static const String statusFilterActiveNonArchived = 'active';
}
