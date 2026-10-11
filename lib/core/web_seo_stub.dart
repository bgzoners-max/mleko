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

String resolveBaseUrl([String? origin]) {
  if (origin == 'https://domacimarket.rs') return 'https://www.domacimarket.rs';
  return origin ?? 'https://www.domacimarket.rs';
}

bool isWebOnline() => true;
