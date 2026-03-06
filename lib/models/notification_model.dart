class NotificationModel {
  final String id;
  final String userId;
  final String? orderId;
  final String type;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.title,
    this.body = '',
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final readAt = json['read_at'];
    final createdAt = json['created_at'];
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      readAt: readAt != null ? (readAt is String ? DateTime.tryParse(readAt) : readAt as DateTime?) : null,
      createdAt: createdAt != null
          ? (createdAt is String
              ? (DateTime.tryParse(createdAt) ?? DateTime.now())
              : createdAt as DateTime)
          : DateTime.now(),
    );
  }
}
