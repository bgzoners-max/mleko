import 'package:flutter_test/flutter_test.dart';
import 'package:mleko/domain/usecases/get_order_status_audit_logs.dart';
import 'package:mleko/models/order_status_audit_log_model.dart';
import 'package:mleko/repositories/orders/order_status_audit_log_repository.dart';

class FakeOrderStatusAuditLogRepository
    implements OrderStatusAuditLogRepository {
  final Map<String, List<OrderStatusAuditLogModel>> logsByOrder = {};

  @override
  Future<List<OrderStatusAuditLogModel>> getOrderStatusAuditLogs(
      String orderId) async {
    return logsByOrder[orderId] ?? const [];
  }
}

void main() {
  group('OrderStatusAuditLogRepository & GetOrderStatusAuditLogsUseCase', () {
    test('učitanje audit logova kroz use case i fake repozitorijum', () async {
      final fakeRepo = FakeOrderStatusAuditLogRepository();
      fakeRepo.logsByOrder['order-100'] = [
        OrderStatusAuditLogModel(
          id: 'log-1',
          orderId: 'order-100',
          oldStatus: 'pending',
          newStatus: 'accepted',
          changedByRole: 'seller',
          changedAt: DateTime.parse('2026-10-21T09:00:00Z'),
        ),
      ];

      final useCase =
          GetOrderStatusAuditLogsUseCase(repository: fakeRepo);
      final logs = await useCase('order-100');

      expect(logs.length, 1);
      expect(logs.first.oldStatus, 'pending');
      expect(logs.first.newStatus, 'accepted');
    });
  });
}
