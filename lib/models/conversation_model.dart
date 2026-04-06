import '../services/core/logger_service.dart';

class ConversationModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String? orderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? otherPartyName;
  final String? otherPartyImageUrl;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isFavorite;
  final bool hidden;

  const ConversationModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.orderId,
    required this.createdAt,
    required this.updatedAt,
    this.otherPartyName,
    this.otherPartyImageUrl,
    this.lastMessageBody,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isFavorite = false,
    this.hidden = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v == null) return fallback;
      if (v is String) return DateTime.tryParse(v) ?? fallback;
      if (v is DateTime) return v;
      return fallback;
    }

    DateTime? parseDateOrNull(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    final now = DateTime.now();

    // Poslednja poruka: RPC vraća ravna polja; stara putanja je nested 'last_message' objekat
    final lastMsg = json['last_message'] as Map<String, dynamic>?;
    final lastBody = json['last_message_body'] as String? ?? _resolveBody(lastMsg);
    final lastAt = json['last_message_at'] ?? lastMsg?['created_at'];

    return ConversationModel(
      id: json['id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      orderId: json['order_id'] as String?,
      createdAt: parseDate(json['created_at'], now),
      updatedAt: parseDate(json['updated_at'], now),
      otherPartyName: json['other_party_name'] as String?,
      otherPartyImageUrl: json['other_party_image_url'] as String?,
      lastMessageBody: lastBody,
      lastMessageAt: parseDateOrNull(lastAt),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
      hidden: (json['hidden'] as bool?) ?? false,
    );
  }

  static String? _resolveBody(Map<String, dynamic>? lastMsg) {
    final body = lastMsg?['body'];
    if (body is String) return body;
    if (body != null) {
      LoggerService.warning(
        'ConversationModel: unexpected last_message.body type',
        extra: {'type': body.runtimeType.toString()},
      );
    }
    return null;
  }
}
