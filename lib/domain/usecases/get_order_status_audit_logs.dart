import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/services/services.dart';

/// Use-case za učitavanje status audit logova porudžbine.
class GetOrderStatusAuditLogsUseCase {
  final OrdersService _ordersService;

  GetOrderStatusAuditLogsUseCase({
    OrdersService? ordersService,
  }) : _ordersService = ordersService ?? OrdersService();

  Future<List<OrderStatusAuditLogModel>> call(String orderId) {
    return _ordersService.getOrderStatusAuditLogs(orderId);
  }
}

