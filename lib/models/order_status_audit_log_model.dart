class OrderStatusAuditLogModel {
  final String id;
  final String orderId;
  final String oldStatus;
  final String newStatus;
  final String changedByRole;
  final String? changedByUserId;
  final DateTime changedAt;

  const OrderStatusAuditLogModel({
    required this.id,
    required this.orderId,
    required this.oldStatus,
    required this.newStatus,
    required this.changedByRole,
    required this.changedAt,
    this.changedByUserId,
  });

  factory OrderStatusAuditLogModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusAuditLogModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      oldStatus: json['old_status'] as String,
      newStatus: json['new_status'] as String,
      changedByRole: json['changed_by_role'] as String,
      changedByUserId: json['changed_by_user_id'] as String?,
      changedAt: DateTime.tryParse(json['changed_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
