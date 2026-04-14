// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void setPageMetadata({
  required String title,
  String? description,
  String? path,
  String? imageUrl,
  String? type,
}) {
  final origin = html.window.location.origin;
  html.document.title = title;

  if (description != null && description.isNotEmpty) {
    _upsertMetaByName('description', description);
    _upsertMetaByProperty('og:description', description);
    _upsertMetaByName('twitter:description', description);
  }

  _upsertMetaByProperty('og:type', type ?? 'website');
  _upsertMetaByProperty('og:title', title);
  _upsertMetaByName('twitter:title', title);
  _upsertMetaByName('twitter:card', 'summary_large_image');

  final resolvedImageUrl = _normalizeUrl(
    imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : '/icons/Icon-512.png',
    origin,
  );
  _upsertMetaByProperty('og:image', resolvedImageUrl);
  _upsertMetaByName('twitter:image', resolvedImageUrl);

  if (path != null && path.isNotEmpty) {
    final canonicalUrl = _normalizeUrl(path, origin);
    _upsertCanonical(canonicalUrl);
    _upsertMetaByProperty('og:url', canonicalUrl);
  }
}

String _normalizeUrl(String value, String origin) {
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  if (value.startsWith('/')) {
    return '$origin$value';
  }
  return '$origin/$value';
}

void _upsertMetaByName(String name, String content) {
  final existing = html.document.head?.querySelector('meta[name="$name"]')
      as html.MetaElement?;
  if (existing != null) {
    existing.content = content;
    return;
  }

  final meta = html.MetaElement()
    ..name = name
    ..content = content;
  html.document.head?.append(meta);
}

void _upsertMetaByProperty(String property, String content) {
  final existing = html.document.head
      ?.querySelector('meta[property="$property"]') as html.MetaElement?;
  if (existing != null) {
    existing.content = content;
    return;
  }

  final meta = html.MetaElement()
    ..setAttribute('property', property)
    ..content = content;
  html.document.head?.append(meta);
}

void _upsertCanonical(String href) {
  final existing = html.document.head?.querySelector('link[rel="canonical"]')
      as html.LinkElement?;
  if (existing != null) {
    existing.href = href;
    return;
  }

  final link = html.LinkElement()
    ..rel = 'canonical'
    ..href = href;
  html.document.head?.append(link);
}
