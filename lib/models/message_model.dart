class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime? readAt;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    final readAt = json['read_at'];
    DateTime created = DateTime.now();
    if (createdAt != null) created = createdAt is String ? DateTime.tryParse(createdAt) ?? created : createdAt as DateTime;
    DateTime? read;
    if (readAt != null) read = readAt is String ? DateTime.tryParse(readAt) : readAt as DateTime;

    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      readAt: read,
      createdAt: created,
    );
  }
}
