void setPageMetadata({
  required String title,
  String? description,
  String? path,
  String? imageUrl,
  String? type,
  String? keywords,
  String? robots,
  Map<String, dynamic>? jsonLd,
}) {}

String resolveBaseUrl([String? origin]) => origin ?? 'https://domacimarket.rs';
