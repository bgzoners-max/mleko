// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

String resolveBaseUrl([String? origin]) {
  if (origin != null && origin.isNotEmpty) {
    if (origin == 'https://domacimarket.rs') return 'https://www.domacimarket.rs';
    return origin;
  }
  final windowOrigin = html.window.location.origin;
  if (windowOrigin.isNotEmpty) {
    if (windowOrigin == 'https://domacimarket.rs') return 'https://www.domacimarket.rs';
    return windowOrigin;
  }
  return 'https://www.domacimarket.rs';
}

bool isWebOnline() {
  try {
    return html.window.navigator.onLine ?? true;
  } catch (_) {
    return true;
  }
}

void setPageMetadata({
  required String title,
  String? description,
  String? path,
  String? imageUrl,
  String? type,
  String? keywords,
  String? robots,
  Map<String, dynamic>? jsonLd,
}) {
  final origin = resolveBaseUrl();

  // 1. Title
  html.document.title = title;
  _upsertMetaByName('title', title);
  _upsertMetaByProperty('og:title', title);
  _upsertMetaByName('twitter:title', title);

  // 2. Description
  if (description != null && description.isNotEmpty) {
    _upsertMetaByName('description', description);
    _upsertMetaByProperty('og:description', description);
    _upsertMetaByName('twitter:description', description);
  }

  // 3. Keywords
  if (keywords != null && keywords.isNotEmpty) {
    _upsertMetaByName('keywords', keywords);
  }

  // 4. Robots direktiva (Googlebot & pretraživači)
  final robotsContent = robots ??
      'index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1';
  _upsertMetaByName('robots', robotsContent);
  _upsertMetaByName('googlebot', robotsContent);

  // 5. OpenGraph Type & Twitter Card
  _upsertMetaByProperty('og:type', type ?? 'website');
  _upsertMetaByProperty('og:site_name', 'Domaći Market');
  _upsertMetaByProperty('og:locale', 'sr_RS');
  _upsertMetaByName('twitter:card', 'summary_large_image');

  // 6. Image
  final resolvedImageUrl = _normalizeUrl(
    imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : 'https://www.domacimarket.rs/icons/Icon-512.png',
    origin,
  );
  _upsertMetaByProperty('og:image', resolvedImageUrl);
  _upsertMetaByProperty('og:image:secure_url', resolvedImageUrl);
  _upsertMetaByName('twitter:image', resolvedImageUrl);

  // 7. Canonical URL i OG URL
  final canonicalUrl = _normalizeUrl(path ?? '/', origin);
  _upsertCanonical(canonicalUrl);
  _upsertMetaByProperty('og:url', canonicalUrl);
  _upsertMetaByName('twitter:url', canonicalUrl);

  // 8. Strukturirani podaci (Schema.org JSON-LD)
  if (jsonLd != null) {
    _upsertJsonLd(jsonLd);
  } else {
    _removeDynamicJsonLd();
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

void _upsertJsonLd(Map<String, dynamic> jsonMap) {
  const scriptId = 'seo-dynamic-jsonld';
  var script = html.document.head?.querySelector('#$scriptId') as html.ScriptElement?;
  if (script == null) {
    script = html.ScriptElement()
      ..id = scriptId
      ..type = 'application/ld+json';
    html.document.head?.append(script);
  }
  script.text = jsonEncode(jsonMap);
}

void _removeDynamicJsonLd() {
  const scriptId = 'seo-dynamic-jsonld';
  final script = html.document.head?.querySelector('#$scriptId');
  script?.remove();
}
