import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/repositories/orders/order_status_audit_log_repository.dart';
import 'package:mleko/services/services.dart';

/// Use-case za učitavanje status audit logova porudžbine.
class GetOrderStatusAuditLogsUseCase {
  final OrderStatusAuditLogRepository _repository;

  GetOrderStatusAuditLogsUseCase({
    OrderStatusAuditLogRepository? repository,
    OrdersService? ordersService,
  }) : _repository = repository ??
            (ordersService != null
                ? _OrdersServiceAdapter(ordersService)
                : SupabaseOrderStatusAuditLogRepository());

  Future<List<OrderStatusAuditLogModel>> call(String orderId) {
    return _repository.getOrderStatusAuditLogs(orderId);
  }
}

class _OrdersServiceAdapter implements OrderStatusAuditLogRepository {
  final OrdersService _service;
  _OrdersServiceAdapter(this._service);

  @override
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(String orderId) {
    return _service.getOrderStatusAuditLogs(orderId);
  }
}
