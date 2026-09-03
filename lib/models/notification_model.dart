class NotificationModel {
  final String id;
  final String userId;
  final String? orderId;
  final String? ticketId;
  final String? conversationId;
  final String type;
  final String title;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.orderId,
    this.ticketId,
    this.conversationId,
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
    final type = json['type'] as String? ?? '';
    final rawTitle = json['title'] as String? ?? '';
    final rawBody = json['body'] as String? ?? '';

    final title = type == 'order_status_changed'
        ? _fixLegacyOrderStatusDiacritics(rawTitle)
        : rawTitle;
    final body = type == 'order_status_changed'
        ? _fixLegacyOrderStatusDiacritics(rawBody)
        : rawBody;

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      ticketId: json['ticket_id'] as String?,
      conversationId: json['conversation_id'] as String?,
      type: type,
      title: title,
      body: body,
      readAt: readAt != null
          ? (readAt is String ? DateTime.tryParse(readAt) : readAt as DateTime?)
          : null,
      createdAt: createdAt != null
          ? (createdAt is String
              ? (DateTime.tryParse(createdAt) ?? DateTime.now())
              : createdAt as DateTime)
          : DateTime.now(),
    );
  }

  static String _fixLegacyOrderStatusDiacritics(String value) {
    return value
        .replaceAll('Porudzbina', 'Porudžbina')
        .replaceAll('prihvacena', 'prihvaćena')
        .replaceAll('vasu', 'vašu')
        .replaceAll('porudzbinu', 'porudžbinu')
        .replaceAll('oznacio', 'označio')
        .replaceAll('isporucenu', 'isporučenu');
  }
}
