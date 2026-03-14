class MessageReactionModel {
  final String messageId;
  final String reaction;
  final int count;
  final bool reactedByMe;

  const MessageReactionModel({
    required this.messageId,
    required this.reaction,
    required this.count,
    required this.reactedByMe,
  });
}

class SellerResponseStats {
  final int sampleCount;
  final double? avgResponseMinutes;
  final double? medianResponseMinutes;
  final double? lastResponseMinutes;

  const SellerResponseStats({
    required this.sampleCount,
    required this.avgResponseMinutes,
    required this.medianResponseMinutes,
    required this.lastResponseMinutes,
  });

  bool get hasData => sampleCount > 0 && avgResponseMinutes != null;

  factory SellerResponseStats.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return SellerResponseStats(
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      avgResponseMinutes: parseNum(json['avg_response_minutes']),
      medianResponseMinutes: parseNum(json['median_response_minutes']),
      lastResponseMinutes: parseNum(json['last_response_minutes']),
    );
  }
}
